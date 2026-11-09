import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/collections.dart';
import '../../data/library_repository.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../actions.dart';
import '../widgets/controls.dart';
import '../widgets/empty_library.dart';
import '../widgets/page.dart';
import '../widgets/rows.dart';
import '../widgets/tappable.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.player, app.playlists]),
      builder: (context, _) {
        final lib = app.library;
        final p = app.player;

        // Recently played, collapsed to albums.
        final seen = <String>{};
        final recentAlbums = <Album>[];
        for (final k in p.recentKeys) {
          final t = lib.byKey(k);
          if (t == null) continue;
          final a = lib.albumOf(t);
          if (a != null && seen.add(a.id)) recentAlbums.add(a);
          if (recentAlbums.length >= 12) break;
        }
        final added = [...lib.albums]..sort((a, b) => (b.added ?? DateTime(0)).compareTo(a.added ?? DateTime(0)));
        final mixes = _mixes(context, lib, p.favorites, p.playCounts);
        final recentTracks = lib.tracks.take(12).toList();

        return LargeTitlePage(
          title: 'Home',
          showBack: false,
          actions: [
            GlassCircleButton(
              icon: CupertinoIcons.person_crop_circle,
              label: 'Settings',
              iconSize: 22,
              onTap: () => showSettingsSheet(context),
            ),
          ],
          slivers: [
            if (lib.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 0), child: EmptyLibrary()),
              ),

            // Top Quick Hero Shelf
            if (lib.tracks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth >= 600;
                      return isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: _QuickHeroCard(
                                    title: 'Shuffle All',
                                    subtitle: '${lib.tracks.length} songs in library',
                                    icon: CupertinoIcons.shuffle,
                                    colors: const [Color(0xFFFF9500), Color(0xFFFF5A6E)],
                                    onTap: () => p.shufflePlay(lib.tracks, from: 'Shuffle All'),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _QuickHeroCard(
                                    title: 'Favorites',
                                    subtitle: '${p.favorites.length} starred songs',
                                    icon: CupertinoIcons.heart_fill,
                                    colors: const [Color(0xFFFF2D55), Color(0xFFAF52DE)],
                                    onTap: () => openTrackList(context, kFavoritesList),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _QuickHeroCard(
                                    title: 'Audio Studio',
                                    subtitle: 'Cutter, converter & merger',
                                    icon: CupertinoIcons.waveform,
                                    colors: const [Color(0xFF34C759), Color(0xFF007AFF)],
                                    onTap: () => app.nav.go(AppTab.studio),
                                  ),
                                ),
                              ],
                            )
                          : _QuickHeroCard(
                              title: 'Shuffle All Songs',
                              subtitle: '${lib.tracks.length} tracks ready to play',
                              icon: CupertinoIcons.shuffle,
                              colors: const [Color(0xFFFF9500), Color(0xFFFF5A6E)],
                              onTap: () => p.shufflePlay(lib.tracks, from: 'Shuffle All'),
                            );
                    },
                  ),
                ),
              ),

            if (mixes.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Made for You')),
              _carousel(
                height: artCardHeight(context, 168),
                count: mixes.length,
                item: (i) => _MixCard(mix: mixes[i], width: 168),
              ),
            ],

            if (recentAlbums.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Recently Played')),
              _carousel(
                height: artCardHeight(context, 168),
                count: recentAlbums.length,
                item: (i) => ArtCard(
                  width: 168,
                  track: recentAlbums[i].cover,
                  title: recentAlbums[i].name,
                  subtitle: recentAlbums[i].artist,
                  onTap: () => openAlbum(context, recentAlbums[i]),
                ),
              ),
            ],

            // Quick Songs List
            if (recentTracks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Songs in Library', onSeeAll: () => openTrackList(context, kRecentlyAddedList)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: recentTracks.length,
                  itemBuilder: (context, i) {
                    final t = recentTracks[i];
                    return Column(
                      children: [
                        SongRow(
                          track: t,
                          onTap: () => p.playList(recentTracks, i, from: 'Library Songs'),
                          onMore: (c) => showTrackMenu(c, t),
                        ),
                        if (i < recentTracks.length - 1) const Hairline(indent: 68),
                      ],
                    );
                  },
                ),
              ),
            ],

            if (added.isNotEmpty && added.length > 1) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Recently Added Albums', onSeeAll: () => openTrackList(context, kRecentlyAddedList)),
              ),
              _carousel(
                height: artCardHeight(context, 168),
                count: added.length.clamp(0, 14),
                item: (i) => ArtCard(
                  width: 168,
                  track: added[i].cover,
                  title: added[i].name,
                  subtitle: added[i].artist,
                  onTap: () => openAlbum(context, added[i]),
                ),
              ),
            ],

            if (lib.artists.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Artists')),
              _carousel(
                height: artCardHeight(context, 134, lines: 1),
                count: lib.artists.length.clamp(0, 16),
                item: (i) => ArtCard(
                  width: 134,
                  circle: true,
                  track: lib.artists[i].cover,
                  title: lib.artists[i].name,
                  subtitle: '',
                  onTap: () => openArtist(context, lib.artists[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _carousel({required double height, required int count, required Widget Function(int) item}) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) => item(i),
        ),
      ),
    );
  }

  List<_Mix> _mixes(BuildContext context, LibraryRepository lib, Set<String> favs, Map<String, int> plays) {
    final all = lib.tracks;
    if (all.isEmpty) return const [];
    final favTracks = [
      for (final t in all)
        if (favs.contains(t.key)) t,
    ];
    final most = [...all.where((t) => (plays[t.key] ?? 0) > 0)]
      ..sort((a, b) => (plays[b.key] ?? 0).compareTo(plays[a.key] ?? 0));
    final fresh = [...all]..sort((a, b) => (b.added ?? DateTime(0)).compareTo(a.added ?? DateTime(0)));

    return [
      _Mix('Shuffle All', '${all.length} songs', all, const [Color(0xFFFF9500), Color(0xFFFF5A6E)], true),
      _Mix('New Music Mix', 'Recently added', fresh.take(25).toList(), const [
        Color(0xFFA18CD1),
        Color(0xFF5B3FC0),
      ], false),
      if (favTracks.isNotEmpty)
        _Mix('Favorites Mix', '${favTracks.length} songs', favTracks, const [
          Color(0xFFFF5E7E),
          Color(0xFFC2185B),
        ], false)
      else
        _Mix('Discovery Mix', 'Explore library', fresh.reversed.take(25).toList(), const [
          Color(0xFFFF5E7E),
          Color(0xFFC2185B),
        ], true),
      if (most.length >= 2)
        _Mix('Heavy Rotation', 'Most played', most.take(25).toList(), const [
          Color(0xFF56CCF2),
          Color(0xFF2F6FED),
        ], false)
      else
        _Mix('Chill Rotation', '${all.length.clamp(0, 30)} tracks', all.take(30).toList(), const [
          Color(0xFF56CCF2),
          Color(0xFF2F6FED),
        ], true),
    ];
  }
}

class _QuickHeroCard extends StatelessWidget {
  const _QuickHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      label: title,
      press: Press.scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: t.dark ? .35 : .22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.white.withValues(alpha: .24),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.headline.copyWith(color: CupertinoColors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption1.copyWith(color: CupertinoColors.white.withValues(alpha: .85)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.white.withValues(alpha: .28),
              ),
              child: const Icon(CupertinoIcons.play_fill, size: 16, color: CupertinoColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  const _MixCard({required this.mix, required this.width});
  final _Mix mix;
  final double width;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    return Tappable(
      press: Press.scale,
      label: '${mix.title}, ${mix.subtitle}',
      onTap: () {
        if (mix.shuffle) {
          app.player.shufflePlay(mix.tracks, from: mix.title);
        } else {
          app.player.playList(mix.tracks, 0, from: mix.title);
        }
      },
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(14)),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: mix.colors),
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: t.dark ? .35 : .16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Text(mix.title, style: t.title3.copyWith(color: const Color(0xFFFFFFFF), height: 1.1)),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFFFF).withValues(alpha: .28),
                        ),
                        child: Icon(
                          mix.shuffle ? CupertinoIcons.shuffle : CupertinoIcons.play_fill,
                          size: 17,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(mix.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.headline),
            Text(mix.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.subhead.copyWith(color: t.secondary)),
          ],
        ),
      ),
    );
  }
}

class _Mix {
  const _Mix(this.title, this.subtitle, this.tracks, this.colors, this.shuffle);
  final String title, subtitle;
  final List<Track> tracks;
  final List<Color> colors;
  final bool shuffle;
}
