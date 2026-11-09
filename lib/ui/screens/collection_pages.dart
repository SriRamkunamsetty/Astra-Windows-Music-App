import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/collections.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../actions.dart';
import '../widgets/artwork.dart';
import '../widgets/controls.dart';
import '../widgets/menu.dart';
import '../widgets/page.dart';
import '../widgets/rows.dart';
import '../widgets/tappable.dart';

/// Play + Shuffle, the two capsules under every album, artist and playlist.
class PlayShuffleRow extends StatelessWidget {
  const PlayShuffleRow({super.key, required this.onPlay, required this.onShuffle, this.enabled = true});
  final VoidCallback onPlay, onShuffle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: PillButton(label: 'Play', icon: CupertinoIcons.play_fill, onTap: enabled ? onPlay : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(label: 'Shuffle', icon: CupertinoIcons.shuffle, onTap: enabled ? onShuffle : null),
            ),
          ],
        ),
      ),
    );
  }
}

void _albumMenu(BuildContext anchor, Album a) {
  final p = AppScope.of(anchor).player;
  showAstraMenu(anchor, [
    MenuAction('Play Next', CupertinoIcons.list_bullet_indent, () async {
      for (final t in a.tracks.reversed) {
        await p.playNext(t);
      }
      p.toast.value = 'Playing next';
    }),
    MenuAction('Play Last', CupertinoIcons.list_bullet, () async {
      for (final t in a.tracks) {
        await p.addToQueue(t);
      }
      p.toast.value = 'Added to queue';
    }),
    MenuAction('Add to Playlist…', CupertinoIcons.music_note_list, () => showAddToPlaylist(anchor, a.tracks)),
  ]);
}

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final w = MediaQuery.sizeOf(context).width;
    final art = (w - 100).clamp(200.0, 300.0);
    final artist = app.library.artists.where((a) => a.name == album.artist).firstOrNull;
    final meta = [if (album.year != null) '${album.year}', 'Album'].join(' · ').toUpperCase();
    return LargeTitlePage(
      title: album.name,
      largeTitle: false,
      wash: album.cover,
      actions: [
        Builder(
          builder: (c) =>
              GlassCircleButton(icon: CupertinoIcons.ellipsis, label: 'More', onTap: () => _albumMenu(c, album)),
        ),
      ],
      header: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 22),
        child: Column(
          children: [
            Center(child: TrackArt(album.cover, size: art, radius: 14, shadow: true)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(album.name, textAlign: TextAlign.center, style: t.title2),
            ),
            const SizedBox(height: 2),
            Tappable(
              onTap: artist == null ? null : () => openArtist(context, artist),
              label: album.artist,
              child: Text(
                album.artist,
                style: t.title2.copyWith(color: t.accent, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 4),
            Text(meta, style: t.caption1.copyWith(color: t.secondary, letterSpacing: .4)),
            const SizedBox(height: 18),
            PlayShuffleRow(
              onPlay: () => app.player.playList(album.tracks, 0, from: album.name),
              onShuffle: () => app.player.shufflePlay(album.tracks, from: album.name),
            ),
          ],
        ),
      ),
      slivers: [
        SliverList.builder(
          itemCount: album.tracks.length,
          itemBuilder: (context, i) {
            final tr = album.tracks[i];
            return Column(
              children: [
                if (i == 0) const Hairline(indent: 20),
                SongRow(
                  track: tr,
                  number: tr.trackNo > 0 ? tr.trackNo : i + 1,
                  subtitle: tr.artist == album.artist ? '' : tr.artist,
                  indent: 20,
                  showDuration: true,
                  onTap: () => app.player.playList(album.tracks, i, from: album.name),
                  onMore: (c) => showTrackMenu(c, tr),
                ),
                if (i < album.tracks.length - 1) const Hairline(indent: 60),
              ],
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              fmtSummary(album.tracks.length, album.duration),
              style: t.footnote.copyWith(color: t.secondary),
            ),
          ),
        ),
      ],
    );
  }
}

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.artist});
  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final w = MediaQuery.sizeOf(context).width;
    final plays = app.player.playCounts;
    final top = [...artist.tracks]..sort((a, b) => (plays[b.key] ?? 0).compareTo(plays[a.key] ?? 0));
    final topSongs = top.take(5).toList();
    return LargeTitlePage(
      title: artist.name,
      largeTitle: false,
      headerUnderBar: true,
      header: SizedBox(
        height: w * 1.05 + MediaQuery.paddingOf(context).top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The artwork runs full-bleed and melts into the page (iOS 27).
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                stops: [0, .45, 1],
              ).createShader(r),
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: w,
                  height: w,
                  child: TrackArt(artist.cover, size: w, radius: 0),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 0,
              child: Text(artist.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.largeTitle),
            ),
          ],
        ),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: PlayShuffleRow(
              onPlay: () => app.player.playList(top, 0, from: artist.name),
              onShuffle: () => app.player.shufflePlay(artist.tracks, from: artist.name),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Top Songs')),
        SliverList.builder(
          itemCount: topSongs.length,
          itemBuilder: (context, i) => Column(
            children: [
              if (i == 0) const Hairline(indent: 20),
              SongRow(
                track: topSongs[i],
                indent: 20,
                subtitle: topSongs[i].album,
                onTap: () => app.player.playList(top, i, from: artist.name),
                onMore: (c) => showTrackMenu(c, topSongs[i]),
              ),
              if (i < topSongs.length - 1) const Hairline(indent: 86),
            ],
          ),
        ),
        if (artist.albums.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Albums')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: artCardHeight(context, 156),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: artist.albums.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final a = artist.albums[i];
                  return ArtCard(
                    width: 156,
                    track: a.cover,
                    title: a.name,
                    subtitle: a.year?.toString() ?? '${a.tracks.length} songs',
                    onTap: () => openAlbum(context, a),
                  );
                },
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Text(
              fmtSummary(artist.tracks.length, artist.tracks.fold(Duration.zero, (a, x) => a + x.duration)),
              style: t.footnote.copyWith(color: t.secondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// A playlist or an automatic list (Favorites, Recently Played …).
class TrackListPage extends StatelessWidget {
  const TrackListPage({super.key, required this.spec});
  final TrackListSpec spec;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final w = MediaQuery.sizeOf(context).width;
    final side = (w - 140).clamp(180.0, 240.0);
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.player, app.playlists]),
      builder: (context, _) {
        final pl = spec.playlistId == null ? null : app.playlists.byId(spec.playlistId!);
        if (spec.playlistId != null && pl == null) {
          // Deleted from under us.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        final title = pl?.name ?? spec.title;
        final tracks = spec.tracks(context);
        final total = tracks.fold(Duration.zero, (a, x) => a + x.duration);
        final grad = spec.gradient ?? [t.accent, t.accent.withValues(alpha: .7)];
        return LargeTitlePage(
          title: title,
          largeTitle: false,
          actions: [
            if (pl != null)
              Builder(
                builder: (c) => GlassCircleButton(
                  icon: CupertinoIcons.ellipsis,
                  label: 'More',
                  onTap: () => showAstraMenu(c, [
                    MenuAction('Rename', CupertinoIcons.pencil, () async {
                      final n = await promptRename(context, pl.name);
                      if (n != null) app.playlists.rename(pl.id, n);
                    }),
                    MenuAction('Delete Playlist', CupertinoIcons.trash, () {
                      app.playlists.delete(pl.id);
                    }, destructive: true),
                  ]),
                ),
              ),
          ],
          header: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 22),
            child: Column(
              children: [
                Center(
                  child: tracks.isNotEmpty && pl != null
                      ? _Mosaic(tracks: tracks, size: side)
                      : _GradientCover(colors: grad, icon: spec.icon, size: side),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(title, textAlign: TextAlign.center, style: t.title2),
                ),
                if (spec.subtitle != null) Text(spec.subtitle!, style: t.subhead.copyWith(color: t.secondary)),
                const SizedBox(height: 18),
                PlayShuffleRow(
                  enabled: tracks.isNotEmpty,
                  onPlay: () => app.player.playList(tracks, 0, from: title),
                  onShuffle: () => app.player.shufflePlay(tracks, from: title),
                ),
              ],
            ),
          ),
          slivers: [
            if (tracks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Text(
                    pl != null
                        ? 'This playlist is empty. Add songs from the ··· menu on any song.'
                        : 'Nothing here yet.',
                    textAlign: TextAlign.center,
                    style: t.subhead.copyWith(color: t.secondary),
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final tr = tracks[i];
                return Column(
                  children: [
                    if (i == 0) const Hairline(indent: 20),
                    SongRow(
                      track: tr,
                      indent: 20,
                      onTap: () => app.player.playList(tracks, i, from: title),
                      onMore: (c) {
                        if (pl == null) return showTrackMenu(c, tr);
                        showAstraMenu(c, [
                          MenuAction('Play Next', CupertinoIcons.list_bullet_indent, () => app.player.playNext(tr)),
                          MenuAction('Play Last', CupertinoIcons.list_bullet, () => app.player.addToQueue(tr)),
                          MenuAction('Remove from Playlist', CupertinoIcons.minus_circle, () {
                            final at = pl.keys.indexOf(tr.key);
                            if (at >= 0) app.playlists.removeAt(pl.id, at);
                          }, destructive: true),
                        ]);
                      },
                    ),
                    if (i < tracks.length - 1) const Hairline(indent: 86),
                  ],
                );
              },
            ),
            if (tracks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(fmtSummary(tracks.length, total), style: t.footnote.copyWith(color: t.secondary)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.colors, required this.icon, required this.size});
  final List<Color> colors;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: ShapeDecoration(
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(artRadius(size))),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      shadows: [BoxShadow(color: const Color(0x38000000), blurRadius: 24, offset: Offset(0, size * .05))],
    ),
    child: Icon(icon, size: size * .4, color: const Color(0xFFFFFFFF).withValues(alpha: .92)),
  );
}

/// A 2×2 collage of up to four different covers.
class _Mosaic extends StatelessWidget {
  const _Mosaic({required this.tracks, required this.size});
  final List<Track> tracks;
  final double size;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final covers = <Track>[];
    for (final t in tracks) {
      if (seen.add(t.album)) covers.add(t);
      if (covers.length == 4) break;
    }
    if (covers.length < 4) {
      return TrackArt(covers.first, size: size, shadow: true);
    }
    final half = size / 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(artRadius(size)),
        boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(artRadius(size)),
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            children: [
              Row(children: [for (final t in covers.take(2)) TrackArt(t, size: half, radius: 0)]),
              Row(children: [for (final t in covers.skip(2)) TrackArt(t, size: half, radius: 0)]),
            ],
          ),
        ),
      ),
    );
  }
}
