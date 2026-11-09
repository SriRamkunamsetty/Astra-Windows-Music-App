import 'dart:io';

import 'package:path/path.dart' as p;

import '../studio/media_tools.dart';
import 'track.dart';

class LyricLine {
  const LyricLine(this.time, this.text);

  /// When the line starts; null for unsynchronised lyrics.
  final Duration? time;
  final String text;
}

class Lyrics {
  const Lyrics(this.lines, {required this.synced});
  final List<LyricLine> lines;
  final bool synced;

  /// Index of the line that is current at [pos], or -1 before the first one.
  int indexAt(Duration pos) {
    if (!synced) return -1;
    var lo = 0, hi = lines.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time! <= pos) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}

final _stamp = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');

/// Parses LRC text. Lines with time tags become synchronised; text without
/// any tag is returned as plain lines.
Lyrics? parseLyrics(String raw) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final synced = <LyricLine>[];
  final plain = <String>[];
  for (final line in text.split('\n')) {
    final stamps = _stamp.allMatches(line).toList();
    if (stamps.isEmpty) {
      final l = line.trim();
      // Skip LRC metadata headers such as [ar:Artist].
      if (l.isNotEmpty && !RegExp(r'^\[[a-zA-Z]+:.*\]$').hasMatch(l)) plain.add(l);
      continue;
    }
    final body = line.substring(stamps.last.end).trim();
    for (final m in stamps) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final fracRaw = m.group(3) ?? '0';
      final ms = (int.parse(fracRaw) * (fracRaw.length == 1 ? 100 : (fracRaw.length == 2 ? 10 : 1)));
      synced.add(LyricLine(Duration(minutes: min, seconds: sec, milliseconds: ms), body));
    }
  }
  if (synced.length >= 2) {
    synced.sort((a, b) => a.time!.compareTo(b.time!));
    return Lyrics(synced, synced: true);
  }
  if (plain.isEmpty && synced.isEmpty) return null;
  return Lyrics([for (final l in plain) LyricLine(null, l)], synced: false);
}

final _cache = <String, Lyrics?>{};

/// Looks for lyrics for [t]: a `.lrc` file beside an imported file, then
/// lyrics embedded in the file's tags.
Future<Lyrics?> loadLyrics(Track t) async {
  if (_cache.containsKey(t.key)) return _cache[t.key];
  Lyrics? found;
  try {
    if (t.source == TrackSource.imported && !t.uri.startsWith('blob:')) {
      final side = File(p.setExtension(t.uri, '.lrc'));
      if (await side.exists()) found = parseLyrics(await side.readAsString());
    }
    if (found == null && studioSupported && !t.uri.startsWith('blob:')) {
      final info = await probe(await ffmpegInput(t));
      for (final e in info.tags.entries) {
        if (e.key.startsWith('lyrics') || e.key.startsWith('unsyncedlyrics') || e.key == 'uslt') {
          found = parseLyrics(e.value);
          if (found != null) break;
        }
      }
    }
  } catch (_) {}
  return _cache[t.key] = found;
}
