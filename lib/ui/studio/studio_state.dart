import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../data/track.dart';
import '../../studio/jobs.dart';
import '../../studio/media_tools.dart';

class StudioTool {
  const StudioTool(this.id, this.title, this.desc, this.icon, this.kind, [this.cta]);
  final String id, title, desc, icon, kind;
  final String? cta;
}

const studioTools = <StudioTool>[
  StudioTool('trim', 'Cutter', 'Trim a clip from a track', 'scissors', 'wave', 'Export clip'),
  StudioTool('video', 'Video to audio', 'Pull the sound out of a video', 'video', 'conv', 'Extract audio'),
  StudioTool('conv', 'Converter', 'MP3, AAC, FLAC, WAV, OGG', 'swap', 'conv', 'Convert'),
  StudioTool('merge', 'Merger', 'Join tracks in order', 'merge', 'merge'),
  StudioTool('split', 'Splitter', 'Cut a track into parts', 'split', 'wave', 'Split at markers'),
  StudioTool('ring', 'Ringtone', 'Make a ringtone from a clip', 'bell', 'wave', 'Set as ringtone'),
];

/// Selections for every Studio tool on Windows.
class StudioState extends ChangeNotifier {
  StudioState._();
  static final instance = StudioState._();

  // Cutter / Splitter / Ringtone
  Track? src;
  double tS = .18, tE = .52;
  String trimFmt = 'M4A';
  List<double>? wave;
  bool previewing = false;
  double? cursor;
  final _preview = AudioPlayer();
  StreamSubscription<Duration>? _previewSub;

  // Converter / Video to audio
  Track? convSrc;
  Track? video;
  String convFmt = 'MP3', br = '256', sr = '44.1';
  int stream = 0;
  final probes = <String, ProbeResult>{};

  // Merger
  List<Track> merge = [];
  String mergeMode = 'Sequential';

  void changed() => notifyListeners();

  Duration get srcDur => src?.duration ?? Duration.zero;
  double get srcSecs => math.max(srcDur.inMilliseconds / 1000, .001);

  void setSource(Track t, {bool notify = true}) {
    if (src?.key == t.key) return;
    stopPreview();
    src = t;
    wave = null;
    final minGap = .5 / srcSecs;
    if (tE - tS < minGap) {
      tS = 0;
      tE = math.min(1, math.max(minGap, .3));
    }
    if (notify) notifyListeners();
    _loadWave(t);
  }

  void setSrc(Track t, {bool notify = true}) => setSource(t, notify: notify);

  void setConvSrc(Track t) {
    convSrc = t;
    ensureProbe(t);
    notifyListeners();
  }

  Future<void> ensureProbe(Track t) async {
    if (probes.containsKey(t.key)) return;
    probes[t.key] = const ProbeResult();
    try {
      probes[t.key] = await probe(await ffmpegInput(t));
    } catch (_) {}
    notifyListeners();
  }

  Future<Track?> pickFile({bool video = false}) async {
    final file = await FilePicker.pickFile(type: video ? FileType.video : FileType.audio);
    if (file == null || file.path == null) return null;
    final path = file.path!;
    final base = p.basenameWithoutExtension(path);
    final key = 'pick:$path';
    final info = await probe(path);
    probes[key] = info;
    return Track(
      key: key,
      title: base,
      artist: info.tags['artist'] ?? 'Unknown Artist',
      album: info.tags['album'] ?? 'Files',
      duration: info.duration ?? Duration.zero,
      uri: path,
      mime: video ? 'video/*' : null,
      source: TrackSource.imported,
      art: ArtSpec.forKey(base),
      added: DateTime.now(),
    );
  }

  Future<void> pickVideo() async {
    final v = await pickFile(video: true);
    if (v != null) {
      video = v;
      stream = 0;
      notifyListeners();
    }
  }

  void _loadWave(Track t) async {
    try {
      final w = await extractWaveform(t.key, () => ffmpegInput(t));
      if (src?.key == t.key && w != null) {
        wave = w;
        notifyListeners();
        return;
      }
    } catch (_) {}
    final r = math.Random(t.title.hashCode ^ t.artist.hashCode);
    final bars = 56;
    final w = <double>[];
    for (var i = 0; i < bars; i++) {
      final v = .2 + .8 * math.sin(i / bars * math.pi) * (0.6 + 0.4 * r.nextDouble());
      w.add(v.clamp(0.08, 1.0));
    }
    if (src?.key == t.key) {
      wave = w;
      notifyListeners();
    }
  }

  List<double> fallbackWave() {
    final seed = (src?.key.hashCode ?? 0) % 97 / 10;
    return List.generate(56, (i) {
      final x = i / 56;
      final h =
          (0.16 +
              0.84 *
                  math.pow(
                    (math.sin(i * 0.37 + seed) * math.cos(i * 0.11 + seed * 2) + 0.35 * math.sin(i * 1.3 + seed)).abs(),
                    0.85,
                  )) *
          (0.55 + 0.45 * math.sin(math.pi * math.min(1, x * 1.1 + 0.05)));
      return h.clamp(0.08, 1.0).toDouble();
    });
  }

  void moveHandle(bool start, double f) {
    final min = .5 / srcSecs;
    if (start) {
      tS = f.clamp(0, math.max(0, tE - min)).toDouble();
    } else {
      tE = f.clamp(math.min(1, tS + min), 1).toDouble();
    }
    if (previewing) stopPreview();
    notifyListeners();
  }

  void nudge(bool start, double secs) => moveHandle(start, (start ? tS : tE) + secs / srcSecs);

  Future<void> togglePreview(Future<void> Function() pauseMain) async {
    if (previewing) {
      stopPreview();
      return;
    }
    final t = src;
    if (t == null) return;
    await pauseMain();
    previewing = true;
    cursor = tS;
    notifyListeners();

    final start = Duration(milliseconds: (tS * srcDur.inMilliseconds).round());
    final end = Duration(milliseconds: (tE * srcDur.inMilliseconds).round());

    try {
      Source source;
      if (t.uri.startsWith('asset:///')) {
        source = AssetSource(t.uri.substring('asset:///'.length));
      } else if (t.uri.startsWith('assets/')) {
        source = AssetSource(t.uri);
      } else {
        source = DeviceFileSource(t.uri.startsWith('file://') ? Uri.parse(t.uri).toFilePath() : t.uri);
      }

      await _preview.stop();
      await _preview.setSource(source);
      await _preview.seek(start);
      await _preview.resume();

      _previewSub?.cancel();
      _previewSub = _preview.onPositionChanged.listen((p) {
        if (!previewing) return;
        if (p >= end) {
          stopPreview();
          return;
        }
        cursor = p.inMilliseconds / math.max(1, srcDur.inMilliseconds);
        notifyListeners();
      });

      _preview.onPlayerComplete.listen((_) => stopPreview());
    } catch (_) {
      stopPreview();
    }
  }

  void stopPreview() {
    if (!previewing && cursor == null) return;
    previewing = false;
    cursor = null;
    _previewSub?.cancel();
    _preview.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    _preview.dispose();
    super.dispose();
  }
}
