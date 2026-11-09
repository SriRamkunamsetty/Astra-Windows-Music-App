import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';
import 'glass.dart';
import 'tappable.dart';

class MenuAction {
  const MenuAction(this.label, this.icon, this.onTap, {this.destructive = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// Shows a glass context menu next to [anchor] (the widget that opened it).
/// Each action closes the menu, then runs.
Future<void> showAstraMenu(BuildContext anchor, List<MenuAction> actions, {Alignment align = Alignment.topRight}) {
  final box = anchor.findRenderObject() as RenderBox?;
  final overlay = Navigator.of(anchor, rootNavigator: true).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null || !box.hasSize) return Future.value();
  final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  final t = anchor.tk;
  return Navigator.of(anchor, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x00000000),
      transitionDuration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      reverseTransitionDuration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
      pageBuilder: (context, a, b) => _MenuLayer(anchor: rect, actions: actions, tokens: t),
      transitionsBuilder: (context, a, b, child) => child,
    ),
  );
}

class _MenuLayer extends StatelessWidget {
  const _MenuLayer({required this.anchor, required this.actions, required this.tokens});
  final Rect anchor;
  final List<MenuAction> actions;
  final AstraTokens tokens;

  static const double width = 262, rowH = 46;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final h = actions.length * rowH;
    // Prefer right-aligned under the anchor; flip above when it won't fit.
    var left = (anchor.right - width).clamp(12.0, size.width - width - 12);
    if (anchor.center.dx < size.width / 3) left = anchor.left.clamp(12.0, size.width - width - 12);
    var top = anchor.bottom + 8;
    final above = top + h > size.height - pad.bottom - 12;
    if (above) top = (anchor.top - 8 - h).clamp(pad.top + 8, size.height);
    final origin = Alignment(((anchor.center.dx - left) / width * 2 - 1).clamp(-1.0, 1.0), above ? 1 : -1);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: t.reduceMotion ? 1 : .6, end: 1),
            duration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Opacity(
              opacity: ((v - .6) / .4).clamp(0.0, 1.0),
              child: Transform.scale(scale: v, alignment: origin, child: child),
            ),
            child: AstraTheme(
              tokens: t,
              child: Glass(
                radius: 24,
                fill: t.dark ? const Color(0xE62C2C2E) : const Color(0xE6F7F7F9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) SizedBox(height: .5, child: ColoredBox(color: t.separator)),
                      Tappable(
                        press: Press.fill,
                        label: a.label,
                        onTap: () {
                          Navigator.of(context).pop();
                          a.onTap();
                        },
                        child: SizedBox(
                          height: rowH,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.body.copyWith(color: a.destructive ? const Color(0xFFFF3B30) : t.label),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(a.icon, size: 19, color: a.destructive ? const Color(0xFFFF3B30) : t.label),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
