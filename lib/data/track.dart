import 'dart:ui';

enum TrackSource { device, imported, sample }

/// Colours and layout for generated cover art, used when a track has no
/// embedded artwork. Each key hashes to one of [presets], a two-stop
/// gradient in the style of Apple Music's placeholder tiles.
class ArtSpec {
  const ArtSpec(this.c1, this.c2, this.c3, this.variant);

  /// Gradient start (top-left), gradient end (bottom-right) and a highlight.
  final Color c1, c2, c3;
  final int variant;

  ArtSpec shifted(int by) => ArtSpec(c1, c2, c3, (variant + by) % 4);

  static const presets = <ArtSpec>[
    ArtSpec(Color(0xFFFF6B6B), Color(0xFFC2185B), Color(0xFFFFD6D6), 0),
    ArtSpec(Color(0xFFFFB347), Color(0xFFE5532D), Color(0xFFFFF0D6), 1),
    ArtSpec(Color(0xFF56CCF2), Color(0xFF2F6FED), Color(0xFFD8F0FF), 2),
    ArtSpec(Color(0xFFA18CD1), Color(0xFF5B3FC0), Color(0xFFEDE5FF), 3),
    ArtSpec(Color(0xFF7BE0AD), Color(0xFF1E8E5A), Color(0xFFDDF7E9), 0),
    ArtSpec(Color(0xFFF7797D), Color(0xFFB02A5B), Color(0xFFFFE0E6), 1),
    ArtSpec(Color(0xFF434343), Color(0xFF0F0F10), Color(0xFFBDBDBD), 2),
    ArtSpec(Color(0xFFFDC830), Color(0xFFF37335), Color(0xFFFFF4C9), 3),
  ];

  static ArtSpec forKey(String key) {
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final p = presets[h % presets.length];
    return ArtSpec(p.c1, p.c2, p.c3, (h ~/ presets.length) % 4);
  }
}

class Track {
  const Track({
    required this.key,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    required this.source,
    required this.art,
    this.mime,
    this.albumId,
    this.added,
    this.trackNo = 0,
    this.discNo = 1,
    this.year,
  });

  /// Stable identity used for favourites, history, playlists and the saved queue.
  final String key;
  final String title, artist, album;
  final Duration duration;

  /// `content://…` on Android, a file path for imports, `asset:///…` for the
  /// bundled samples, or a `blob:` URL for files picked in a browser.
  final String uri;
  final TrackSource source;
  final ArtSpec art;
  final String? mime;
  final int? albumId;
  final DateTime? added;

  /// 1-based position on the disc; 0 when unknown.
  final int trackNo;
  final int discNo;
  final int? year;

  /// Short container label shown in the Studio, e.g. "M4A".
  String get formatLabel {
    final m = (mime ?? '').toLowerCase();
    final ext = uri.split('?').first.split('.').last.toLowerCase();
    if (m.contains('mpeg') || ext == 'mp3') return 'MP3';
    if (m.contains('flac') || ext == 'flac') return 'FLAC';
    if (m.contains('wav') || ext == 'wav') return 'WAV';
    if (m.contains('ogg') || m.contains('opus') || ext == 'ogg' || ext == 'opus') return 'OGG';
    if (m.contains('mp4') || m.contains('aac') || m.contains('m4a') || ext == 'm4a' || ext == 'aac') return 'M4A';
    return ext.length <= 4 && ext.isNotEmpty ? ext.toUpperCase() : 'Audio';
  }

  /// The quality badge on Now Playing, as Apple Music shows it.
  String? get qualityBadge => switch (formatLabel) {
    'FLAC' || 'WAV' => 'Lossless',
    _ => null,
  };

  Map<String, Object?> toJson() => {
    'key': key,
    'title': title,
    'artist': artist,
    'album': album,
    'ms': duration.inMilliseconds,
    'uri': uri,
    'mime': mime,
    'trackNo': trackNo,
    'discNo': discNo,
    'year': year,
  };

  static Track importedFromJson(Map<String, dynamic> j) => Track(
    key: j['key'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    album: j['album'] as String,
    duration: Duration(milliseconds: (j['ms'] as num).toInt()),
    uri: j['uri'] as String,
    mime: j['mime'] as String?,
    source: TrackSource.imported,
    art: ArtSpec.forKey(j['album'] as String),
    trackNo: (j['trackNo'] as num?)?.toInt() ?? 0,
    discNo: (j['discNo'] as num?)?.toInt() ?? 1,
    year: (j['year'] as num?)?.toInt(),
  );
}

String fmtDur(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}

/// Tenths of a second, e.g. "1:04.3" (the Cutter readouts).
String fmtTenths(double seconds) {
  final s = (seconds * 10).round() / 10;
  final m = s ~/ 60;
  final r = s - m * 60;
  return '$m:${r < 10 ? '0' : ''}${r.toStringAsFixed(1)}';
}

/// "3 songs, 12 minutes", as under an Apple Music album.
String fmtSummary(int songs, Duration total) {
  final mins = (total.inSeconds / 60).round();
  final s = '$songs ${songs == 1 ? 'song' : 'songs'}';
  if (mins < 1) return s;
  if (mins >= 60) {
    final h = mins ~/ 60, m = mins % 60;
    return '$s, $h hr${m > 0 ? ', $m min' : ''}';
  }
  return '$s, $mins ${mins == 1 ? 'minute' : 'minutes'}';
}
