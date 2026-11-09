import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../data/artwork.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';

/// Cover art for a track: embedded artwork when the platform provides it,
/// otherwise a gradient tile with a note, like Apple Music's placeholder.
class TrackArt extends StatelessWidget {
  const TrackArt(this.track, {super.key, this.size, this.radius, this.circle = false, this.shadow = false});

  final Track track;
  final double? size;

  /// Defaults to [artRadius] for the rendered size.
  final double? radius;
  final bool circle;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = size ?? (c.hasBoundedWidth ? c.maxWidth : 56);
        final r = circle ? side / 2 : (radius ?? artRadius(side));
        final art = ValueListenableBuilder<Uint8List?>(
          valueListenable: Artwork.instance.listen(track),
          builder: (context, bytes, _) => bytes == null
              ? PlaceholderArt(track.art, size: side)
              : Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  width: side,
                  height: side,
                  errorBuilder: (_, _, _) => PlaceholderArt(track.art, size: side),
                ),
        );
        Widget clipped = SizedBox(
          width: side,
          height: side,
          child: circle ? ClipOval(child: art) : ClipRSuperellipse(borderRadius: BorderRadius.circular(r), child: art),
        );
        if (shadow) {
          clipped = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(circle ? side : r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: .28),
                  blurRadius: side * .12 + 6,
                  offset: Offset(0, side * .04 + 2),
                ),
              ],
            ),
            child: clipped,
          );
        }
        return clipped;
      },
    );
  }
}

/// The generated tile: a diagonal gradient, a soft highlight, a music note.
class PlaceholderArt extends StatelessWidget {
  const PlaceholderArt(this.spec, {super.key, required this.size});
  final ArtSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = math.min(size * .42, 96.0);
    final (hx, hy) = switch (spec.variant % 4) {
      0 => (-.55, -.7),
      1 => (.6, -.6),
      2 => (-.6, .55),
      _ => (.55, .6),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [spec.c1, spec.c2]),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(hx, hy),
            radius: .9,
            colors: [spec.c3.withValues(alpha: .38), spec.c3.withValues(alpha: 0)],
          ),
        ),
        child: Center(
          child: Icon(CupertinoIcons.music_note_2, size: glyph, color: const Color(0xFFFFFFFF).withValues(alpha: .86)),
        ),
      ),
    );
  }
}

/// The colours Now Playing and the album/artist pages take from a cover.
///
/// Embedded artwork is sampled in four quadrants; generated tiles use their
/// own gradient. Results are cached per track.
class ArtColors {
  ArtColors._();
  static final instance = ArtColors._();

  final _cache = <String, ValueNotifier<List<Color>>>{};

  /// Always returns a list of at least two colours; embedded art refines it
  /// once decoded.
  ValueListenable<List<Color>> listen(Track t) {
    final hit = _cache[t.key];
    if (hit != null) return hit;
    final n = _cache[t.key] = ValueNotifier<List<Color>>([t.art.c1, t.art.c2]);
    final src = Artwork.instance.listen(t);
    void sample() {
      final bytes = src.value;
      if (bytes == null) return;
      _sample(bytes).then((cs) {
        if (cs != null) n.value = cs;
      });
    }

    src.addListener(sample);
    sample();
    return n;
  }

  Future<List<Color>?> _sample(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 16, targetHeight: 16);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      const n = 16;
      Color quad(int x0, int y0) {
        var r = 0, g = 0, b = 0, c = 0;
        for (var y = y0; y < y0 + n ~/ 2; y++) {
          for (var x = x0; x < x0 + n ~/ 2; x++) {
            final o = (y * n + x) * 4;
            r += data.getUint8(o);
            g += data.getUint8(o + 1);
            b += data.getUint8(o + 2);
            c++;
          }
        }
        return Color.fromARGB(255, r ~/ c, g ~/ c, b ~/ c);
      }

      return [quad(0, 0), quad(n ~/ 2, n ~/ 2), quad(n ~/ 2, 0), quad(0, n ~/ 2)];
    } catch (_) {
      return null;
    }
  }
}
