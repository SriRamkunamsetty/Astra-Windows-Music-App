import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../studio/commands.dart';
import '../../studio/jobs.dart';
import '../../studio/media_tools.dart';
import '../../theme/tokens.dart';
import '../widgets/artwork.dart';
import '../widgets/controls.dart';
import '../widgets/tappable.dart';
import 'source_picker.dart';
import 'studio_state.dart';
import 'studio_widgets.dart';

class MergeTool extends StatelessWidget {
  const MergeTool({super.key});

  static const _notes = {
    'Sequential': 'Songs play one after another with no overlap.',
    'Crossfade': 'Each join overlaps by 2 seconds.',
    'Mix': 'All songs overlap and play at the same time.',
  };

  Duration _total(List<Track> ts, String mode) {
    if (ts.isEmpty) return Duration.zero;
    if (mode == 'Mix') return ts.map((t) => t.duration).reduce((a, b) => a > b ? a : b);
    final sum = ts.fold<Duration>(Duration.zero, (a, t) => a + t.duration);
    return mode == 'Crossfade' ? sum - Duration(seconds: 2 * math.max(0, ts.length - 1)) : sum;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final st = StudioState.instance;
    final t = context.tk;
    return ListenableBuilder(
      listenable: Listenable.merge([st, app.jobs]),
      builder: (context, _) {
        final ts = st.merge;
        final total = _total(ts, st.mergeMode);
        final canExport = ts.length >= 2 && studioSupported && !app.jobs.running;
        void move(int i, int d) {
          final j = i + d;
          if (j < 0 || j >= ts.length) return;
          final a = [...ts];
          final x = a[i];
          a[i] = a[j];
          a[j] = x;
          st.merge = a;
          st.changed();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ts.isNotEmpty)
              InsetGroup(
                header: 'Order',
                children: [
                  for (final (i, x) in ts.indexed)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${i + 1}',
                                textAlign: TextAlign.center,
                                style: t.headline.copyWith(color: t.accent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TrackArt(x, size: 44, radius: 8),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.body),
                                  Text(fmtDur(x.duration), style: t.footnote.copyWith(color: t.secondary)),
                                ],
                              ),
                            ),
                            _icon(t, CupertinoIcons.arrow_up, 'Move up', i == 0 ? .25 : 1, () => move(i, -1)),
                            _icon(
                              t,
                              CupertinoIcons.arrow_down,
                              'Move down',
                              i == ts.length - 1 ? .25 : 1,
                              () => move(i, 1),
                            ),
                            _icon(t, CupertinoIcons.xmark, 'Remove', 1, () {
                              st.merge = [...ts]..removeAt(i);
                              st.changed();
                            }, muted: true),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            Tappable(
              onTap: () async {
                final pick = await chooseSource(context, title: 'Add a Song', exclude: {for (final x in ts) x.key});
                if (pick != null) {
                  st.merge = [...st.merge, pick];
                  st.changed();
                }
              },
              label: 'Add song',
              child: Container(
                height: 52,
                decoration: BoxDecoration(color: t.cell, borderRadius: BorderRadius.circular(26)),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.plus_circle_fill, size: 22, color: t.accent),
                    const SizedBox(width: 8),
                    Text('Add Song', style: t.headline.copyWith(color: t.accent)),
                  ],
                ),
              ),
            ),
            OptionBlock(
              label: 'Mode',
              child: Segmented(
                options: const ['Sequential', 'Crossfade', 'Mix'],
                value: st.mergeMode,
                onChanged: (v) {
                  st.mergeMode = v;
                  st.changed();
                },
              ),
            ),
            Note(_notes[st.mergeMode]!),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ts.length} ${ts.length == 1 ? 'song' : 'songs'}',
                  style: t.subhead.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('Total ${fmtDur(total)}', style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Merge and Export',
              enabled: canExport,
              onTap: () {
                app.player.haptic();
                final fmt = app.settings.exportFormat;
                final list = [...ts];
                final mode = st.mergeMode;
                final name = 'Merged mix.${extFor(fmt)}';
                app.jobs.start(
                  JobSpec(
                    name: name,
                    kind: 'Merger',
                    length: fmtDur(total),
                    expected: total,
                    outputs: [name],
                    mime: mimeFor(fmt),
                    buildArgs: (outs) async =>
                        mergeArgs([for (final x in list) await ffmpegInput(x)], mode, fmt, outs.first),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _icon(AstraTokens t, IconData icon, String label, double opacity, VoidCallback onTap, {bool muted = false}) =>
      Tappable(
        onTap: onTap,
        label: label,
        child: SizedBox(
          width: 38,
          height: 44,
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Icon(icon, size: 18, color: muted ? t.secondary : t.label),
            ),
          ),
        ),
      );
}
