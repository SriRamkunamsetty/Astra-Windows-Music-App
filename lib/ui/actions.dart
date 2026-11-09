import 'package:flutter/cupertino.dart';

import '../app_scope.dart';
import '../data/collections.dart';
import '../data/playlist_store.dart';
import '../data/track.dart';
import '../theme/tokens.dart';
import 'screens/collection_pages.dart';
import 'widgets/glass.dart';
import 'widgets/menu.dart';
import 'widgets/tappable.dart';

/// A page of tracks that isn't an album or artist: playlists and the
/// automatic lists (Favorites, Recently Played …).
class TrackListSpec {
  const TrackListSpec({
    required this.title,
    required this.tracks,
    required this.icon,
    this.subtitle,
    this.playlistId,
    this.gradient,
  });
  final String title;
  final String? subtitle;
  final List<Track> Function(BuildContext) tracks;
  final IconData icon;
  final String? playlistId;
  final List<Color>? gradient;
}

void _push(BuildContext context, Widget page) {
  final nav = AppScope.of(context).nav;
  nav.setNowPlaying(false);
  nav.push(CupertinoPageRoute<void>(builder: (_) => page));
}

void openAlbum(BuildContext context, Album album) => _push(context, AlbumPage(album: album));
void openArtist(BuildContext context, Artist artist) => _push(context, ArtistPage(artist: artist));
void openTrackList(BuildContext context, TrackListSpec spec) => _push(context, TrackListPage(spec: spec));

/// Plays [track] from [list] as the queue.
void playFrom(BuildContext context, List<Track> list, int i, {required String from}) {
  AppScope.of(context).player.playList(list, i, from: from);
}

/// The standard menu for a song.
void showTrackMenu(BuildContext anchor, Track t, {bool inNowPlaying = false}) {
  final app = AppScope.of(anchor);
  final p = app.player;
  final fav = p.isFav(t);
  final album = app.library.albumOf(t);
  final artist = app.library.artistOf(t);
  showAstraMenu(anchor, [
    MenuAction('Play Next', CupertinoIcons.list_bullet_indent, () {
      p.playNext(t);
      p.toast.value = 'Playing next';
    }),
    MenuAction('Play Last', CupertinoIcons.list_bullet, () {
      p.addToQueue(t);
      p.toast.value = 'Added to queue';
    }),
    MenuAction(fav ? 'Remove from Favorites' : 'Favorite', fav ? CupertinoIcons.heart_slash : CupertinoIcons.heart, () {
      p.toggleFav(t);
    }),
    MenuAction('Add to Playlist…', CupertinoIcons.music_note_list, () => showAddToPlaylist(anchor, [t])),
    if (album != null) MenuAction('Go to Album', CupertinoIcons.music_albums, () => openAlbum(anchor, album)),
    if (artist != null) MenuAction('Go to Artist', CupertinoIcons.person_2, () => openArtist(anchor, artist)),
  ]);
}

/// Asks for a playlist name and returns the created playlist.
Future<Playlist?> promptNewPlaylist(BuildContext context, {List<Track> tracks = const []}) async {
  final store = AppScope.of(context).playlists;
  final c = TextEditingController();
  final name = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('New Playlist'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: c,
          autofocus: true,
          placeholder: 'Playlist name',
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
      ),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  c.dispose();
  if (name == null) return null;
  return store.create(name, tracks: tracks);
}

Future<String?> promptRename(BuildContext context, String current) async {
  final c = TextEditingController(text: current);
  final name = await showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Rename Playlist'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(controller: c, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
      ),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  c.dispose();
  return name;
}

/// A glass bottom sheet listing the playlists, with "New Playlist" on top.
Future<void> showAddToPlaylist(BuildContext context, List<Track> tracks) {
  final app = AppScope.of(context);
  final t = context.tk;
  return showCupertinoModalPopup<void>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) => AstraTheme(
      tokens: t,
      child: ListenableBuilder(
        listenable: app.playlists,
        builder: (ctx, _) {
          final lists = app.playlists.all;
          final h = MediaQuery.sizeOf(ctx).height;
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.paddingOf(ctx).bottom + 10),
              child: Glass(
                radius: 34,
                fill: t.dark ? const Color(0xF21C1C1E) : const Color(0xF2F2F2F7),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: h * .6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
                        child: Row(
                          children: [
                            Expanded(child: Text('Add to Playlist', style: t.title3)),
                            Tappable(
                              onTap: () => Navigator.pop(ctx),
                              label: 'Close',
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(CupertinoIcons.xmark_circle_fill, color: t.tertiary, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          children: [
                            _SheetRow(
                              icon: CupertinoIcons.plus,
                              title: 'New Playlist…',
                              accent: true,
                              onTap: () async {
                                Navigator.pop(ctx);
                                final p = await promptNewPlaylist(context, tracks: tracks);
                                if (p != null) app.player.toast.value = 'Added to ${p.name}';
                              },
                            ),
                            for (final p in lists)
                              _SheetRow(
                                icon: CupertinoIcons.music_note_list,
                                title: p.name,
                                subtitle: '${p.keys.length} ${p.keys.length == 1 ? 'song' : 'songs'}',
                                onTap: () {
                                  final n = app.playlists.add(p.id, tracks);
                                  Navigator.pop(ctx);
                                  app.player.toast.value = n == 0 ? 'Already in ${p.name}' : 'Added to ${p.name}';
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.title, required this.onTap, this.subtitle, this.accent = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      press: Press.fill,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: ShapeDecoration(
                  color: accent ? t.accentTint(.15) : t.fill,
                  shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: Icon(icon, size: 19, color: accent ? t.accent : t.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.body.copyWith(color: accent ? t.accent : t.label)),
                    if (subtitle != null) Text(subtitle!, style: t.footnote.copyWith(color: t.secondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Automatic lists --------------------------------------------------------

List<Track> _byAdded(Iterable<Track> l) =>
    ([...l]..sort((a, b) => (b.added ?? DateTime(0)).compareTo(a.added ?? DateTime(0))));

final TrackListSpec kFavoritesList = TrackListSpec(
  title: 'Favorites',
  icon: CupertinoIcons.star_fill,
  gradient: const [Color(0xFFFF5E7E), Color(0xFFC2185B)],
  tracks: (c) {
    final app = AppScope.of(c);
    return [
      for (final t in app.library.tracks)
        if (app.player.favorites.contains(t.key)) t,
    ];
  },
);

final TrackListSpec kRecentlyPlayedList = TrackListSpec(
  title: 'Recently Played',
  icon: CupertinoIcons.clock_fill,
  gradient: const [Color(0xFFFFB347), Color(0xFFE5532D)],
  tracks: (c) {
    final app = AppScope.of(c);
    return [for (final k in app.player.recentKeys) ?app.library.byKey(k)];
  },
);

final TrackListSpec kMostPlayedList = TrackListSpec(
  title: 'Most Played',
  icon: CupertinoIcons.waveform,
  gradient: const [Color(0xFF56CCF2), Color(0xFF2F6FED)],
  tracks: (c) {
    final app = AppScope.of(c);
    final plays = app.player.playCounts;
    return ([
      ...app.library.tracks.where((t) => (plays[t.key] ?? 0) > 0),
    ]..sort((a, b) => (plays[b.key] ?? 0).compareTo(plays[a.key] ?? 0))).take(100).toList();
  },
);

final TrackListSpec kRecentlyAddedList = TrackListSpec(
  title: 'Recently Added',
  icon: CupertinoIcons.sparkles,
  gradient: const [Color(0xFFA18CD1), Color(0xFF5B3FC0)],
  tracks: (c) => _byAdded(AppScope.of(c).library.tracks).take(100).toList(),
);

/// A user playlist as a page spec.
TrackListSpec playlistSpec(Playlist p) => TrackListSpec(
  title: p.name,
  icon: CupertinoIcons.music_note_list,
  playlistId: p.id,
  tracks: (c) {
    final lib = AppScope.of(c).library;
    final cur = AppScope.of(c).playlists.byId(p.id);
    return [for (final k in cur?.keys ?? p.keys) ?lib.byKey(k)];
  },
);
