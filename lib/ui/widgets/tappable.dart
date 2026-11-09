import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';

/// How a [Tappable] responds while pressed.
enum Press {
  /// Fades to 55%: iOS buttons and bar items.
  dim,

  /// Shrinks slightly: tiles and cards.
  scale,

  /// Paints a fill behind the content: list rows.
  fill,
  none,
}

/// A tap target with iOS press feedback and button semantics.
class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.press = Press.dim,
    this.label,
    this.selected,
    this.radius = BorderRadius.zero,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Press press;
  final String? label;
  final bool? selected;
  final BorderRadius radius;
  final HitTestBehavior behavior;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final active = widget.onTap != null || widget.onLongPress != null;
    Widget c = widget.child;
    switch (widget.press) {
      case Press.dim:
        c = AnimatedOpacity(
          opacity: _down ? .55 : 1,
          duration: Duration(milliseconds: _down ? 40 : 180),
          child: c,
        );
      case Press.scale:
        c = AnimatedScale(
          scale: _down ? .96 : 1,
          duration: Duration(milliseconds: _down ? 70 : 220),
          curve: Curves.easeOut,
          child: c,
        );
      case Press.fill:
        c = DecoratedBox(
          decoration: BoxDecoration(color: _down ? t.fill : const Color(0x00000000), borderRadius: widget.radius),
          child: c,
        );
      case Press.none:
        break;
    }
    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      selected: widget.selected,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: c,
      ),
    );
  }
}
