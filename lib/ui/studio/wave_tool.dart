import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../platform/native_media.dart';
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

/// Cutter, Splitter and Ringtone: pick a range on the waveform and export.
class WaveTool extends StatefulWidget {
  const WaveTool({super.key, required this.tool});
  final StudioTool tool;

  @override
  State<WaveTool> createState() => _WaveToolState();
}

class _WaveToolState extends State<WaveTool> {
  final st = StudioState.instance;
  bool? _dragStart;

  @override
  void initState() {
    super.initState();
    final app = AppScope.of(context);
    final t = st.src ?? app.player.current ?? app.library.tracks.firstOrNull;
    if (t != null) st.setSource(t, notify: false);
  }

  static const _notes = {
    'ring': 'Android asks you to confirm the change. Not available on every device.',
    'split': 'Creates 3 files: start to marker, marker to marker, marker to end.',
  };

  void _pointer(Offset local, double width, {bool down = false}) {
    final f = (local.dx / width).clamp(0.0, 1.0);
    if (down) _dragStart = (f - st.tS).abs() <= (f - st.tE).abs();
    if (_dragStart != null) st.moveHandle(_dragStart!, f);
  }

  Future<void> _export() async {
    final app = AppScope.of(context);
    final src = st.src;
    if (src == null) return;
    final id = widget.tool.id;
    if (id == 'ring' && NativeMedia.isAndroid && !await NativeMedia.canWriteSettings()) {
      app.player.toast.value = 'Allow “Modify system settings”, then tap again';
      await NativeMedia.requestWriteSettings();
      return;
    }
    st.stopPreview();
    app.player.haptic();
    final secs = st.srcSecs;
    final a = st.tS * secs, b = st.tE * secs;
    final fmt = st.trimFmt;
    final ext = extFor(fmt);
    final tag = switch (id) {
      'split' => 'split',
      'ring' => 'ringtone',
      _ => 'trim',
    };
    final outputs = id == 'split'
        ? [for (var i = 1; i <= 3; i++) '${src.title} (part $i).$ext']
        : ['${src.title} ($tag).$ext'];
    app.jobs.start(
      JobSpec(
        name: '${src.title} ($tag).$ext',
        kind: widget.tool.title,
        length: fmtDur(Duration(milliseconds: (id == 'split' ? secs : b - a).round() * 1000)),
        expected: Duration(milliseconds: ((id == 'split' ? secs : b - a) * 1000).round()),
        outputs: outputs,
        mime: mimeFor(fmt),
        ringtone: id == 'ring',
        buildArgs: (outs) async {
          final input = await ffmpegInput(src);
          return id == 'split' ? splitArgs(input, a, b, secs, fmt, outs) : trimArgs(input, a, b, fmt, outs.first);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    return ListenableBuilder(
      listenable: Listenable.merge([st, app.jobs]),
      builder: (context, _) {
        final src = st.src;
        if (src == null) {
          return SourceCard(
            leading: _iconTile(t, CupertinoIcons.music_note),
            title: 'No Song Selected',
            meta: 'Choose something to trim',
            onChoose: _choose,
          );
        }
        final secs = st.srcSecs;
        final bars = st.wave ?? st.fallbackWave();
        final probe = st.probes[src.key];
        if (probe == null) st.ensureProbe(src);
        final meta = [
          probe?.format ?? src.formatLabel,
          if ((probe?.sampleRate ?? 0) > 0) probe!.sampleRateLabel,
          if (probe?.channels != null) _cap(probe!.channels!),
          fmtDur(src.duration),
        ].join(' · ');
        final note = _notes[widget.tool.id];
        final cta = widget.tool.id == 'trim' ? 'Export ${st.trimFmt}' : widget.tool.cta!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SourceCard(leading: TrackArt(src, size: 52, radius: 9), title: src.title, meta: meta, onChoose: _choose),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              decoration: ShapeDecoration(
                color: t.cell,
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 132,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        return Semantics(
                          label: 'Selection from ${fmtTenths(st.tS * secs)} to ${fmtTenths(st.tE * secs)}',
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) => _pointer(e.localPosition, w, down: true),
                            onPointerMove: (e) => _pointer(e.localPosition, w),
                            onPointerUp: (_) => _dragStart = null,
                            onPointerCancel: (_) => _dragStart = null,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Row(
                                    children: [
                                      for (final (i, h) in bars.indexed) ...[
                                        if (i > 0) const SizedBox(width: 2),
                                        Expanded(
                                          child: Center(
                                            child: FractionallySizedBox(
                                              widthFactor: 1,
                                              heightFactor: h,
                                              child: Builder(
                                                builder: (context) {
                                                  final x = i / bars.length;
                                                  final inside = x >= st.tS - .005 && x <= st.tE;
                                                  return DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: inside ? t.accent : t.tertiary,
                                                      borderRadius: BorderRadius.circular(99),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (st.cursor != null)
                                  Positioned(
                                    top: -4,
                                    bottom: -4,
                                    left: st.cursor! * w - 1,
                                    width: 2,
                                    child: ColoredBox(color: t.label),
                                  ),
                                _handle(t, st.tS * w, top: true),
                                _handle(t, st.tE * w, top: false),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _readout(t, 'Start', fmtTenths(st.tS * secs)),
                      _readout(t, 'Length', fmtTenths((st.tE - st.tS) * secs), accent: true),
                      _readout(t, 'End', fmtTenths(st.tE * secs)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _nudger(t, 'Start', true)),
                const SizedBox(width: 10),
                Expanded(child: _nudger(t, 'End', false)),
              ],
            ),
            const SizedBox(height: 14),
            Tappable(
              onTap: () => st.togglePreview(() async => app.player.pause()),
              label: st.previewing ? 'Stop preview' : 'Preview selection',
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: t.cell, borderRadius: BorderRadius.circular(24)),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      st.previewing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      size: 18,
                      color: t.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(st.previewing ? 'Stop Preview' : 'Preview', style: t.headline.copyWith(color: t.accent)),
                  ],
                ),
              ),
            ),
            OptionBlock(
              label: 'Format',
              child: Segmented(
                options: const ['M4A', 'MP3', 'WAV'],
                value: st.trimFmt,
                onChanged: (v) {
                  st.trimFmt = v;
                  st.changed();
                },
              ),
            ),
            if (note != null) Note(note),
            const SizedBox(height: 22),
            PrimaryButton(label: cta, onTap: _export, enabled: studioSupported && !app.jobs.running),
          ],
        );
      },
    );
  }

  Future<void> _choose() async {
    final t = await chooseSource(context);
    if (t != null) st.setSource(t);
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _iconTile(AstraTokens t, IconData icon) => Container(
    decoration: ShapeDecoration(
      color: t.fill,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(10)),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 24, color: t.secondary),
  );

  Widget _handle(AstraTokens t, double x, {required bool top}) => Positioned(
    left: x - 1.5,
    top: -14,
    bottom: -14,
    width: 3,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(99)),
          ),
        ),
        Positioned(
          left: -9.5,
          top: top ? -4 : null,
          bottom: top ? null : -4,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: t.accent,
              shape: BoxShape.circle,
              border: Border.all(color: t.cell, width: 3),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _readout(AstraTokens t, String label, String v, {bool accent = false}) => Expanded(
    child: Column(
      children: [
        Text(label, style: t.caption1.copyWith(color: t.secondary)),
        Text(
          v,
          style: t.title3.copyWith(
            color: accent ? t.accent : t.label,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  Widget _nudger(AstraTokens t, String label, bool start) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    decoration: BoxDecoration(color: t.cell, borderRadius: BorderRadius.circular(26)),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
        ),
        for (final (d, txt) in const [(-0.1, '−0.1'), (0.1, '+0.1')]) ...[
          if (d > 0) const SizedBox(width: 4),
          Tappable(
            onTap: () => st.nudge(start, d),
            label: '$label ${d < 0 ? 'earlier' : 'later'} 0.1 seconds',
            child: Container(
              width: 46,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(18)),
              child: Text(txt, style: t.footnote.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    ),
  );
}
