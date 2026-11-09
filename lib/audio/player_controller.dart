import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_repository.dart';
import '../data/settings_store.dart';
import '../data/track.dart';

enum Repeat { off, all, one }

typedef QueueEntry = (Track, int);

/// Owns audio playback on Windows desktop: queue, transport, shuffle/repeat/speed,
/// favourites, play history and session restore.
class PlayerController extends ChangeNotifier {
  PlayerController(this._prefs, this._settings) {
    favorites = {...?_prefs.getStringList('favs')};
    recentKeys = [...?_prefs.getStringList('recent')];
    final plays = _prefs.getString('plays');
    if (plays != null) {
      try {
        playCounts = (jsonDecode(plays) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }
    shuffle = _prefs.getBool('shuffle') ?? false;
    repeat = Repeat.values[(_prefs.getInt('repeat') ?? 0).clamp(0, 2)];
    speed = _prefs.getDouble('speed') ?? 1.0;
    _wire();
  }

  final SharedPreferences _prefs;
  // ignore: unused_field
  final SettingsStore _settings;
  final player = AudioPlayer();
  LibraryRepository? library;

  List<Track> queue = const [];
  String from = 'Library';
  int? index;
  bool playing = false;
  bool shuffle = false;
  Repeat repeat = Repeat.off;
  double speed = 1.0;

  final volume = ValueNotifier<double>(1.0);
  late Set<String> favorites;
  late List<String> recentKeys;
  Map<String, int> playCounts = {};
  String outputLabel = 'PC Audio';
  String outputIcon = 'speaker';

  final position = ValueNotifier<Duration>(Duration.zero);
  Duration? _duration;
  final toast = ValueNotifier<String?>(null);

  Track? get current => (index != null && index! >= 0 && index! < queue.length) ? queue[index!] : null;
  Duration get duration => _duration ?? current?.duration ?? Duration.zero;
  bool isFav(Track t) => favorites.contains(t.key);
  bool isCurrent(Track t) => current?.key == t.key;

  final _subs = <StreamSubscription<dynamic>>[];
  String? _lastCounted;

  Future<void> init() async {
    await player.setPlaybackRate(speed);
    await player.setVolume(volume.value);
  }

  void _wire() {
    _subs.add(
      player.onPlayerStateChanged.listen((state) {
        final isPlay = state == PlayerState.playing;
        if (playing != isPlay) {
          playing = isPlay;
          if (isPlay) _recordPlay();
          notifyListeners();
          if (!isPlay) _saveSession(force: true);
        }
      }),
    );

    _subs.add(
      player.onPositionChanged.listen((p) {
        position.value = p;
        _saveSession();
      }),
    );

    _subs.add(
      player.onDurationChanged.listen((d) {
        _duration = d;
        notifyListeners();
      }),
    );

    _subs.add(
      player.onPlayerComplete.listen((_) async {
        if (repeat == Repeat.one) {
          seek(Duration.zero);
          play();
        } else if (repeat == Repeat.all || (index != null && index! < queue.length - 1)) {
          await next();
        } else {
          // Completed queue with repeat off
          playing = false;
          seek(Duration.zero);
          notifyListeners();
        }
      }),
    );
  }

  Source _sourceForTrack(Track t) {
    if (t.uri.startsWith('asset:///')) {
      final path = t.uri.substring('asset:///'.length);
      return AssetSource(path);
    } else if (t.uri.startsWith('assets/')) {
      return AssetSource(t.uri);
    } else {
      final local = t.uri.startsWith('file://') ? Uri.parse(t.uri).toFilePath() : t.uri;
      return DeviceFileSource(local);
    }
  }

  Future<void> playList(
    List<Track> list,
    int start, {
    String from = 'Library',
    bool autoplay = true,
    Duration at = Duration.zero,
  }) async {
    if (list.isEmpty) return;
    start = start.clamp(0, list.length - 1);
    queue = List.of(list);
    this.from = from;
    index = start;
    position.value = at;
    _duration = list[start].duration;
    notifyListeners();

    try {
      final t = list[start];
      final src = _sourceForTrack(t);
      if (autoplay) {
        await player.play(src, position: at > Duration.zero ? at : null);
        playing = true;
      } else {
        await player.setSource(src);
        if (at > Duration.zero) await player.seek(at);
      }
      notifyListeners();
    } catch (e) {
      toast.value = "Couldn't open ${list[start].title}";
      debugPrint("Audio error: $e");
    }
  }

  Future<void> shufflePlay(List<Track> list, {String from = 'Library'}) async {
    if (list.isEmpty) return;
    if (!shuffle) {
      shuffle = true;
      _prefs.setBool('shuffle', true);
    }
    final shuffled = List<Track>.of(list)..shuffle();
    await playList(shuffled, 0, from: from);
  }

  void togglePlay() {
    if (current == null) return;
    if (playing) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (current == null && queue.isNotEmpty) {
      playList(queue, 0);
      return;
    }
    player.resume();
    playing = true;
    notifyListeners();
  }

  void pause() {
    player.pause();
    playing = false;
    notifyListeners();
  }

  Future<void> next() async {
    if (queue.isEmpty) {
      final all = library?.tracks ?? const [];
      if (all.isNotEmpty) {
        await playList(all, 0, from: 'Library');
      }
      return;
    }

    final cur = index ?? 0;

    // Handle shuffle mode when multiple songs exist in the queue
    if (shuffle && queue.length > 1) {
      final candidates = [for (var i = 0; i < queue.length; i++) if (i != cur) i];
      if (candidates.isNotEmpty) {
        final nextIdx = candidates[math.Random().nextInt(candidates.length)];
        await _playIndex(nextIdx);
        return;
      }
    }

    // Advance to next song in the active queue
    if (cur < queue.length - 1) {
      await _playIndex(cur + 1);
      return;
    }

    // At the end of the active queue (or single-track queue)
    if (repeat == Repeat.all || queue.length > 1) {
      // Loop back to the beginning of the queue
      await _playIndex(0);
      return;
    }

    // If queue only has 1 track (e.g. played directly from search), continue with library
    final all = library?.tracks ?? const [];
    if (all.isNotEmpty) {
      final currentKey = queue[cur].key;
      final libIdx = all.indexWhere((t) => t.key == currentKey);
      final nextLibIdx = (libIdx >= 0 && libIdx < all.length - 1) ? libIdx + 1 : 0;
      await playList(all, nextLibIdx, from: 'Library');
    } else {
      seek(Duration.zero);
    }
  }

  Future<void> prev() async {
    if (queue.isEmpty) {
      final all = library?.tracks ?? const [];
      if (all.isNotEmpty) {
        await playList(all, 0, from: 'Library');
      }
      return;
    }

    // If past 3 seconds, standard music player behavior is to seek to track start
    if (position.value > const Duration(seconds: 3)) {
      seek(Duration.zero);
      return;
    }

    final cur = index ?? 0;
    if (cur > 0) {
      await _playIndex(cur - 1);
      return;
    }

    // At the start of the queue
    if (queue.length > 1) {
      await _playIndex(queue.length - 1);
      return;
    }

    // If queue only has 1 track, pick previous from library
    final all = library?.tracks ?? const [];
    if (all.isNotEmpty) {
      final currentKey = queue[cur].key;
      final libIdx = all.indexWhere((t) => t.key == currentKey);
      final prevLibIdx = libIdx > 0 ? libIdx - 1 : all.length - 1;
      await playList(all, prevLibIdx, from: 'Library');
    } else {
      seek(Duration.zero);
    }
  }

  Future<void> _playIndex(int i) async {
    if (queue.isEmpty) return;
    index = i.clamp(0, queue.length - 1);
    final t = queue[index!];
    _duration = t.duration;
    position.value = Duration.zero;
    notifyListeners();
    try {
      final src = _sourceForTrack(t);
      await player.play(src);
      playing = true;
      _recordPlay();
      _saveSession(force: true);
      notifyListeners();
    } catch (e) {
      toast.value = "Couldn't open ${t.title}";
      debugPrint("Audio error: $e");
    }
  }

  void seek(Duration d) {
    final max = duration;
    final clamped = d < Duration.zero ? Duration.zero : (max > Duration.zero && d > max ? max : d);
    position.value = clamped;
    player.seek(clamped);
  }

  Future<void> playAt(int queueIndex) async {
    await _playIndex(queueIndex);
  }

  void toggleFav(Track t) {
    if (favorites.contains(t.key)) {
      favorites.remove(t.key);
    } else {
      favorites.add(t.key);
    }
    _prefs.setStringList('favs', favorites.toList());
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    _prefs.setBool('shuffle', shuffle);
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = switch (repeat) {
      Repeat.off => Repeat.all,
      Repeat.all => Repeat.one,
      Repeat.one => Repeat.off,
    };
    _prefs.setInt('repeat', repeat.index);
    notifyListeners();
  }

  static const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  void setSpeed(double s) {
    speed = s;
    _prefs.setDouble('speed', s);
    player.setPlaybackRate(s);
    notifyListeners();
  }

  void haptic() {}

  Future<void> addToQueue(Track t) async {
    playLater(t);
  }

  List<QueueEntry> get upNext {
    if (queue.isEmpty || index == null) return const [];
    final cur = index!;
    if (cur >= queue.length - 1) return const [];
    return [for (var i = cur + 1; i < queue.length; i++) (queue[i], i)];
  }

  List<QueueEntry> get history {
    if (queue.isEmpty || index == null) return const [];
    final cur = index!;
    if (cur <= 0) return const [];
    return [for (var i = 0; i < cur; i++) (queue[i], i)];
  }

  void cycleSpeed() {
    speed = switch (speed) {
      1.0 => 1.25,
      1.25 => 1.5,
      1.5 => 2.0,
      2.0 => 0.75,
      _ => 1.0,
    };
    player.setPlaybackRate(speed);
    _prefs.setDouble('speed', speed);
    notifyListeners();
  }

  void setVolume(double v) {
    volume.value = v.clamp(0.0, 1.0);
    player.setVolume(volume.value);
  }

  Future<void> playNext(Track t) async {
    if (queue.isEmpty) {
      await playList([t], 0);
      return;
    }
    final nextIdx = (index ?? 0) + 1;
    final updated = List<Track>.of(queue);
    updated.insert(nextIdx.clamp(0, updated.length), t);
    queue = updated;
    notifyListeners();
  }

  void playLater(Track t) {
    if (queue.isEmpty) {
      playList([t], 0);
      return;
    }
    final updated = List<Track>.of(queue)..add(t);
    queue = updated;
    notifyListeners();
  }

  void removeFromQueue(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= queue.length) return;
    final updated = List<Track>.of(queue)..removeAt(queueIndex);
    queue = updated;
    if (index != null && queueIndex < index!) {
      index = index! - 1;
    } else if (index != null && index! >= queue.length) {
      index = queue.isEmpty ? null : queue.length - 1;
    }
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final updated = List<Track>.of(queue);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    if (index == oldIndex) {
      index = newIndex;
    } else if (oldIndex < (index ?? -1) && newIndex >= (index ?? -1)) {
      index = (index ?? 0) - 1;
    } else if (oldIndex > (index ?? -1) && newIndex <= (index ?? -1)) {
      index = (index ?? 0) + 1;
    }
    queue = updated;
    notifyListeners();
  }

  void clearQueue() {
    player.stop();
    playing = false;
    queue = const [];
    index = null;
    position.value = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  Future<void> restore(dynamic lib) async {
    try {
      if (lib is LibraryRepository) {
        library = lib;
      }
      final tracks = (lib.tracks as List).cast<Track>();
      restoreSession(tracks);
    } catch (_) {}
  }

  void restoreSession(List<Track> allTracks) {
    final raw = _prefs.getString('session');
    if (raw == null) return;
    try {
      final s = jsonDecode(raw) as Map<String, dynamic>;
      final keys = (s['queue'] as List<dynamic>? ?? []).cast<String>();
      final byKey = {for (final t in allTracks) t.key: t};
      final q = [for (final k in keys) if (byKey[k] != null) byKey[k]!];
      if (q.isNotEmpty) {
        final startIdx = (s['index'] as int? ?? 0).clamp(0, q.length - 1);
        final atMs = s['pos'] as int? ?? 0;
        playList(q, startIdx, from: s['from'] as String? ?? 'Library', autoplay: false, at: Duration(milliseconds: atMs));
      }
    } catch (_) {}
  }

  void _recordPlay() {
    final t = current;
    if (t == null) return;
    if (recentKeys.isEmpty || recentKeys.first != t.key) {
      recentKeys = [t.key, ...recentKeys.where((k) => k != t.key)].take(40).toList();
      _prefs.setStringList('recent', recentKeys);
    }
    if (_lastCounted != t.key) {
      _lastCounted = t.key;
      playCounts = {...playCounts, t.key: (playCounts[t.key] ?? 0) + 1};
      _prefs.setString('plays', jsonEncode(playCounts));
    }
  }

  DateTime _lastSave = DateTime(0);
  void _saveSession({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastSave).inSeconds < 5) return;
    _lastSave = now;
    if (queue.isEmpty) return;
    _prefs.setString(
      'session',
      jsonEncode({
        'queue': [for (final t in queue) t.key],
        'index': index ?? 0,
        'from': from,
        'pos': position.value.inMilliseconds,
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    player.dispose();
    super.dispose();
  }
}
