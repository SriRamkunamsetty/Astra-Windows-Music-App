import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/collections.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/controls.dart';
import '../widgets/empty_library.dart';
import '../widgets/menu.dart';
import '../widgets/page.dart';
import '../widgets/rows.dart';
import 'collection_pages.dart';
import 'settings_screen.dart';

void _pushPage(BuildContext context, Widget page) {
  AppScope.of(context).nav.push(CupertinoPageRoute<void>(builder: (_) => page));
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.player, app.playlists]),
      builder: (context, _) {
        final lib = app.library;
        final albums = [...lib.albums]..sort((a, b) => (b.added ?? DateTime(0)).compareTo(a.added ?? DateTime(0)));
        final rows = <(IconData, String, VoidCallback)>[
          (CupertinoIcons.music_note_list, 'Playlists', () => _pushPage(context, const PlaylistsPage())),
          (CupertinoIcons.person_2, 'Artists', () => _pushPage(context, const ArtistsPage())),
          (CupertinoIcons.music_albums, 'Albums', () => _pushPage(context, const AlbumsPage())),
          (CupertinoIcons.music_note, 'Songs', () => _pushPage(context, const SongsPage())),
          (CupertinoIcons.star, 'Favorites', () => openTrackList(context, kFavoritesList)),
          (CupertinoIcons.clock, 'Recently Played', () => openTrackList(context, kRecentlyPlayedList)),
        ];
        return LargeTitlePage(
          title: 'Library',
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
            if (!lib.isEmpty)
              SliverList.list(
                children: [
                  const SizedBox(height: 6),
                  for (final (i, r) in rows.indexed) ...[
                    if (i == 0) const Hairline(indent: 20),
                    NavRow(leading: LibraryGlyph(r.$1), title: r.$2, onTap: r.$3, indent: 20, height: 52),
                    Hairline(indent: i == rows.length - 1 ? 0 : 68),
                  ],
                ],
              ),
            if (albums.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader('Recently Added')),
              _AlbumGrid(albums: albums.take(20).toList()),
            ],
          ],
        );
      },
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums});
  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final cols = (constraints.crossAxisExtent / 180).floor().clamp(2, 8);
        final cell = (constraints.crossAxisExtent - 40 - 16 * (cols - 1)) / cols;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 18,
              crossAxisSpacing: 16,
              mainAxisExtent: artCardHeight(context, cell),
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) => ArtCard(
              track: albums[i].cover,
              title: albums[i].name,
              subtitle: albums[i].artist,
              onTap: () => openAlbum(context, albums[i]),
            ),
          ),
        );
      },
    );
  }
}

// ---- Sub pages ---------------------------------------------------------------

class SongsPage extends StatelessWidget {
  const SongsPage({super.key});

  static const sorts = ['Title', 'Artist', 'Recently Added', 'Duration'];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.settings]),
      builder: (context, _) {
        final sort = app.settings.songSort;
        final all = [...app.library.tracks];
        all.sort(
          (a, b) => switch (sort) {
            'Artist' => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
            'Recently Added' => (b.added ?? DateTime(0)).compareTo(a.added ?? DateTime(0)),
            'Duration' => a.duration.compareTo(b.duration),
            _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          },
        );
        return LargeTitlePage(
          title: 'Songs',
          actions: [
            Builder(
              builder: (c) => GlassCircleButton(
                icon: CupertinoIcons.arrow_up_arrow_down,
                label: 'Sort',
                onTap: () => showAstraMenu(c, [
                  for (final s in sorts)
                    MenuAction(s == sort ? '$s  ✓' : s, switch (s) {
                      'Artist' => CupertinoIcons.person,
                      'Recently Added' => CupertinoIcons.clock,
                      'Duration' => CupertinoIcons.time,
                      _ => CupertinoIcons.textformat,
                    }, () => app.settings.songSort = s),
                ]),
              ),
            ),
          ],
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 14),
                child: PlayShuffleRow(
                  enabled: all.isNotEmpty,
                  onPlay: () => app.player.playList(all, 0, from: 'Songs'),
                  onShuffle: () => app.player.shufflePlay(all, from: 'Songs'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Hairline(indent: 20)),
            SliverList.builder(
              itemCount: all.length,
              itemBuilder: (context, i) => Column(
                children: [
                  SongRow(
                    track: all[i],
                    indent: 20,
                    onTap: () => app.player.playList(all, i, from: 'Songs'),
                    onMore: (c) => showTrackMenu(c, all[i]),
                  ),
                  const Hairline(indent: 86),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  fmtSummary(all.length, all.fold(Duration.zero, (a, x) => a + x.duration)),
                  style: t.footnote.copyWith(color: t.secondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.library,
      builder: (context, _) => LargeTitlePage(
        title: 'Albums',
        slivers: [_AlbumGrid(albums: app.library.albums)],
      ),
    );
  }
}

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.library,
      builder: (context, _) {
        final artists = app.library.artists;
        return LargeTitlePage(
          title: 'Artists',
          slivers: [
            const SliverToBoxAdapter(child: Hairline(indent: 20)),
            SliverList.builder(
              itemCount: artists.length,
              itemBuilder: (context, i) {
                final a = artists[i];
                return Column(
                  children: [
                    NavRow(
                      leading: TrackArt(a.cover, size: 52, circle: true),
                      title: a.name,
                      subtitle: '${a.tracks.length} ${a.tracks.length == 1 ? 'song' : 'songs'}',
                      indent: 20,
                      onTap: () => openArtist(context, a),
                    ),
                    const Hairline(indent: 86),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.playlists, app.player]),
      builder: (context, _) {
        final lists = app.playlists.all;
        Widget cover(List<Color> colors, IconData icon) => Container(
          width: 52,
          height: 52,
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(8)),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: Icon(icon, size: 24, color: const Color(0xFFFFFFFF)),
        );
        Widget smart(TrackListSpec s) => Column(
          children: [
            NavRow(
              leading: cover(s.gradient!, s.icon),
              title: s.title,
              subtitle: '${s.tracks(context).length} songs',
              indent: 20,
              onTap: () => openTrackList(context, s),
            ),
            const Hairline(indent: 86),
          ],
        );
        return LargeTitlePage(
          title: 'Playlists',
          actions: [
            GlassCircleButton(
              icon: CupertinoIcons.plus,
              label: 'New Playlist',
              onTap: () => promptNewPlaylist(context),
            ),
          ],
          slivers: [
            const SliverToBoxAdapter(child: Hairline(indent: 20)),
            SliverList.list(
              children: [
                smart(kFavoritesList),
                smart(kRecentlyPlayedList),
                smart(kMostPlayedList),
                smart(kRecentlyAddedList),
                for (final p in lists)
                  Column(
                    children: [
                      NavRow(
                        leading: () {
                          final first = [for (final k in p.keys) ?app.library.byKey(k)].firstOrNull;
                          return first == null
                              ? cover([t.fillStrong, t.fillStrong], CupertinoIcons.music_note_list)
                              : TrackArt(first, size: 52, radius: 8);
                        }(),
                        title: p.name,
                        subtitle: '${p.keys.length} ${p.keys.length == 1 ? 'song' : 'songs'}',
                        indent: 20,
                        onTap: () => openTrackList(context, playlistSpec(p)),
                      ),
                      const Hairline(indent: 86),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
