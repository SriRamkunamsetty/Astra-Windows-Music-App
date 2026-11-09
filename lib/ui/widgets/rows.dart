import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import 'artwork.dart';
import 'tappable.dart';

/// The animated four-bar "now playing" indicator.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key, required this.color, required this.animating, this.size = 18});
  final Color color;
  final bool animating;
  final double size;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.animating) _c.repeat();
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.animating && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animating && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.tk.reduceMotion;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: widget.size / 7,
                height:
                    widget.size *
                    ((widget.animating && !reduce)
                        ? .25 + .75 * (.5 + .5 * math.sin((_c.value * 2 * math.pi) + i * 1.7)).abs()
                        : .35),
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A song in a list: artwork, title, artist, optional trailing controls.
class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.track,
    required this.onTap,
    this.onMore,
    this.number,
    this.subtitle,
    this.showArt = true,
    this.showDuration = false,
    this.indent = 16,
    this.trailing,
  });

  final Track track;
  final VoidCallback onTap;

  /// Opens the track menu; receives the button's context for anchoring.
  final void Function(BuildContext)? onMore;

  /// Replaces the artwork with a track number (album pages).
  final int? number;
  final String? subtitle;
  final bool showArt, showDuration;
  final double indent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final player = AppScope.of(context).player;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final cur = player.isCurrent(track);
        final lead = number != null
            ? SizedBox(
                width: 28,
                child: Center(
                  child: cur
                      ? EqualizerBars(color: t.accent, animating: player.playing)
                      : Text('$number', style: t.body.copyWith(color: t.secondary)),
                ),
              )
            : (showArt
                  ? SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TrackArt(track, size: 52),
                          if (cur)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x73000000),
                                borderRadius: BorderRadius.circular(artRadius(52)),
                              ),
                              child: Center(
                                child: EqualizerBars(color: const Color(0xFFFFFFFF), animating: player.playing),
                              ),
                            ),
                        ],
                      ),
                    )
                  : null);
        return Tappable(
          onTap: onTap,
          press: Press.fill,
          label: '${track.title}, ${track.artist}',
          child: Padding(
            padding: EdgeInsets.only(left: indent, right: 4),
            child: SizedBox(
              height: number != null ? 54 : 64,
              child: Row(
                children: [
                  if (lead != null) ...[lead, SizedBox(width: number != null ? 12 : 14)],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.body.copyWith(color: cur && number != null ? t.accent : t.label),
                        ),
                        if ((subtitle ?? track.artist).isNotEmpty)
                          Text(
                            subtitle ?? track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.subhead.copyWith(color: t.secondary),
                          ),
                      ],
                    ),
                  ),
                  if (showDuration)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(fmtDur(track.duration), style: t.subhead.copyWith(color: t.secondary)),
                    ),
                  ?trailing,
                  if (onMore != null)
                    Builder(
                      builder: (btn) => Tappable(
                        onTap: () => onMore!(btn),
                        label: 'More options for ${track.title}',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(child: Icon(CupertinoIcons.ellipsis, size: 19, color: t.secondary)),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Square artwork with a title and subtitle beneath it (albums, mixes).
class ArtCard extends StatelessWidget {
  const ArtCard({
    super.key,
    required this.track,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.width,
    this.onLongPress,
    this.circle = false,
    this.cover,
    this.titleBold = false,
  });

  final Track track;
  final String title, subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool circle;
  final bool titleBold;

  /// Replaces the artwork (generated mix covers).
  final Widget? cover;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      onLongPress: onLongPress,
      press: Press.scale,
      label: '$title, $subtitle',
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: circle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child:
                  cover ??
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(circle ? 999 : 10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withValues(alpha: t.dark ? .35 : .16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TrackArt(track, circle: circle),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: circle ? TextAlign.center : TextAlign.start,
              style: t.subhead.copyWith(fontWeight: titleBold ? FontWeight.w700 : FontWeight.w500),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: circle ? TextAlign.center : TextAlign.start,
                style: t.subhead.copyWith(color: t.secondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// A row with a leading widget, title/subtitle and a chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.chevron = true,
    this.indent = 16,
    this.height = 64,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool chevron;
  final double indent, height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      press: Press.fill,
      label: subtitle == null ? title : '$title, $subtitle',
      child: Padding(
        padding: EdgeInsets.only(left: indent, right: 16),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.body),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.subhead.copyWith(color: t.secondary),
                      ),
                  ],
                ),
              ),
              ?trailing,
              if (chevron) ...[
                const SizedBox(width: 8),
                Icon(CupertinoIcons.chevron_forward, size: 15, color: t.tertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The accent glyph used by the Library category list.
class LibraryGlyph extends StatelessWidget {
  const LibraryGlyph(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(width: 34, child: Icon(icon, size: 26, color: context.tk.accent));
}

/// Height of an [ArtCard] of the given [width]: the square art, the gap, and
/// two text lines at the current text scale. Fixed numbers overflow on
/// wider phones and with larger system text.
double artCardHeight(BuildContext context, double width, {int lines = 2}) {
  final line = MediaQuery.textScalerOf(context).scale(20);
  return width + 8 + lines * line + 6;
}
