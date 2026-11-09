import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../theme/tokens.dart';
import '../widgets/controls.dart';
import '../widgets/glass.dart';
import '../widgets/rows.dart';
import '../widgets/tappable.dart';
import 'studio_state.dart';

/// Bottom sheet for choosing a Studio source: any library song, or a file
/// from the device.
Future<Track?> chooseSource(BuildContext context, {String title = 'Choose a Song', Set<String> exclude = const {}}) {
  final app = AppScope.of(context);
  final t = context.tk;
  return showCupertinoModalPopup<Track>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (ctx) {
      final tracks = app.library.tracks.where((x) => !exclude.contains(x.key)).toList();
      final h = MediaQuery.sizeOf(ctx).height;
      return AstraTheme(
        tokens: t,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.paddingOf(ctx).bottom + 10),
            child: Glass(
              radius: 34,
              fill: t.dark ? const Color(0xF21C1C1E) : const Color(0xF2F2F2F7),
              child: SizedBox(
                height: (h * .7).clamp(320.0, 620.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 8, 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(title, style: t.title3)),
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
                    Tappable(
                      onTap: () async {
                        final f = await StudioState.instance.pickFile();
                        if (ctx.mounted) Navigator.pop(ctx, f);
                      },
                      press: Press.fill,
                      label: 'Browse files',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            const IconTile(CupertinoIcons.folder_fill, color: Color(0xFF007AFF), size: 44),
                            const SizedBox(width: 14),
                            Text('Browse Files', style: t.body),
                          ],
                        ),
                      ),
                    ),
                    const Hairline(indent: 20),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: tracks.length,
                        itemBuilder: (context, i) => SongRow(
                          track: tracks[i],
                          indent: 20,
                          showDuration: true,
                          onTap: () => Navigator.pop(ctx, tracks[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
