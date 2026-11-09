import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'collections.dart';
import 'settings_store.dart';
import 'track.dart';
import '../platform/audio_tag_reader.dart';

enum LibraryAccess { notNeeded, unknown, granted, denied, permanentlyDenied }

/// The eight bundled sample tracks: short synthesized clips so the app has
/// something to play before the person adds music.
final sampleTracks = <Track>[
  for (final (i, t) in const [
    // title, artist, album, ms, track number, year
    ('Slow Orchard', 'Mara Oake', 'Orchard Hours', 36075, 1, 2025),
    ('Clay & Honey', 'The Terracottas', 'Warm Clay', 32052, 1, 2024),
    ('Low Tide Letters', 'Juniper Lane', 'Letters from Low Tide', 40072, 1, 2025),
    ('Marigold Hour', 'Odd Moss', 'Marigold', 30067, 1, 2023),
    ('Paper Lanterns', 'Pell & Wren', 'Paper Lanterns', 38060, 1, 2026),
    ('Fern Static', 'Odd Moss', 'Marigold', 34064, 2, 2023),
    ('Saltwater Radio', 'Juniper Lane', 'Letters from Low Tide', 36075, 2, 2025),
    ('Kitchen Light', 'Mara Oake', 'Orchard Hours', 28056, 2, 2025),
  ].indexed)
    Track(
      key: 'sample:$i',
      title: t.$1,
      artist: t.$2,
      album: t.$3,
      duration: Duration(milliseconds: t.$4),
      uri: 'asset:///assets/samples/sample_$i.mp3',
      mime: 'audio/mpeg',
      source: TrackSource.sample,
      art: ArtSpec.presets[i],
      added: DateTime(2026, 1, 1 + i),
      trackNo: t.$5,
      year: t.$6,
    ),
];

/// Windows music library: scans user's Music folder, imported files, and samples.
class LibraryRepository extends ChangeNotifier {
  LibraryRepository(this._prefs, this._settings) {
    _settings.addListener(_onSettings);
    _samplesOn = _settings.samples;
    _imported = [
      for (final s in _prefs.getStringList('imports') ?? const <String>[])
        Track.importedFromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    _imported.removeWhere((t) => !File(t.uri).existsSync());
  }

  final SharedPreferences _prefs;
  final SettingsStore _settings;
  late bool _samplesOn;

  List<Track> _device = const [];
  List<Track> _imported = [];
  LibraryAccess access = LibraryAccess.granted;
  bool scanning = false;

  List<Track>? _tracksCache;
  List<Album>? _albumsCache;
  List<Artist>? _artistsCache;

  @override
  void notifyListeners() {
    _tracksCache = _albumsCache = _artistsCache = null;
    _byKeyCache.clear();
    super.notifyListeners();
  }

  List<Track> get tracks => _tracksCache ??= [..._device, ..._imported, if (_settings.samples) ...sampleTracks];
  List<Album> get albums => _albumsCache ??= buildAlbums(tracks);
  List<Artist> get artists => _artistsCache ??= buildArtists(tracks, albums);
  bool get isEmpty => tracks.isEmpty;
  bool get ready => true;

  final _byKeyCache = <String, Track>{};
  Track? byKey(String key) {
    if (_byKeyCache.isEmpty) {
      for (final t in tracks) {
        _byKeyCache[t.key] = t;
      }
    }
    return _byKeyCache[key];
  }

  Album? albumOf(Track t) {
    for (final a in albums) {
      if (a.tracks.any((x) => x.key == t.key)) return a;
    }
    return null;
  }

  Artist? artistOf(Track t) {
    for (final a in artists) {
      if (a.name == t.artist) return a;
    }
    return null;
  }

  void _onSettings() {
    if (_settings.samples != _samplesOn) {
      _samplesOn = _settings.samples;
      notifyListeners();
    }
  }

  /// Scans Windows `%USERPROFILE%\Music` folder for audio files.
  Future<void> scan({bool ask = true}) async {
    scanning = true;
    notifyListeners();
    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final musicPath = p.join(userProfile, 'Music');
      final musicDir = Directory(musicPath);

      final found = <Track>[];
      if (musicDir.existsSync()) {
        final audioExtensions = {'.mp3', '.m4a', '.flac', '.wav', '.ogg', '.opus', '.aac', '.wma'};
        final entities = musicDir.listSync(recursive: true, followLinks: false);
        for (final e in entities) {
          if (e is File) {
            final ext = p.extension(e.path).toLowerCase();
            if (audioExtensions.contains(ext)) {
              final base = p.basenameWithoutExtension(e.path);
              String title = base;
              String artist = 'Local Audio';
              String album = 'My Music';
              if (base.contains(' - ')) {
                final parts = base.split(' - ');
                if (parts.length >= 2) {
                  artist = parts[0].trim();
                  title = parts.sublist(1).join(' - ').trim();
                }
              }

              // Read embedded ID3/Vorbis/MP4 tags
              try {
                final tag = await AudioTagReader.readMetadata(e.path);
                if (tag.title != null && tag.title!.isNotEmpty) title = tag.title!;
                if (tag.artist != null && tag.artist!.isNotEmpty) artist = tag.artist!;
                if (tag.album != null && tag.album!.isNotEmpty) album = tag.album!;
              } catch (_) {}

              found.add(
                Track(
                  key: 'win:${e.path}',
                  title: title,
                  artist: artist,
                  album: album,
                  duration: Duration.zero,
                  uri: e.path,
                  mime: _mimeFor(e.path),
                  source: TrackSource.device,
                  art: ArtSpec.forKey(base),
                  added: e.lastModifiedSync(),
                ),
              );
            }
          }
        }
      }
      _device = found;
      access = LibraryAccess.granted;
    } catch (err) {
      debugPrint('Scan error: $err');
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> openPermissionSettings() async {}

  Future<int> importFiles() async {
    final res = await FilePicker.pickFiles(type: FileType.audio);
    if (res.isEmpty) return 0;
    var added = 0;
    for (final f in res) {
      if (f.path != null) {
        final file = File(f.path!);
        final base = p.basenameWithoutExtension(file.path);
        final t = Track(
          key: 'file:${file.path}',
          title: base,
          artist: 'Imported',
          album: 'Imported Music',
          duration: Duration.zero,
          uri: file.path,
          mime: _mimeFor(file.path),
          source: TrackSource.imported,
          art: ArtSpec.forKey(base),
          added: DateTime.now(),
        );
        _imported.add(t);
        added++;
      }
    }
    await _prefs.setStringList('imports', [for (final t in _imported) jsonEncode(t.toJson())]);
    notifyListeners();
    return added;
  }

  static String _mimeFor(String name) => switch (p.extension(name).toLowerCase()) {
    '.mp3' => 'audio/mpeg',
    '.m4a' || '.aac' || '.mp4' => 'audio/mp4',
    '.flac' => 'audio/flac',
    '.wav' => 'audio/wav',
    '.ogg' || '.oga' => 'audio/ogg',
    '.opus' => 'audio/opus',
    _ => 'audio/*',
  };
}
