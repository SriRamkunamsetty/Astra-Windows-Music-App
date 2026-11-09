import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';

/// iOS 26 "Liquid Glass": the content behind is blurred and saturated, a
/// translucent fill sits on top, a specular rim catches light along the top-
/// left and bottom-right edges, and a soft shadow lifts the surface.
///
/// [capsule] draws a pill (or a circle when the box is square); otherwise
/// the surface uses continuous (squircle) corners of [radius].
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.capsule = false,
    this.tint,
    this.fill,
    this.padding,
    this.shadow = true,
    this.rim = true,
  });

  final Widget child;
  final double radius;
  final bool capsule;

  /// Colour washed over the glass (a selected tab, an accent button).
  final Color? tint;

  /// Overrides the default translucent fill.
  final Color? fill;
  final EdgeInsetsGeometry? padding;
  final bool shadow, rim;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final base = fill ?? t.glassFill;
    Widget body = DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: tint == null
          ? (padding == null ? child : Padding(padding: padding!, child: child))
          : DecoratedBox(
              decoration: BoxDecoration(color: tint),
              child: padding == null ? child : Padding(padding: padding!, child: child),
            ),
    );
    if (t.glassBlur > 0) {
      body = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: t.glassBlur, sigmaY: t.glassBlur),
        child: body,
      );
    }
    final clip = capsule
        ? ClipRRect(borderRadius: BorderRadius.circular(9999), child: body)
        : ClipRSuperellipse(borderRadius: BorderRadius.circular(radius), child: body);
    return RepaintBoundary(
      child: CustomPaint(
        painter: shadow ? _ShadowPainter(t.glassShadow, capsule ? null : radius) : null,
        foregroundPainter: rim ? _RimPainter(t, capsule ? null : radius) : null,
        child: clip,
      ),
    );
  }
}

/// A shadow painted only outside the shape, so it can't show through the
/// translucent fill.
class _ShadowPainter extends CustomPainter {
  _ShadowPainter(this.color, this.radius);
  final Color color;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = radius ?? size.shortestSide / 2;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(r));
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(80))
        ..addRRect(rr),
    );
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rr.shift(const Offset(0, 6)), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.color != color || old.radius != radius;
}

class _RimPainter extends CustomPainter {
  _RimPainter(this.t, this.radius);
  final AstraTokens t;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = radius ?? size.shortestSide / 2;
    final rr = RRect.fromRectAndRadius(rect.deflate(.5), Radius.circular(math.max(0, r - .5)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          t.glassEdgeHi,
          t.glassEdgeLo,
          t.glassEdgeLo,
          t.glassEdgeHi.withValues(alpha: t.glassEdgeHi.a * .6),
        ],
        stops: const [0, .35, .65, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.t != t || old.radius != radius;
}
