import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../audio/player_controller.dart';
import '../../data/lyrics.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/controls.dart';
import '../widgets/menu.dart';
import '../widgets/tappable.dart';

enum _Mode { player, lyrics, queue }

/// The foreground colour for the player: white on the dark backdrop, near-black
/// on the light one.
Color _ink(BuildContext context) => context.tk.dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);

/// The full-screen player: animated artwork-coloured backdrop, large cover,
/// scrubber, transport, volume, and the lyrics / queue views.
class NowPlayingView extends StatefulWidget {
  const NowPlayingView({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<NowPlayingView> createState() => _NowPlayingViewState();
}

class _NowPlayingViewState extends State<NowPlayingView> {
  _Mode _mode = _Mode.player;

  void _toggle(_Mode m) => setState(() => _mode = _mode == m ? _Mode.player : m);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final ink = _ink(context);
    return ListenableBuilder(
      listenable: app.player,
      builder: (context, _) {
        final cur = app.player.current;
        if (cur == null) return const SizedBox.expand();
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Status bar icons follow the theme, so they stay readable on the
          // light backdrop as well as the dark one.
          value: t.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Backdrop(track: cur, playing: app.player.playing),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: t.fastDur,
                          child: switch (_mode) {
                            _Mode.player => _PlayerPane(key: const ValueKey('p'), track: cur, onClose: widget.onClose),
                            _Mode.lyrics => _LyricsPane(key: const ValueKey('l'), track: cur),
                            _Mode.queue => _QueuePane(key: const ValueKey('q'), track: cur),
                          },
                        ),
                      ),
                      _BottomRow(
                        mode: _mode,
                        onLyrics: () => _toggle(_Mode.lyrics),
                        onQueue: () => _toggle(_Mode.queue),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- Backdrop --------------------------------------------------------------

class _Backdrop extends StatefulWidget {
  const _Backdrop({required this.track, required this.playing});
  final Track track;
  final bool playing;

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static Color _deepen(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h
        .withLightness((h.lightness * (1 - amount)).clamp(0.08, 0.55))
        .withSaturation((h.saturation * 1.1).clamp(0, 1))
        .toColor();
  }

  /// A light wash of the artwork colour over white, for the light appearance.
  static Color _pastel(Color c, double amount) => Color.lerp(const Color(0xFFFFFFFF), c, amount)!;

  @override
  Widget build(BuildContext context) {
    final tk = context.tk;
    final reduce = tk.reduceMotion;
    final dark = tk.dark;
    return ValueListenableBuilder<List<Color>>(
      valueListenable: ArtColors.instance.listen(widget.track),
      builder: (context, cs, _) {
        final colors = [for (final c in cs) dark ? _deepen(c, .35) : _pastel(c, .55)];
        Color at(int i) => colors[i % colors.length];
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final a = reduce ? 0.0 : _c.value * 2 * math.pi;
            return LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                Widget blob(Color c, double cx, double cy, double r) => Positioned(
                  left: cx * w - r,
                  top: cy * h - r,
                  width: r * 2,
                  height: r * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [c.withValues(alpha: .95), c.withValues(alpha: 0)]),
                    ),
                  ),
                );
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: dark ? _deepen(at(0), .35) : _pastel(cs.first, .22))),
                    blob(at(1), .2 + .12 * math.sin(a), .22 + .08 * math.cos(a), w * .95),
                    blob(at(2), .85 + .1 * math.cos(a * 1.3), .5 + .1 * math.sin(a * .8), w * .9),
                    blob(at(3), .35 + .15 * math.sin(a * .7), .88 + .05 * math.cos(a), w * 1.0),
                    // Keeps the type legible on any cover (dark appearance only).
                    if (dark) Positioned.fill(child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: .22))),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---- Player pane ---------------------------------------------------------

class _PlayerPane extends StatelessWidget {
  const _PlayerPane({super.key, required this.track, required this.onClose});
  final Track track;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.player;
    final t = context.tk;
    return LayoutBuilder(
      builder: (context, box) {
        const fixed = 330.0; // title, scrubber, transport, volume and gaps
        final art = math.min(box.maxWidth, math.max(150.0, box.maxHeight - fixed)).toDouble();
        return Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedScale(
                  scale: p.playing ? 1 : .86,
                  duration: t.sheetDur,
                  curve: AstraTokens.ease,
                  child: TrackArt(track, size: art, radius: art * .045 + 6, shadow: true),
                ),
              ),
            ),
            _TitleRow(track: track),
            const SizedBox(height: 18),
            const _Scrubber(),
            const SizedBox(height: 14),
            const _Transport(),
            const SizedBox(height: 18),
            const _Volume(),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.track, this.compact = false});
  final Track track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final fav = app.player.isFav(track);
    final ink = _ink(context);
    return Row(
      children: [
        if (compact) ...[TrackArt(track, size: 56), const SizedBox(width: 14)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact ? t.headline : t.title2).copyWith(color: ink),
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact ? t.subhead : t.title3.copyWith(fontWeight: FontWeight.w400)).copyWith(
                  color: ink.withValues(alpha: .62),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoundTranslucent(
          icon: fav ? CupertinoIcons.star_fill : CupertinoIcons.star,
          label: fav ? 'Remove from favorites' : 'Add to favorites',
          onTap: () => app.player.toggleFav(track),
        ),
        const SizedBox(width: 10),
        Builder(
          builder: (c) => _RoundTranslucent(
            icon: CupertinoIcons.ellipsis,
            label: 'More',
            onTap: () => showTrackMenu(c, track, inNowPlaying: true),
          ),
        ),
      ],
    );
  }
}

class _RoundTranslucent extends StatelessWidget {
  const _RoundTranslucent({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return Tappable(
      onTap: onTap,
      label: label,
      press: Press.scale,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withValues(alpha: .14)),
        child: Icon(icon, size: 17, color: ink),
      ),
    );
  }
}

class _Scrubber extends StatefulWidget {
  const _Scrubber();

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).player;
    final t = context.tk;
    final ink = _ink(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: p.position,
      builder: (context, pos, _) {
        final d = p.duration;
        final ms = d.inMilliseconds;
        final f = _drag ?? (ms == 0 ? 0.0 : (pos.inMilliseconds / ms).clamp(0.0, 1.0));
        final shown = _drag == null ? pos : Duration(milliseconds: (f * ms).round());
        final badge = p.current?.qualityBadge;
        return Column(
          children: [
            ScrubBar(
              value: f,
              active: ink.withValues(alpha: .92),
              track: ink.withValues(alpha: .24),
              semanticLabel: 'Seek',
              semanticValue: fmtDur(shown),
              increasedValue: fmtDur(shown + const Duration(seconds: 10)),
              decreasedValue: fmtDur(
                shown - const Duration(seconds: 10) < Duration.zero
                    ? Duration.zero
                    : shown - const Duration(seconds: 10),
              ),
              onIncrease: () => p.seek(pos + const Duration(seconds: 10)),
              onDecrease: () => p.seek(pos - const Duration(seconds: 10)),
              onChanged: (v) => setState(() => _drag = v),
              onChangeEnd: (v) {
                setState(() => _drag = null);
                p.seek(Duration(milliseconds: (v * ms).round()));
              },
            ),
            Row(
              children: [
                Text(
                  fmtDur(shown),
                  style: t.caption1.copyWith(color: ink.withValues(alpha: .6), fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Center(
                    child: badge == null
                        ? null
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badge,
                              style: t.caption2.copyWith(
                                color: ink.withValues(alpha: .85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ),
                Text(
                  '-${fmtDur(d - shown < Duration.zero ? Duration.zero : d - shown)}',
                  style: t.caption1.copyWith(color: ink.withValues(alpha: .6), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport();

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).player;
    // A const child of the player pane is never rebuilt by its parent, so it
    // has to listen itself or the play/pause glyph goes stale.
    return ListenableBuilder(listenable: p, builder: (context, _) => _build(context, p));
  }

  Widget _build(BuildContext context, PlayerController p) {
    final ink = _ink(context);
    Widget btn(IconData i, String label, VoidCallback onTap, double size) => Tappable(
      onTap: onTap,
      label: label,
      press: Press.scale,
      child: SizedBox(
        width: 84,
        height: 76,
        child: Center(
          child: Icon(i, size: size, color: ink),
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        btn(CupertinoIcons.backward_fill, 'Previous', p.prev, 38),
        btn(
          p.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
          p.playing ? 'Pause' : 'Play',
          p.togglePlay,
          52,
        ),
        btn(CupertinoIcons.forward_fill, 'Next', p.next, 38),
      ],
    );
  }
}

class _Volume extends StatelessWidget {
  const _Volume();

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).player;
    final ink = _ink(context);
    return ValueListenableBuilder<double>(
      valueListenable: p.volume,
      builder: (context, vol, _) => Row(
        children: [
          Icon(CupertinoIcons.speaker_fill, size: 15, color: ink.withValues(alpha: .6)),
          const SizedBox(width: 12),
          Expanded(
            child: ScrubBar(
              value: vol,
              active: ink.withValues(alpha: .85),
              track: ink.withValues(alpha: .24),
              semanticLabel: 'Volume',
              semanticValue: '${(vol * 100).round()}%',
              increasedValue: '${((vol + .1).clamp(0.0, 1.0) * 100).round()}%',
              decreasedValue: '${((vol - .1).clamp(0.0, 1.0) * 100).round()}%',
              onChanged: p.setVolume,
              onIncrease: () => p.setVolume(vol + .1),
              onDecrease: () => p.setVolume(vol - .1),
            ),
          ),
          const SizedBox(width: 12),
          Icon(CupertinoIcons.speaker_3_fill, size: 17, color: ink.withValues(alpha: .6)),
        ],
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.mode, required this.onLyrics, required this.onQueue});
  final _Mode mode;
  final VoidCallback onLyrics, onQueue;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.player;
    final ink = _ink(context);
    Widget item(Widget icon, String label, VoidCallback onTap, {bool on = false}) => Tappable(
      onTap: onTap,
      label: label,
      selected: on,
      press: Press.scale,
      child: Container(
        width: 56,
        height: 44,
        decoration: BoxDecoration(
          color: on ? ink.withValues(alpha: .24) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: icon),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        item(
          Icon(
            mode == _Mode.lyrics ? CupertinoIcons.quote_bubble_fill : CupertinoIcons.quote_bubble,
            size: 22,
            color: ink.withValues(alpha: mode == _Mode.lyrics ? 1 : .85),
          ),
          'Lyrics',
          onLyrics,
          on: mode == _Mode.lyrics,
        ),
        Builder(
          builder: (c) => item(
            CustomPaint(size: const Size(24, 24), painter: _AirPlayPainter(ink.withValues(alpha: .85))),
            'Output and speed',
            () => showAstraMenu(c, [
              MenuAction(
                p.outputLabel,
                p.outputIcon == 'headphones' ? CupertinoIcons.headphones : CupertinoIcons.speaker_2_fill,
                () {},
              ),
              for (final s in PlayerController.speeds)
                MenuAction(
                  'Speed ${s == s.roundToDouble() ? s.toStringAsFixed(0) : s}×${s == p.speed ? '  ✓' : ''}',
                  CupertinoIcons.gauge,
                  () => p.setSpeed(s),
                ),
            ]),
          ),
        ),
        item(
          Icon(CupertinoIcons.list_bullet, size: 22, color: ink.withValues(alpha: mode == _Mode.queue ? 1 : .85)),
          'Queue',
          onQueue,
          on: mode == _Mode.queue,
        ),
      ],
    );
  }
}

/// The AirPlay-audio glyph: broadcast rings above a triangle.
class _AirPlayPainter extends CustomPainter {
  _AirPlayPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;
    final c = Offset(s.width / 2, s.height * .42);
    canvas.drawCircle(c, s.width * .12, Paint()..color = color);
    for (final r in [s.width * .27, s.width * .42]) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * .8, math.pi * 1.4, false, stroke);
    }
    final tri = Path()
      ..moveTo(s.width * .5, s.height * .6)
      ..lineTo(s.width * .74, s.height * .93)
      ..lineTo(s.width * .26, s.height * .93)
      ..close();
    canvas.drawPath(tri, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AirPlayPainter old) => old.color != color;
}

// ---- Lyrics ------------------------------------------------------------

class _LyricsPane extends StatefulWidget {
  const _LyricsPane({super.key, required this.track});
  final Track track;

  @override
  State<_LyricsPane> createState() => _LyricsPaneState();
}

class _LyricsPaneState extends State<_LyricsPane> {
  Lyrics? _lyrics;
  bool _loading = true;
  String? _forKey;
  final _c = ScrollController();
  int _active = -1;
  List<GlobalKey> _keys = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(_LyricsPane old) {
    super.didUpdateWidget(old);
    _load();
  }

  Future<void> _load() async {
    if (_forKey == widget.track.key) return;
    _forKey = widget.track.key;
    setState(() {
      _loading = true;
      _lyrics = null;
      _active = -1;
    });
    final l = await loadLyrics(widget.track);
    if (!mounted || _forKey != widget.track.key) return;
    setState(() {
      _lyrics = l;
      _keys = [for (var n = 0; n < (l?.lines.length ?? 0); n++) GlobalKey()];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).player;
    final t = context.tk;
    final ink = _ink(context);
    final l = _lyrics;
    return Column(
      children: [
        const SizedBox(height: 14),
        _TitleRow(track: widget.track, compact: true),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? Center(child: CupertinoActivityIndicator(color: ink))
              : l == null
              ? Center(
                  child: Text('Lyrics Not Available', style: t.title3.copyWith(color: ink.withValues(alpha: .6))),
                )
              : ValueListenableBuilder<Duration>(
                  valueListenable: p.position,
                  builder: (context, pos, _) {
                    final i = l.indexAt(pos);
                    if (i != _active && l.synced) {
                      _active = i;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_c.hasClients || i < 0 || i >= _keys.length) return;
                        final ctx = _keys[i].currentContext;
                        if (ctx == null) return;
                        // Measured, not assumed: wrapped lines have different heights.
                        Scrollable.ensureVisible(ctx, alignment: .22, duration: t.sheetDur, curve: AstraTokens.ease);
                      });
                    }
                    return SingleChildScrollView(
                      controller: _c,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (n, line) in l.lines.indexed)
                            Builder(
                              builder: (context) {
                                final isOn = !l.synced || n == i;
                                return Tappable(
                                  key: _keys[n],
                                  onTap: line.time == null ? null : () => p.seek(line.time!),
                                  press: Press.none,
                                  child: AnimatedOpacity(
                                    duration: t.fastDur,
                                    opacity: isOn ? 1 : .36,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        line.text.isEmpty ? '♪' : line.text,
                                        style: t.title1.copyWith(color: ink, height: 1.25),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---- Queue ---------------------------------------------------------------

class _QueuePane extends StatelessWidget {
  const _QueuePane({super.key, required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.player;
    final t = context.tk;
    final ink = _ink(context);
    return Column(
      children: [
        const SizedBox(height: 14),
        _TitleRow(track: track, compact: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Playing Next', style: t.title3.copyWith(color: ink)),
            ),
            _ModeChip(
              icon: CupertinoIcons.shuffle,
              label: p.shuffle ? 'Shuffle on' : 'Shuffle off',
              on: p.shuffle,
              onTap: p.toggleShuffle,
            ),
            const SizedBox(width: 8),
            _ModeChip(
              icon: p.repeat == Repeat.one ? CupertinoIcons.repeat_1 : CupertinoIcons.repeat,
              label: switch (p.repeat) {
                Repeat.off => 'Repeat off',
                Repeat.all => 'Repeat all',
                Repeat.one => 'Repeat one',
              },
              on: p.repeat != Repeat.off,
              onTap: p.cycleRepeat,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Builder(
            builder: (context) {
              final next = p.upNext;
              if (next.isEmpty) {
                return Center(
                  child: Text('No songs up next', style: t.body.copyWith(color: ink.withValues(alpha: .6))),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: next.length,
                itemBuilder: (context, i) {
                  final (tr, qi) = next[i];
                  return Dismissible(
                    key: ValueKey('q$qi-${tr.key}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => p.removeFromQueue(qi),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: const Color(0xFFFF3B30),
                      child: const Icon(CupertinoIcons.trash, color: Color(0xFFFFFFFF)),
                    ),
                    child: Tappable(
                      onTap: () => p.playAt(qi),
                      press: Press.fill,
                      label: '${tr.title}, ${tr.artist}',
                      child: SizedBox(
                        height: 62,
                        child: Row(
                          children: [
                            TrackArt(tr, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.body.copyWith(color: ink),
                                  ),
                                  Text(
                                    tr.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.subhead.copyWith(color: ink.withValues(alpha: .6)),
                                  ),
                                ],
                              ),
                            ),
                            Text(fmtDur(tr.duration), style: t.subhead.copyWith(color: ink.withValues(alpha: .5))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    final dark = context.tk.dark;
    return Tappable(
      onTap: onTap,
      label: label,
      selected: on,
      press: Press.scale,
      child: Container(
        width: 44,
        height: 36,
        decoration: BoxDecoration(
          color: on ? ink.withValues(alpha: .92) : ink.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        // The selected chip is filled with the ink colour, so its glyph flips.
        child: Icon(icon, size: 17, color: on ? (dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF)) : ink),
      ),
    );
  }
}
