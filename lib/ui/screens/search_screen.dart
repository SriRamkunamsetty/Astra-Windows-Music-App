import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/page.dart';
import '../widgets/rows.dart';
import '../widgets/tappable.dart';
import 'library_screen.dart';

/// Search across the library. As on iOS 26, the field floats at the bottom,
/// above the tab bar, and moves up with the keyboard.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final mq = MediaQuery.of(context);
    final isDesktop = mq.size.width >= 720;
    final q = _c.text.trim().toLowerCase();
    final keyboard = mq.viewInsets.bottom;
    final fieldBottom = math.max(keyboard, mq.padding.bottom) + 8;

    Widget searchField() => Glass(
      capsule: true,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, size: 19, color: t.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoTextField(
                  controller: _c,
                  focusNode: _focus,
                  placeholder: 'Search songs, artists, albums...',
                  placeholderStyle: t.body.copyWith(color: t.secondary),
                  style: t.body,
                  cursorColor: t.accent,
                  decoration: null,
                  padding: EdgeInsets.zero,
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (_c.text.isNotEmpty)
                Tappable(
                  onTap: _c.clear,
                  label: 'Clear search',
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 19, color: t.tertiary),
                ),
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([app.library, app.player]),
          builder: (context, _) {
            return LargeTitlePage(
              title: 'Search',
              showBack: false,
              slivers: [
                if (isDesktop)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: searchField(),
                        ),
                      ),
                    ),
                  ),
                ...(q.isEmpty ? _browse(context) : _results(context, q)),
              ],
            );
          },
        ),
        if (!isDesktop)
          Positioned(
            left: 16,
            right: 16,
            bottom: fieldBottom,
            child: searchField(),
          ),
      ],
    );
  }

  List<Widget> _browse(BuildContext context) {
    final tiles = <(String, IconData, List<Color>, VoidCallback)>[
      (
        'Songs',
        CupertinoIcons.music_note,
        const [Color(0xFFFF5E7E), Color(0xFFC2185B)],
        () => _push(const SongsPage()),
      ),
      (
        'Albums',
        CupertinoIcons.music_albums_fill,
        const [Color(0xFFFFB347), Color(0xFFE5532D)],
        () => _push(const AlbumsPage()),
      ),
      (
        'Artists',
        CupertinoIcons.person_2_fill,
        const [Color(0xFF56CCF2), Color(0xFF2F6FED)],
        () => _push(const ArtistsPage()),
      ),
      (
        'Playlists',
        CupertinoIcons.music_note_list,
        const [Color(0xFFA18CD1), Color(0xFF5B3FC0)],
        () => _push(const PlaylistsPage()),
      ),
      (
        'Favorites',
        CupertinoIcons.star_fill,
        const [Color(0xFF7BE0AD), Color(0xFF1E8E5A)],
        () => openTrackList(context, kFavoritesList),
      ),
      (
        'Recently Added',
        CupertinoIcons.sparkles,
        const [Color(0xFF434343), Color(0xFF0F0F10)],
        () => openTrackList(context, kRecentlyAddedList),
      ),
    ];
    return [
      const SliverToBoxAdapter(child: SectionHeader('Browse Categories', padding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final cols = (constraints.crossAxisExtent / 220).floor().clamp(2, 6);
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.7,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, i) {
                final (title, icon, colors, onTap) = tiles[i];
                return Tappable(
                  onTap: onTap,
                  press: Press.scale,
                  label: title,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                    ),
                    child: Stack(
                      children: [
                        Text(title, style: context.tk.headline.copyWith(color: const Color(0xFFFFFFFF))),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Transform.rotate(
                            angle: .35,
                            child: Icon(icon, size: 52, color: const Color(0xFFFFFFFF).withValues(alpha: .35)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 90)),
    ];
  }

  void _push(Widget page) {
    AppScope.of(context).nav.push(CupertinoPageRoute<void>(builder: (_) => page));
  }

  List<Widget> _results(BuildContext context, String q) {
    final app = AppScope.of(context);
    final t = context.tk;
    bool hit(String s) => s.toLowerCase().contains(q);
    final songs = <Track>[
      for (final x in app.library.tracks)
        if (hit(x.title) || hit(x.artist) || hit(x.album)) x,
    ];
    final albums = [
      for (final a in app.library.albums)
        if (hit(a.name) || hit(a.artist)) a,
    ];
    final artists = [
      for (final a in app.library.artists)
        if (hit(a.name)) a,
    ];
    if (songs.isEmpty && albums.isEmpty && artists.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
            child: Column(
              children: [
                Text('No Results', style: t.title3),
                const SizedBox(height: 6),
                Text(
                  'Try a different spelling or search for something else.',
                  textAlign: TextAlign.center,
                  style: t.subhead.copyWith(color: t.secondary),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      if (artists.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Artists', padding: EdgeInsets.fromLTRB(20, 14, 20, 6))),
        SliverList.builder(
          itemCount: math.min(artists.length, 3),
          itemBuilder: (context, i) => Column(
            children: [
              NavRow(
                leading: TrackArt(artists[i].cover, size: 52, circle: true),
                title: artists[i].name,
                subtitle: 'Artist',
                indent: 20,
                onTap: () => openArtist(context, artists[i]),
              ),
              const Hairline(indent: 86),
            ],
          ),
        ),
      ],
      if (albums.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Albums', padding: EdgeInsets.fromLTRB(20, 18, 20, 6))),
        SliverList.builder(
          itemCount: math.min(albums.length, 4),
          itemBuilder: (context, i) => Column(
            children: [
              NavRow(
                leading: TrackArt(albums[i].cover, size: 52),
                title: albums[i].name,
                subtitle: 'Album · ${albums[i].artist}',
                indent: 20,
                onTap: () => openAlbum(context, albums[i]),
              ),
              const Hairline(indent: 86),
            ],
          ),
        ),
      ],
      if (songs.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Songs', padding: EdgeInsets.fromLTRB(20, 18, 20, 6))),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, i) => Column(
            children: [
              SongRow(
                track: songs[i],
                indent: 20,
                subtitle: '${songs[i].artist} · ${songs[i].album}',
                onTap: () => app.player.playList(songs, i, from: 'Search'),
                onMore: (c) => showTrackMenu(c, songs[i]),
              ),
              const Hairline(indent: 86),
            ],
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 90)),
    ];
  }
}
