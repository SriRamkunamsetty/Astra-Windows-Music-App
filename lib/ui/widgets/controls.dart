import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';
import 'glass.dart';
import 'tappable.dart';

/// A round glass button (back, close, more, profile) for navigation bars.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size, iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      label: label,
      press: Press.scale,
      child: SizedBox(
        width: size,
        height: size,
        child: Glass(
          capsule: true,
          child: Center(
            child: Icon(icon, size: iconSize, color: color ?? t.label),
          ),
        ),
      ),
    );
  }
}

/// A capsule action: grey fill with an accent label ("Play", "Shuffle").
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onTap, this.icon, this.filled = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// An accent-filled primary action instead of the tinted grey one.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final fg = filled ? t.onAccent : t.accent;
    return Tappable(
      onTap: onTap,
      label: label,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: filled ? t.accent : t.fillStrong, borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.headline.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width capsule call to action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.enabled = true});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: Tappable(
        onTap: enabled ? onTap : null,
        label: label,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(27)),
          child: Text(label, style: t.headline.copyWith(color: t.onAccent)),
        ),
      ),
    );
  }
}

/// The Apple Music scrubber and volume bar: a capsule that grows under the
/// finger. [value] is 0–1.
class ScrubBar extends StatefulWidget {
  const ScrubBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.onChangeStart,
    this.active,
    this.track,
    this.semanticLabel = 'Position',
    this.semanticValue,
    this.increasedValue,
    this.decreasedValue,
    this.onIncrease,
    this.onDecrease,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback? onChangeStart;
  final Color? active, track;
  final String semanticLabel;
  final String? semanticValue;

  /// Spoken values after a step up or down. Required with [semanticValue]
  /// when the step callbacks are set.
  final String? increasedValue, decreasedValue;
  final VoidCallback? onIncrease, onDecrease;

  @override
  State<ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<ScrubBar> {
  bool _drag = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final active = widget.active ?? t.label;
    final track = widget.track ?? t.label.withValues(alpha: .22);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        double at(Offset o) => (o.dx / w).clamp(0.0, 1.0);
        return Semantics(
          slider: true,
          label: widget.semanticLabel,
          value: widget.semanticValue,
          increasedValue: widget.increasedValue,
          decreasedValue: widget.decreasedValue,
          onIncrease: widget.onIncrease,
          onDecrease: widget.onDecrease,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (e) {
              widget.onChanged(at(e.localPosition));
              widget.onChangeEnd?.call(at(e.localPosition));
            },
            onHorizontalDragStart: (e) {
              setState(() => _drag = true);
              widget.onChangeStart?.call();
              widget.onChanged(at(e.localPosition));
            },
            onHorizontalDragUpdate: (e) => widget.onChanged(at(e.localPosition)),
            onHorizontalDragEnd: (_) {
              setState(() => _drag = false);
              widget.onChangeEnd?.call(widget.value);
            },
            onHorizontalDragCancel: () => setState(() => _drag = false),
            child: SizedBox(
              height: 36,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: double.infinity,
                  height: _drag ? 12 : 6,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(6)),
                  // heightFactor: 1 matters: without it the fill has no height and is
                  // invisible, which made the bar look broken.
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.value.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(decoration: BoxDecoration(color: active)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A rounded group of rows on the grouped background (Settings style).
class InsetGroup extends StatelessWidget {
  const InsetGroup({super.key, this.header, this.footer, required this.children});

  final String? header, footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 16, 7),
              child: Text(header!.toUpperCase(), style: t.footnote.copyWith(color: t.secondary)),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: t.cell,
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(26)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, c) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _Hairline(color: t.separator),
                    ),
                  c,
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 7, 24, 0),
              child: Text(footer!, style: t.footnote.copyWith(color: t.secondary)),
            ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(height: 0.5, child: ColoredBox(color: color));
}

/// A full-width hairline separator.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: _Hairline(color: context.tk.separator),
  );
}

/// One row inside an [InsetGroup].
class InsetRow extends StatelessWidget {
  const InsetRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.destructive = false,
    this.minHeight = 52,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron, destructive;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: t.body.copyWith(color: destructive ? const Color(0xFFFF3B30) : t.label)),
                  if (subtitle != null) Text(subtitle!, style: t.footnote.copyWith(color: t.secondary)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (chevron) ...[
              const SizedBox(width: 8),
              Icon(CupertinoIcons.chevron_forward, size: 15, color: t.tertiary),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Tappable(onTap: onTap, press: Press.fill, label: title, child: row);
  }
}

/// A small rounded-square glyph tile, as in iOS Settings.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, required this.color, this.size = 30});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: ShapeDecoration(
      color: color,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * .27)),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: size * .62, color: const Color(0xFFFFFFFF)),
  );
}

/// iOS-style section title: bold, large, with an optional "See All".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll, this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 10)});
  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: t.title2)),
          if (onSeeAll != null)
            Tappable(
              onTap: onSeeAll,
              label: 'See all $title',
              child: Row(
                children: [
                  Text('See All', style: t.subhead.copyWith(color: t.accent)),
                  const SizedBox(width: 2),
                  Icon(CupertinoIcons.chevron_forward, size: 13, color: t.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
