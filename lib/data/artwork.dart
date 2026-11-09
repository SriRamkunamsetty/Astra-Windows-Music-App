import 'package:flutter/foundation.dart';

import '../platform/native_media.dart';
import 'track.dart';

/// Lazily loads embedded album art and shares it between
/// every widget showing the same track/album.
class Artwork {
  Artwork._();
  static final instance = Artwork._();

  final _byAlbum = <String, ValueNotifier<Uint8List?>>{};
  static final _none = ValueNotifier<Uint8List?>(null);

  ValueListenable<Uint8List?> listen(Track t) {
    if (t.source != TrackSource.device && t.source != TrackSource.imported) return _none;
    final k = t.uri.isNotEmpty ? t.uri : t.key;
    final existing = _byAlbum[k];
    if (existing != null) return existing;
    final n = _byAlbum[k] = ValueNotifier<Uint8List?>(null);
    NativeMedia.albumArt(t.uri, t.albumId).then((b) {
      if (b != null && b.isNotEmpty) n.value = b;
    });
    return n;
  }
}
