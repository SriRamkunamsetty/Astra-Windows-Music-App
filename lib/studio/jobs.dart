import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_store.dart';
import '../platform/native_media.dart';

enum JobStatus { running, done, cancelled, failed }

/// One export: the FFmpeg arguments, where the output goes, and how to
/// label it in the sheet and in Recent jobs.
class JobSpec {
  JobSpec({
    required this.name,
    required this.kind,
    required this.length,
    required this.expected,
    required this.outputs,
    required this.mime,
    required this.buildArgs,
    this.ringtone = false,
  });

  final String name;
  final String kind;
  final String length;
  final Duration expected;
  final List<String> outputs;
  final String mime;
  final bool ringtone;
  final Future<List<String>> Function(List<String> outPaths) buildArgs;
}

class Job {
  Job(this.spec);
  final JobSpec spec;
  JobStatus status = JobStatus.running;
  double progress = 0;
  String? error;
  Process? _proc;
  List<String> _temps = const [];
}

class HistoryEntry {
  const HistoryEntry(this.title, this.sub);
  final String title, sub;
}

class JobController extends ChangeNotifier {
  JobController(this._prefs, this._settings) {
    history = [
      for (final s in _prefs.getStringList('jobs') ?? const <String>[])
        () {
          final j = jsonDecode(s) as Map<String, dynamic>;
          return HistoryEntry(j['t'] as String, j['s'] as String);
        }(),
    ];
  }

  final SharedPreferences _prefs;
  // ignore: unused_field
  final SettingsStore _settings;

  Job? job;
  late List<HistoryEntry> history;

  bool get running => job?.status == JobStatus.running;

  Future<Directory> _workDir() async {
    final d = Directory(p.join((await getTemporaryDirectory()).path, 'exports'));
    await d.create(recursive: true);
    return d;
  }

  Future<void> start(JobSpec spec) async {
    final j = job = Job(spec);
    notifyListeners();
    try {
      final dir = await _workDir();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      j._temps = [for (final (i, o) in spec.outputs.indexed) p.join(dir.path, '${stamp}_${i}_$o')];
      final args = await spec.buildArgs(j._temps);
      final expectedMs = spec.expected.inMilliseconds.clamp(1, 1 << 40);

      final proc = await Process.start('ffmpeg', ['-y', '-hide_banner', ...args]);
      j._proc = proc;

      final stderrBuffer = StringBuffer();
      proc.stderr.transform(utf8.decoder).listen((chunk) {
        stderrBuffer.write(chunk);
        final m = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)').firstMatch(chunk);
        if (m != null) {
          final hrs = int.parse(m.group(1)!);
          final mins = int.parse(m.group(2)!);
          final secs = double.parse(m.group(3)!);
          final curMs = ((hrs * 3600 + mins * 60 + secs) * 1000).round();
          if (job == j && j.status == JobStatus.running) {
            j.progress = (curMs / expectedMs * 100).clamp(0, 99).toDouble();
            notifyListeners();
          }
        }
      });

      final exitCode = await proc.exitCode;
      if (j.status == JobStatus.cancelled) {
        await _cleanup(j);
        notifyListeners();
        return;
      }

      if (exitCode != 0) {
        await _cleanup(j);
        _fail(j, _summarise(stderrBuffer.toString()));
        return;
      }

      for (final (i, t) in j._temps.indexed) {
        await _save(t, j.spec.outputs[i], j.spec.mime, ringtone: j.spec.ringtone);
      }

      await _cleanup(j);
      j.progress = 100;
      j.status = JobStatus.done;
      _addHistory(HistoryEntry(j.spec.name, '${j.spec.kind} · ${j.spec.length} · Done'));
      notifyListeners();
    } catch (e) {
      await _cleanup(j);
      _fail(j, 'Could not complete export: $e');
    }
  }

  String _summarise(String logs) {
    final lines = logs.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    for (final l in lines.reversed) {
      if (l.contains('No such file') || l.contains('Invalid data')) return 'The source file could not be read.';
      if (l.contains('Stream map') || l.contains('matches no streams')) return 'That file has no audio stream.';
    }
    return 'FFmpeg could not process this file.';
  }

  Future<String?> _save(String temp, String name, String mime, {bool ringtone = false}) async {
    return NativeMedia.saveToShared(temp, name, mime, ringtone: ringtone);
  }

  Future<void> _cleanup(Job j) async {
    for (final t in j._temps) {
      try {
        final f = File(t);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  void _fail(Job j, String why) {
    j.status = JobStatus.failed;
    j.error = why;
    notifyListeners();
  }

  void cancel() {
    final j = job;
    if (j == null || j.status != JobStatus.running) return;
    j.status = JobStatus.cancelled;
    j._proc?.kill();
    notifyListeners();
  }

  void retry() {
    final j = job;
    if (j != null) start(j.spec);
  }

  void dismiss() {
    if (running) return;
    job = null;
    notifyListeners();
  }

  void _addHistory(HistoryEntry e) {
    history = [e, ...history].take(30).toList();
    _prefs.setStringList('jobs', [
      for (final h in history) jsonEncode({'t': h.title, 's': h.sub}),
    ]);
  }

  Future<int> tempBytes() async {
    var total = 0;
    try {
      final d = await getTemporaryDirectory();
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) total += await e.length();
      }
    } catch (_) {}
    return total;
  }

  Future<void> clearTemp() async {
    if (running) return;
    final d = await getTemporaryDirectory();
    try {
      await for (final e in d.list(followLinks: false)) {
        try {
          await e.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
    clearWaveformCache();
  }
}

final _waveCache = <String, List<double>>{};
void clearWaveformCache() => _waveCache.clear();

Future<List<double>?> extractWaveform(String cacheKey, Future<String> Function() input, {int bars = 56}) async {
  final hit = _waveCache[cacheKey];
  if (hit != null) return hit;
  try {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'waveforms'));
    await dir.create(recursive: true);
    final inPath = await input();
    final out = p.join(dir.path, '${cacheKey.hashCode}.pcm');
    final res = await Process.run('ffmpeg', [
      '-y',
      '-hide_banner',
      '-i',
      inPath,
      '-map',
      '0:a:0',
      '-ac',
      '1',
      '-ar',
      '800',
      '-f',
      's16le',
      '-acodec',
      'pcm_s16le',
      out,
    ]);
    if (res.exitCode != 0) return null;
    final f = File(out);
    if (!f.existsSync()) return null;
    final bytes = await f.readAsBytes();
    await f.delete();
    final samples = bytes.buffer.asInt16List(0, bytes.lengthInBytes ~/ 2);
    if (samples.isEmpty) return null;
    final per = (samples.length / bars).ceil();
    final rms = List<double>.generate(bars, (b) {
      var sum = 0.0;
      var n = 0;
      for (var i = b * per; i < (b + 1) * per && i < samples.length; i++) {
        sum += samples[i] * samples[i].toDouble();
        n++;
      }
      return n == 0 ? 0 : math.sqrt(sum / n);
    });
    final top = rms.fold<double>(0, math.max);
    return _waveCache[cacheKey] = [
      for (final v in rms) top == 0 ? .08 : (0.08 + 0.92 * math.pow(v / top, 0.85)).clamp(0.08, 1.0).toDouble(),
    ];
  } catch (_) {
    return null;
  }
}
