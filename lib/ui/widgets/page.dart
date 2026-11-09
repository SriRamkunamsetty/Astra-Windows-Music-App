import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';
import '../../data/track.dart';
import 'artwork.dart';
import 'controls.dart';

/// Height of the navigation bar's button row, below the status bar.
const double kNavBarHeight = 52;

/// An iOS 26 page: a large left-aligned title that collapses into a centred
/// compact title as the content scrolls under a blurred bar, with glass
/// buttons at the edges.
///
/// Slivers are placed below the title. The bottom inset comes from
/// [MediaQuery] so content clears the floating tab bar and mini player.
class LargeTitlePage extends StatefulWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.leading,
    this.showBack,
    this.largeTitle = true,
    this.background,
    this.header,
    this.controller,
    this.wash,
    this.headerUnderBar = false,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Widget? leading;

  /// Defaults to whether the navigator can pop.
  final bool? showBack;

  /// False for pages that provide their own hero (album, artist).
  final bool largeTitle;
  final Color? background;

  /// Content between the bar and the first sliver, instead of the title.
  final Widget? header;
  final ScrollController? controller;

  /// A track whose artwork colour tints the top of the page and fades out.
  final Track? wash;

  /// Lets [header] run full-bleed under the status bar and navigation bar.
  final bool headerUnderBar;

  @override
  State<LargeTitlePage> createState() => _LargeTitlePageState();
}

class _LargeTitlePageState extends State<LargeTitlePage> {
  late final ScrollController _c = widget.controller ?? ScrollController();
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _c.addListener(_onScroll);
  }

  @override
  void dispose() {
    _c.removeListener(_onScroll);
    _offsetNotifier.dispose();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_c.hasClients) return;
    final o = _c.offset;
    if ((o - _offsetNotifier.value).abs() > 1.0) {
      _offsetNotifier.value = o;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final pad = MediaQuery.paddingOf(context);
    final top = pad.top + kNavBarHeight;
    final back = widget.showBack ?? Navigator.of(context).canPop();
    final hasLarge = widget.largeTitle && widget.header == null;
    final bg = widget.background ?? t.bg;

    return ColoredBox(
      color: bg,
      child: Stack(
        children: [
          if (widget.wash != null)
            ValueListenableBuilder<double>(
              valueListenable: _offsetNotifier,
              builder: (context, offset, _) => Positioned(
                top: -offset,
                left: 0,
                right: 0,
                height: 560,
                child: IgnorePointer(child: _Wash(track: widget.wash!)),
              ),
            ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomScrollView(
                controller: _c,
                slivers: [
                  if (!(widget.headerUnderBar && widget.header != null)) SliverToBoxAdapter(child: SizedBox(height: top)),
                  if (widget.header != null) SliverToBoxAdapter(child: widget.header),
                  if (hasLarge)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                        child: Text(widget.title, style: t.largeTitle),
                      ),
                    ),
                  ...widget.slivers,
                  SliverToBoxAdapter(child: SizedBox(height: pad.bottom + 24)),
                ],
              ),
            ),
          ),
          // Blurred bar background, fading in as content passes under it.
          ValueListenableBuilder<double>(
            valueListenable: _offsetNotifier,
            builder: (context, offset, _) {
              final p = hasLarge
                  ? ((offset - 6) / 30).clamp(0.0, 1.0)
                  : (widget.header != null ? ((offset - 120) / 40).clamp(0.0, 1.0) : 1.0);
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: top,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: p,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: t.reduceTransparency
                                ? ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                                : ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: bg.withValues(alpha: t.reduceTransparency ? 1 : .72),
                                border: Border(bottom: BorderSide(color: t.separator, width: 0.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: pad.top,
                    left: 0,
                    right: 0,
                    height: kNavBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: p,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 64),
                              child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.headline),
                            ),
                          ),
                          Row(
                            children: [
                              if (widget.leading != null)
                                widget.leading!
                              else if (back)
                                GlassCircleButton(
                                  icon: CupertinoIcons.chevron_back,
                                  label: 'Back',
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                              const Spacer(),
                              for (final (i, a) in widget.actions.indexed) ...[if (i > 0) const SizedBox(width: 10), a],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return ValueListenableBuilder<List<Color>>(
      valueListenable: ArtColors.instance.listen(track),
      builder: (context, colors, _) {
        final c = colors.first;
        final a = t.dark ? .6 : .45;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.withValues(alpha: a),
                c.withValues(alpha: a * .4),
                c.withValues(alpha: 0),
              ],
              stops: const [0, .5, 1],
            ),
          ),
        );
      },
    );
  }
}
