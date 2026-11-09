import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'track.dart';

class Playlist {
  Playlist({required this.id, required this.name, required this.keys, required this.created});

  final String id;
  String name;

  /// Track keys, in order. Keys of tracks that are no longer in the library
  /// are kept so a playlist survives a rescan; callers skip the missing ones.
  List<String> keys;
  final DateTime created;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'keys': keys, 'created': created.millisecondsSinceEpoch};

  static Playlist fromJson(Map<String, dynamic> j) => Playlist(
    id: j['id'] as String,
    name: j['name'] as String,
    keys: [...(j['keys'] as List).cast<String>()],
    created: DateTime.fromMillisecondsSinceEpoch((j['created'] as num).toInt()),
  );
}

/// User playlists, persisted in preferences.
class PlaylistStore extends ChangeNotifier {
  PlaylistStore(this._prefs) {
    final raw = _prefs.getString('playlists');
    if (raw != null) {
      try {
        _all = [for (final j in jsonDecode(raw) as List) Playlist.fromJson(j as Map<String, dynamic>)];
      } catch (_) {
        _all = [];
      }
    }
  }

  final SharedPreferences _prefs;
  List<Playlist> _all = [];

  List<Playlist> get all => List.unmodifiable(_all);

  Playlist? byId(String id) {
    for (final p in _all) {
      if (p.id == id) return p;
    }
    return null;
  }

  Playlist create(String name, {List<Track> tracks = const []}) {
    final p = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name.trim().isEmpty ? 'New Playlist' : name.trim(),
      keys: [for (final t in tracks) t.key],
      created: DateTime.now(),
    );
    _all = [p, ..._all];
    _save();
    return p;
  }

  void rename(String id, String name) {
    final p = byId(id);
    if (p == null || name.trim().isEmpty) return;
    p.name = name.trim();
    _save();
  }

  void delete(String id) {
    _all = _all.where((p) => p.id != id).toList();
    _save();
  }

  /// Adds [tracks] to the end, skipping ones already present.
  int add(String id, Iterable<Track> tracks) {
    final p = byId(id);
    if (p == null) return 0;
    var n = 0;
    for (final t in tracks) {
      if (!p.keys.contains(t.key)) {
        p.keys.add(t.key);
        n++;
      }
    }
    if (n > 0) _save();
    return n;
  }

  void removeAt(String id, int index) {
    final p = byId(id);
    if (p == null || index < 0 || index >= p.keys.length) return;
    p.keys.removeAt(index);
    _save();
  }

  void move(String id, int from, int to) {
    final p = byId(id);
    if (p == null) return;
    final k = p.keys.removeAt(from);
    p.keys.insert(to.clamp(0, p.keys.length), k);
    _save();
  }

  void _save() {
    _prefs.setString('playlists', jsonEncode([for (final p in _all) p.toJson()]));
    notifyListeners();
  }
}
