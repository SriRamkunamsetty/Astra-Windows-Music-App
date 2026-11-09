import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../audio/player_controller.dart';
import '../theme/tokens.dart';
import 'actions.dart';
import 'now_playing/now_playing.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/studio_screen.dart';
import 'sheets/job_sheet.dart';
import 'widgets/artwork.dart';
import 'widgets/controls.dart';
import 'widgets/glass.dart';
import 'widgets/tappable.dart';

const double _tabBarH = 62;
const double _miniH = 58;
const double _gap = 8;
const double _sideMargin = 16;
const double _desktopSidebarW = 240;
const double _desktopPlayerH = 84;

/// Responsive app shell: adapts between a sleek desktop layout (left sidebar +
/// bottom docked player bar) and compact mobile portrait layout.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  late final AnimationController _np = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  NavState? _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = AppScope.of(context).nav;
    if (_nav != nav) {
      _nav?.removeListener(_onNav);
      _nav = nav..addListener(_onNav);
    }
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNav);
    _np.dispose();
    super.dispose();
  }

  void _onNav() {
    final t = context.tk;
    final open = _nav!.nowPlaying;
    if (t.reduceMotion) {
      _np.value = open ? 1 : 0;
    } else {
      _np.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 280));
    }
  }

  void _drag(DragUpdateDetails d, double height) {
    _np.value -= (d.primaryDelta ?? 0) / height;
  }

  void _dragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = v < -600 ? true : (v > 600 ? false : _np.value > .5);
    final changed = _nav!.nowPlaying != open;
    _nav!.setNowPlaying(open);
    if (!changed) {
      _np.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 220));
    }
  }

  void _back() {
    final app = AppScope.of(context);
    final nav = app.nav;
    if (app.jobs.job != null) {
      app.jobs.dismiss();
    } else if (nav.nowPlaying) {
      nav.setNowPlaying(false);
    } else if (nav.navigator?.canPop() ?? false) {
      nav.navigator!.pop();
    } else if (nav.tab != AppTab.home) {
      nav.go(AppTab.home);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final mq = MediaQuery.of(context);
    final isDesktop = mq.size.width >= 720;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([app.nav, app.player]),
        builder: (context, _) {
          final hasTrack = app.player.current != null;
          final h = mq.size.height;

          return ColoredBox(
            color: t.bg,
            child: AnimatedBuilder(
              animation: _np,
              builder: (context, _) {
                final v = _np.value;
                return Stack(
                  children: [
                    // Main layout
                    Positioned.fill(
                      child: isDesktop
                          ? _buildDesktopLayout(context, app, t, mq, hasTrack)
                          : _buildMobileLayout(context, app, t, mq, hasTrack, v, h),
                    ),

                    // Fullscreen / Modal Now Playing
                    if (hasTrack && v > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: v < 0.05,
                          child: Opacity(
                            opacity: v.clamp(0.0, 1.0),
                            child: isDesktop
                                ? _buildDesktopNowPlayingModal(context, app, t)
                                : _buildMobileNowPlayingSheet(context, app, t, v, h),
                          ),
                        ),
                      ),

                    const JobSheet(),
                    const _Toast(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppScope app,
    AstraTokens t,
    MediaQueryData mq,
    bool hasTrack,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left Desktop Navigation Sidebar
              const _DesktopSidebar(),
              // Vertical hairline separator
              Container(width: 1, color: t.separator.withValues(alpha: .2)),
              // Primary Tab Content
              Expanded(
                child: MediaQuery(
                  data: mq.copyWith(
                    padding: mq.padding.copyWith(bottom: hasTrack ? _desktopPlayerH : 0),
                  ),
                  child: IndexedStack(
                    index: app.nav.tab.index,
                    children: [for (final tab in AppTab.values) _TabNavigator(tab: tab)],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Persistent Bottom Desktop Player Dock
        const _DesktopPlayerBar(),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppScope app,
    AstraTokens t,
    MediaQueryData mq,
    bool hasTrack,
    double v,
    double h,
  ) {
    final bottomGap = math.max(mq.padding.bottom, 12.0);
    final accessory = bottomGap + _tabBarH + (hasTrack ? _miniH + _gap : 0) + _gap;

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: 1 - .05 * v,
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(28 * v),
              child: MediaQuery(
                data: mq.copyWith(padding: mq.padding.copyWith(bottom: mq.padding.bottom + accessory)),
                child: IndexedStack(
                  index: app.nav.tab.index,
                  children: [for (final tab in AppTab.values) _TabNavigator(tab: tab)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: _sideMargin,
          right: _sideMargin,
          bottom: bottomGap,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Opacity(
                opacity: (1 - v * 1.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, v * (accessory + 20)),
                  child: _Accessory(showMini: hasTrack, onDrag: (d) => _drag(d, h), onDragEnd: _dragEnd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNowPlayingModal(BuildContext context, AppScope app, AstraTokens t) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => app.nav.setNowPlaying(false),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.bg,
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: Stack(
                    children: [
                      NowPlayingView(onClose: () => app.nav.setNowPlaying(false)),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GlassCircleButton(
                          icon: CupertinoIcons.xmark,
                          label: 'Close',
                          iconSize: 16,
                          onTap: () => app.nav.setNowPlaying(false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNowPlayingSheet(
    BuildContext context,
    AppScope app,
    AstraTokens t,
    double v,
    double h,
  ) {
    return Transform.translate(
      offset: Offset(0, (1 - v) * h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => _drag(d, h),
        onVerticalDragEnd: _dragEnd,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32 * (1 - v))),
          child: ColoredBox(
            color: t.bg,
            child: NowPlayingView(onClose: () => app.nav.setNowPlaying(false)),
          ),
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.tab});
  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Navigator(
      key: app.nav.navigators[tab],
      onGenerateRoute: (settings) => CupertinoPageRoute<void>(
        settings: settings,
        builder: (_) => switch (tab) {
          AppTab.home => const HomeScreen(),
          AppTab.library => const LibraryScreen(),
          AppTab.studio => const StudioScreen(),
          AppTab.search => const SearchScreen(),
        },
      ),
    );
  }
}

// ---- Desktop Sidebar --------------------------------------------------------

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.nav, app.player, app.library]),
      builder: (context, _) {
        final t = context.tk;
        final sel = app.nav.tab;
        final lib = app.library;

        void go(AppTab tab) {
          app.nav.go(tab);
        }

        return SizedBox(
          width: _desktopSidebarW,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.dark ? const Color(0xFF141416) : const Color(0xFFF7F7F9),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [t.accent, t.accent.withValues(alpha: .6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: t.accent.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(CupertinoIcons.music_note_2, size: 18, color: CupertinoColors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Astra Music',
                        style: t.headline.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Main Nav Section
                _SidebarHeader(title: 'MENU', t: t),
                const SizedBox(height: 6),
                _SidebarItem(
                  icon: CupertinoIcons.house_fill,
                  label: 'Home',
                  selected: sel == AppTab.home,
                  onTap: () => go(AppTab.home),
                  t: t,
                ),
                _SidebarItem(
                  icon: CupertinoIcons.music_albums_fill,
                  label: 'Library',
                  selected: sel == AppTab.library,
                  onTap: () => go(AppTab.library),
                  t: t,
                ),
                _SidebarItem(
                  icon: CupertinoIcons.waveform,
                  label: 'Audio Studio',
                  selected: sel == AppTab.studio,
                  onTap: () => go(AppTab.studio),
                  t: t,
                ),
                _SidebarItem(
                  icon: CupertinoIcons.search,
                  label: 'Search',
                  selected: sel == AppTab.search,
                  onTap: () => go(AppTab.search),
                  t: t,
                ),

                const SizedBox(height: 20),
                _SidebarHeader(title: 'MY MUSIC', t: t),
                const SizedBox(height: 6),
                _SidebarItem(
                  icon: CupertinoIcons.heart_fill,
                  label: 'Favorites',
                  selected: false,
                  badge: '${app.player.favorites.length}',
                  onTap: () {
                    go(AppTab.library);
                    openTrackList(context, kFavoritesList);
                  },
                  t: t,
                ),
                _SidebarItem(
                  icon: CupertinoIcons.clock_fill,
                  label: 'Recently Played',
                  selected: false,
                  onTap: () {
                    go(AppTab.library);
                    openTrackList(context, kRecentlyPlayedList);
                  },
                  t: t,
                ),
                _SidebarItem(
                  icon: CupertinoIcons.folder_fill,
                  label: 'Local Files',
                  selected: false,
                  badge: '${lib.tracks.length}',
                  onTap: () {
                    go(AppTab.library);
                    app.nav.push(CupertinoPageRoute<void>(builder: (_) => const SongsPage()));
                  },
                  t: t,
                ),

                const Spacer(),

                // Bottom Settings / Preferences
                Container(height: 1, color: t.separator.withValues(alpha: .15)),
                const SizedBox(height: 10),
                Tappable(
                  onTap: () => showSettingsSheet(context),
                  label: 'Settings',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: t.dark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.gear_alt_fill, size: 18, color: t.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Settings', style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.title, required this.t});
  final String title;
  final AstraTokens t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 2),
      child: Text(
        title,
        style: t.caption1.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: t.secondary.withValues(alpha: .5),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.t,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AstraTokens t;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final activeBg = t.accent.withValues(alpha: t.dark ? .22 : .14);
    final activeColor = t.accent;
    final inactiveColor = t.label.withValues(alpha: .85);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tappable(
        onTap: onTap,
        label: label,
        selected: selected,
        press: Press.none,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? activeBg : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? activeColor : inactiveColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  style: t.body.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? t.accent : (t.dark ? const Color(0x33FFFFFF) : const Color(0x1F000000)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: t.caption2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: selected ? CupertinoColors.white : t.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Desktop Bottom Player Dock ---------------------------------------------

class _DesktopPlayerBar extends StatelessWidget {
  const _DesktopPlayerBar();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.player,
      builder: (context, _) {
        final t = context.tk;
        final p = app.player;
        final cur = p.current;

        return RepaintBoundary(
          child: Container(
            height: _desktopPlayerH,
            decoration: BoxDecoration(
              color: t.dark ? const Color(0xFF1B1B1E) : const Color(0xFFFFFFFF),
              border: Border(top: BorderSide(color: t.separator.withValues(alpha: .25), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: t.dark ? .45 : .08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: cur == null
                ? _buildIdleBar(context, app, t)
                : _buildActiveBar(context, app, t, p, cur),
          ),
        );
      },
    );
  }

  Widget _buildIdleBar(BuildContext context, AppScope app, AstraTokens t) {
    final hasTracks = app.library.tracks.isNotEmpty;
    return Row(
      children: [
        Icon(CupertinoIcons.music_note, size: 24, color: t.secondary),
        const SizedBox(width: 12),
        Text(
          hasTracks ? 'Ready to play — pick a song from your library' : 'No music loaded yet',
          style: t.subhead.copyWith(color: t.secondary),
        ),
        const Spacer(),
        if (hasTracks)
          Tappable(
            onTap: () => app.player.shufflePlay(app.library.tracks, from: 'Shuffle All'),
            label: 'Shuffle All',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.shuffle, size: 16, color: CupertinoColors.white),
                  const SizedBox(width: 6),
                  Text('Shuffle All', style: t.subhead.copyWith(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveBar(
    BuildContext context,
    AppScope app,
    AstraTokens t,
    PlayerController p,
    dynamic cur,
  ) {
    final fav = p.isFav(cur);

    return Row(
      children: [
        // Left Column: Artwork + Title + Artist + Heart (~260px)
        SizedBox(
          width: 260,
          child: Row(
            children: [
              Tappable(
                onTap: () => app.nav.setNowPlaying(true),
                label: 'Open Now Playing',
                child: TrackArt(cur, size: 52, radius: 8, shadow: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cur.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.headline.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cur.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption1.copyWith(color: t.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tappable(
                onTap: () => p.toggleFav(cur),
                label: fav ? 'Favorite' : 'Unfavorite',
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    fav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    size: 20,
                    color: fav ? t.accent : t.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Center Column: Transport Controls + Scrubber
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Transport Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TransportIcon(
                        icon: CupertinoIcons.shuffle,
                        active: p.shuffle,
                        onTap: p.toggleShuffle,
                        t: t,
                        size: 18,
                      ),
                      const SizedBox(width: 18),
                      _TransportIcon(
                        icon: CupertinoIcons.backward_fill,
                        onTap: p.prev,
                        t: t,
                        size: 20,
                      ),
                      const SizedBox(width: 18),
                      // Play / Pause Circle
                      Tappable(
                        onTap: p.togglePlay,
                        label: p.playing ? 'Pause' : 'Play',
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.accent,
                            boxShadow: [
                              BoxShadow(color: t.accent.withValues(alpha: .4), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            p.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                            size: 19,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      _TransportIcon(
                        icon: CupertinoIcons.forward_fill,
                        onTap: p.next,
                        t: t,
                        size: 20,
                      ),
                      const SizedBox(width: 18),
                      _TransportIcon(
                        icon: p.repeat == Repeat.one
                            ? CupertinoIcons.repeat_1
                            : CupertinoIcons.repeat,
                        active: p.repeat != Repeat.off,
                        onTap: p.cycleRepeat,
                        t: t,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Scrubber Bar
                  ValueListenableBuilder<Duration>(
                    valueListenable: p.position,
                    builder: (context, pos, _) {
                      final d = p.duration;
                      final ms = d.inMilliseconds;
                      final f = ms == 0 ? 0.0 : (pos.inMilliseconds / ms).clamp(0.0, 1.0);

                      return Row(
                        children: [
                          Text(_fmtDuration(pos), style: t.caption2.copyWith(color: t.secondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DesktopScrubberSlider(
                              value: f,
                              onChanged: (val) {
                                p.seek(Duration(milliseconds: (val * ms).round()));
                              },
                              accent: t.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_fmtDuration(d), style: t.caption2.copyWith(color: t.secondary)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Column: Speed + Volume Slider + Fullscreen
        SizedBox(
          width: 240,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Speed Pill
              Tappable(
                onTap: p.cycleSpeed,
                label: 'Speed ${p.speed}x',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: t.dark ? const Color(0x2EFFFFFF) : const Color(0x1F000000),
                  ),
                  child: Text(
                    '${p.speed}x',
                    style: t.caption1.copyWith(fontWeight: FontWeight.bold, color: t.label),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Volume Icon & Slider
              ValueListenableBuilder<double>(
                valueListenable: p.volume,
                builder: (context, vol, _) {
                  final isMute = vol <= 0.01;
                  return Row(
                    children: [
                      Tappable(
                        onTap: () => p.setVolume(isMute ? 0.7 : 0.0),
                        label: isMute ? 'Unmute' : 'Mute',
                        child: Icon(
                          isMute
                              ? CupertinoIcons.volume_off
                              : (vol < 0.5 ? CupertinoIcons.volume_down : CupertinoIcons.volume_up),
                          size: 19,
                          color: t.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 80,
                        child: _DesktopScrubberSlider(
                          value: vol,
                          onChanged: p.setVolume,
                          accent: t.accent,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 14),

              // Expand to Fullscreen Now Playing
              Tappable(
                onTap: () => app.nav.setNowPlaying(true),
                label: 'Expand Now Playing',
                child: Icon(CupertinoIcons.fullscreen, size: 20, color: t.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _TransportIcon extends StatelessWidget {
  const _TransportIcon({
    required this.icon,
    required this.onTap,
    required this.t,
    this.active = false,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AstraTokens t;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      label: 'Control',
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: size,
          color: active ? t.accent : t.label.withValues(alpha: .85),
        ),
      ),
    );
  }
}

class _DesktopScrubberSlider extends StatelessWidget {
  const _DesktopScrubberSlider({
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(d.globalPosition);
        final fraction = (local.dx / box.size.width).clamp(0.0, 1.0);
        onChanged(fraction);
      },
      onTapDown: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(d.globalPosition);
        final fraction = (local.dx / box.size.width).clamp(0.0, 1.0);
        onChanged(fraction);
      },
      child: SizedBox(
        height: 20,
        child: Center(
          child: Stack(
            children: [
              // Track Background
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0x33787880),
                ),
              ),
              // Track Progress
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Compact Mobile Accessory & TabBar ---------------------------------------

class _Accessory extends StatelessWidget {
  const _Accessory({required this.showMini, required this.onDrag, required this.onDragEnd});
  final bool showMini;
  final ValueChanged<DragUpdateDetails> onDrag;
  final ValueChanged<DragEndDetails> onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMini) ...[
          GestureDetector(onVerticalDragUpdate: onDrag, onVerticalDragEnd: onDragEnd, child: const _MiniPlayer()),
          const SizedBox(height: _gap),
        ],
        const _TabBar(),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(listenable: app.player, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final p = app.player;
    final cur = p.current;
    if (cur == null) return const SizedBox.shrink();
    return Tappable(
      onTap: () => app.nav.setNowPlaying(true),
      press: Press.scale,
      label: 'Now playing: ${cur.title}. Double tap to open the player.',
      child: SizedBox(
        height: _miniH,
        child: Glass(
          capsule: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
            child: Row(
              children: [
                TrackArt(cur, size: 42, radius: 9),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cur.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.subhead.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Tappable(
                  onTap: p.togglePlay,
                  label: p.playing ? 'Pause' : 'Play',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      p.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      size: 24,
                      color: t.label,
                    ),
                  ),
                ),
                Tappable(
                  onTap: p.next,
                  label: 'Next',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(CupertinoIcons.forward_fill, size: 24, color: t.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  static const _items = [
    (AppTab.home, 'Home', CupertinoIcons.house_fill),
    (AppTab.library, 'Library', CupertinoIcons.music_albums_fill),
    (AppTab.studio, 'Studio', CupertinoIcons.waveform),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(listenable: app.nav, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final sel = app.nav.tab;
    void go(AppTab tab) {
      app.player.haptic();
      app.nav.go(tab);
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _tabBarH,
            child: Glass(
              capsule: true,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - 8) / _items.length;
                  final idx = _items.indexWhere((e) => e.$1 == sel);
                  return Stack(
                    children: [
                      if (idx >= 0)
                        AnimatedPositioned(
                          duration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: 4 + idx * w,
                          top: 4,
                          bottom: 4,
                          width: w,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.dark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          for (final (tab, label, icon) in _items)
                            Expanded(
                              child: Tappable(
                                onTap: () => go(tab),
                                label: label,
                                selected: tab == sel,
                                press: Press.none,
                                child: _TabItem(icon: icon, label: label, on: tab == sel),
                              ),
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        Tappable(
          onTap: () => go(AppTab.search),
          label: 'Search',
          selected: sel == AppTab.search,
          press: Press.scale,
          child: SizedBox(
            width: _tabBarH,
            height: _tabBarH,
            child: Glass(
              capsule: true,
              child: Center(
                child: Icon(CupertinoIcons.search, size: 25, color: sel == AppTab.search ? t.accent : t.label),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.on});
  final IconData icon;
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final color = on ? t.accent : t.label.withValues(alpha: .62);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 3),
        Text(label, maxLines: 1, style: t.tabLabel.copyWith(color: color)),
      ],
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast();

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  String? _msg;
  ValueNotifier<String?>? _src;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final src = AppScope.of(context).player.toast;
    if (_src != src) {
      _src?.removeListener(_onMsg);
      _src = src..addListener(_onMsg);
    }
  }

  @override
  void dispose() {
    _src?.removeListener(_onMsg);
    super.dispose();
  }

  void _onMsg() {
    final m = _src!.value;
    if (m == null) return;
    setState(() => _msg = m);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      if (_src!.value == m) _src!.value = null;
      if (_msg == m) setState(() => _msg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final top = MediaQuery.paddingOf(context).top + 10;
    return Positioned(
      top: top,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _msg == null ? const Offset(0, -1.5) : Offset.zero,
          duration: t.fastDur,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _msg == null ? 0 : 1,
            duration: t.fastDur,
            child: Center(
              child: Glass(
                capsule: true,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Text(_msg ?? '', style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
