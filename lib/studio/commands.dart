/// FFmpeg argument builders for the Studio tools.
library;

/// File extension for an output format label.
String extFor(String fmt) => switch (fmt) {
  'AAC' || 'M4A' => 'm4a',
  'MP3' => 'mp3',
  'FLAC' => 'flac',
  'WAV' => 'wav',
  'OGG' => 'ogg',
  _ => fmt.toLowerCase(),
};

String mimeFor(String fmt) => switch (fmt) {
  'AAC' || 'M4A' => 'audio/mp4',
  'MP3' => 'audio/mpeg',
  'FLAC' => 'audio/flac',
  'WAV' => 'audio/wav',
  'OGG' => 'audio/ogg',
  _ => 'audio/*',
};

bool isLossless(String fmt) => fmt == 'FLAC' || fmt == 'WAV';

/// Encoder arguments. [kbps] is ignored for lossless formats; [sampleRate]
/// is in Hz, or null to keep the source rate.
List<String> encode(String fmt, {int kbps = 256, int? sampleRate}) => [
  ...switch (fmt) {
    'AAC' || 'M4A' => ['-c:a', 'aac', '-b:a', '${kbps}k', '-movflags', '+faststart'],
    'MP3' => ['-c:a', 'libmp3lame', '-b:a', '${kbps}k'],
    'FLAC' => ['-c:a', 'flac'],
    'WAV' => ['-c:a', 'pcm_s16le'],
    'OGG' => ['-c:a', 'libvorbis', '-b:a', '${kbps}k'],
    _ => ['-c:a', 'aac', '-b:a', '${kbps}k'],
  },
  if (sampleRate != null) ...['-ar', '$sampleRate'],
];

String _t(double s) => s.toStringAsFixed(3);

/// Cutter and Ringtone: one clip from [start] to [end] seconds.
List<String> trimArgs(String input, double start, double end, String fmt, String out) => [
  '-ss',
  _t(start),
  '-i',
  input,
  '-t',
  _t(end - start),
  '-map',
  '0:a:0',
  '-vn',
  '-map_metadata',
  '0',
  ...encode(fmt),
  out,
];

/// Splitter: start→marker, marker→marker, marker→end as three files.
List<String> splitArgs(String input, double a, double b, double total, String fmt, List<String> outs) => [
  '-i',
  input,
  for (final (s, e, o) in [(0.0, a, outs[0]), (a, b, outs[1]), (b, total, outs[2])]) ...[
    '-map',
    '0:a:0',
    '-vn',
    '-ss',
    _t(s),
    '-t',
    _t(e - s),
    '-map_metadata',
    '0',
    ...encode(fmt),
    o,
  ],
];

/// Converter and Video to audio.
List<String> convertArgs(String input, int stream, String fmt, int kbps, int sampleRate, String out) => [
  '-i',
  input,
  '-map',
  '0:a:$stream',
  '-vn',
  '-map_metadata',
  '0',
  ...encode(fmt, kbps: kbps, sampleRate: sampleRate),
  out,
];

/// Merger. Every input is resampled to 44.1 kHz stereo so the filters can
/// join files with different formats.
List<String> mergeArgs(List<String> inputs, String mode, String fmt, String out) {
  final n = inputs.length;
  final pre = [
    for (var i = 0; i < n; i++) '[$i:a:0]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo[a$i]',
  ];
  final String join;
  switch (mode) {
    case 'Crossfade':
      final steps = <String>[];
      var last = 'a0';
      for (var i = 1; i < n; i++) {
        final o = i == n - 1 ? 'out' : 'x$i';
        steps.add('[$last][a$i]acrossfade=d=2:c1=tri:c2=tri[$o]');
        last = o;
      }
      join = steps.join(';');
    case 'Mix':
      join = '${[for (var i = 0; i < n; i++) '[a$i]'].join()}amix=inputs=$n:duration=longest:normalize=1[out]';
    default:
      join = '${[for (var i = 0; i < n; i++) '[a$i]'].join()}concat=n=$n:v=0:a=1[out]';
  }
  return [
    for (final i in inputs) ...['-i', i],
    '-filter_complex',
    '${pre.join(';')};$join',
    '-map',
    '[out]',
    ...encode(fmt),
    out,
  ];
}
