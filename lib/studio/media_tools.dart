import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/track.dart';

/// FFmpeg runs natively on Windows desktop.
bool get studioSupported => true;

class AudioStreamInfo {
  const AudioStreamInfo(this.label, this.codec);
  final String label;
  final String codec;
}

class ProbeResult {
  const ProbeResult({
    this.duration,
    this.format,
    this.sampleRate,
    this.channels,
    this.size,
    this.videoCodec,
    this.audioStreams = const [],
    this.tags = const {},
  });

  final Duration? duration;
  final String? format;
  final int? sampleRate;
  final String? channels;
  final int? size;
  final String? videoCodec;
  final List<AudioStreamInfo> audioStreams;
  final Map<String, String> tags;

  String get sampleRateLabel {
    final sr = sampleRate;
    if (sr == null) return '';
    final k = sr / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)} kHz';
  }
}

String _codecName(String? c) => switch ((c ?? '').toLowerCase()) {
  'h264' => 'H.264',
  'hevc' => 'HEVC',
  'aac' => 'AAC',
  'mp3' => 'MP3',
  'opus' => 'Opus',
  'vorbis' => 'Vorbis',
  'flac' => 'FLAC',
  'vp9' => 'VP9',
  'av1' => 'AV1',
  'ac3' => 'AC-3',
  'eac3' => 'E-AC-3',
  final s when s.startsWith('pcm') => 'PCM',
  final s => s.toUpperCase(),
};

String _channelLabel(String? layout) => switch (layout) {
  'mono' => 'mono',
  'stereo' => 'stereo',
  null || '' => 'audio',
  final l => l,
};

final _inputCache = <String, String>{};

/// An input argument FFmpeg can open for [t]: local file path or temp copy of a bundled sample.
Future<String> ffmpegInput(Track t) async {
  final cached = _inputCache[t.key];
  if (cached != null) return cached;
  String input;
  if (t.uri.startsWith('asset:///')) {
    final asset = t.uri.substring('asset:///'.length);
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'samples'));
    await dir.create(recursive: true);
    final f = File(p.join(dir.path, p.basename(asset)));
    if (!await f.exists()) {
      final data = await rootBundle.load(asset);
      await f.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    input = f.path;
  } else {
    input = t.uri.startsWith('file://') ? Uri.parse(t.uri).toFilePath() : t.uri;
  }
  return _inputCache[t.key] = input;
}

Future<String> ffmpegInputForPath(String pathOrUri) async => pathOrUri;

Future<ProbeResult> probe(String input) async {
  try {
    final res = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_entries', 'format=duration,size,format_name:stream=codec_name,sample_rate,channels,channel_layout,codec_type',
      '-of', 'json',
      input,
    ]);
    if (res.exitCode == 0 && res.stdout.toString().isNotEmpty) {
      final data = jsonDecode(res.stdout.toString()) as Map<String, dynamic>;
      final format = data['format'] as Map<String, dynamic>?;
      final streams = (data['streams'] as List<dynamic>? ?? []);
      final audio = streams.where((s) => s['codec_type'] == 'audio').toList();
      final video = streams.where((s) => s['codec_type'] == 'video').toList();
      final a0 = audio.isEmpty ? null : audio.first as Map<String, dynamic>;
      final dur = double.tryParse(format?['duration']?.toString() ?? '');
      final size = int.tryParse(format?['size']?.toString() ?? '');
      var i = 0;
      return ProbeResult(
        duration: dur == null ? null : Duration(milliseconds: (dur * 1000).round()),
        format: _formatLabel(format?['format_name']?.toString(), a0?['codec_name']?.toString()),
        sampleRate: int.tryParse(a0?['sample_rate']?.toString() ?? ''),
        channels: a0?['channel_layout']?.toString() ?? a0?['channels']?.toString(),
        size: size,
        videoCodec: video.isEmpty ? null : _codecName(video.first['codec_name']?.toString()),
        audioStreams: [
          for (final s in audio)
            AudioStreamInfo(
              'Stream ${++i} · ${_codecName(s['codec_name']?.toString())} ${_channelLabel(s['channel_layout']?.toString())}',
              _codecName(s['codec_name']?.toString()),
            )
        ],
      );
    }
  } catch (_) {}

  // Fallback: estimate from file if exists
  final f = File(input);
  if (f.existsSync()) {
    return ProbeResult(
      size: f.lengthSync(),
      format: p.extension(input).replaceAll('.', '').toUpperCase(),
    );
  }
  return const ProbeResult();
}

String? _formatLabel(String? container, String? codec) {
  final c = (container ?? '').toLowerCase();
  if (c.contains('mp3')) return 'MP3';
  if (c.contains('flac')) return 'FLAC';
  if (c.contains('wav')) return 'WAV';
  if (c.contains('ogg')) return codec == 'opus' ? 'Opus' : 'OGG';
  if (c.contains('mp4') || c.contains('m4a') || c.contains('mov')) return codec == 'alac' ? 'ALAC' : 'M4A';
  if (c.contains('matroska') || c.contains('webm')) return 'WebM';
  return codec == null ? null : _codecName(codec);
}

String fmtBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  return mb >= 10 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
}
