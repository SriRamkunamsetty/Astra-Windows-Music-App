import 'track.dart';

/// An album: tracks that share an album identity, in disc/track order.
class Album {
  Album._(this.id, this.name, this.artist, this.tracks)
    : cover = tracks.first,
      year = tracks.map((t) => t.year).whereType<int>().fold<int?>(null, (a, b) => a == null || b < a ? b : a),
      added = tracks
          .map((t) => t.added)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

  final String id, name, artist;
  final List<Track> tracks;
  final Track cover;
  final int? year;
  final DateTime? added;

  Duration get duration => tracks.fold(Duration.zero, (a, t) => a + t.duration);
}

class Artist {
  Artist._(this.name, this.tracks, this.albums);

  final String name;
  final List<Track> tracks;
  final List<Album> albums;

  Track get cover => (albums.isNotEmpty ? albums.first.cover : tracks.first);
}

int _byTrackOrder(Track a, Track b) {
  final d = a.discNo.compareTo(b.discNo);
  if (d != 0) return d;
  if (a.trackNo != b.trackNo && a.trackNo != 0 && b.trackNo != 0) return a.trackNo.compareTo(b.trackNo);
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

/// Groups [all] into albums. Device tracks group by MediaStore album id,
/// everything else by case-insensitive album name.
List<Album> buildAlbums(List<Track> all) {
  final by = <String, List<Track>>{};
  for (final t in all) {
    final k = t.albumId != null ? 'id:${t.albumId}' : 'n:${t.album.toLowerCase()}';
    (by[k] ??= []).add(t);
  }
  final out = <Album>[];
  by.forEach((id, ts) {
    ts.sort(_byTrackOrder);
    final artists = ts.map((t) => t.artist).toSet();
    out.add(Album._(id, ts.first.album, artists.length == 1 ? artists.first : 'Various Artists', ts));
  });
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

List<Artist> buildArtists(List<Track> all, List<Album> albums) {
  final by = <String, List<Track>>{};
  for (final t in all) {
    (by[t.artist] ??= []).add(t);
  }
  final out = <Artist>[];
  by.forEach((name, ts) {
    final mine = albums.where((a) => a.tracks.any((t) => t.artist == name)).toList();
    out.add(Artist._(name, ts, mine));
  });
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

/// The index letter used by the alphabetical section headers.
String indexLetter(String s) {
  final t = s.trim();
  if (t.isEmpty) return '#';
  final c = t[0].toUpperCase();
  return RegExp('[A-Z]').hasMatch(c) ? c : '#';
}
