import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/track.dart';
import '../../studio/commands.dart';
import '../../studio/jobs.dart';
import '../../studio/media_tools.dart';
import '../../theme/tokens.dart';
import '../widgets/controls.dart';
import 'source_picker.dart';
import 'studio_state.dart';
import 'studio_widgets.dart';

/// Converter and Video to audio.
class ConvertTool extends StatefulWidget {
  const ConvertTool({super.key, required this.tool});
  final StudioTool tool;

  @override
  State<ConvertTool> createState() => _ConvertToolState();
}

class _ConvertToolState extends State<ConvertTool> {
  final st = StudioState.instance;

  bool get isVideo => widget.tool.id == 'video';

  @override
  void initState() {
    super.initState();
    if (!isVideo && st.convSrc == null) {
      final app = AppScope.of(context);
      st.convSrc = st.src ?? app.player.current ?? app.library.tracks.firstOrNull;
    }
  }

  Future<void> _choose() async {
    final Track? t = isVideo ? await st.pickFile(video: true) : await chooseSource(context);
    if (t == null) return;
    if (isVideo) {
      st.video = t;
      st.stream = 0;
    } else {
      st.convSrc = t;
    }
    st.changed();
  }

  Future<void> _export(Track src, String out) async {
    final app = AppScope.of(context);
    app.player.haptic();
    final fmt = st.convFmt, stream = st.stream;
    final kbps = int.parse(st.br);
    final rate = st.sr == '48' ? 48000 : 44100;
    final dur = st.probes[src.key]?.duration ?? src.duration;
    app.jobs.start(
      JobSpec(
        name: out,
        kind: widget.tool.title,
        length: fmtDur(dur),
        expected: dur,
        outputs: [out],
        mime: mimeFor(fmt),
        buildArgs: (outs) async => convertArgs(await ffmpegInput(src), stream, fmt, kbps, rate, outs.first),
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
        final src = isVideo ? st.video : st.convSrc;
        final info = src == null ? null : st.probes[src.key];
        if (src != null && info == null) st.ensureProbe(src);
        final String meta;
        if (src == null) {
          meta = isVideo ? 'MP4, MOV, MKV or WebM' : 'Pick a song to convert';
        } else if (isVideo) {
          meta = [
            [info?.videoCodec, info?.audioStreams.firstOrNull?.codec].whereType<String>().join(' + '),
            fmtDur(info?.duration ?? src.duration),
            if (info?.size != null) fmtBytes(info!.size!),
          ].where((s) => s.isNotEmpty).join(' · ');
        } else {
          meta = [
            info?.format ?? src.formatLabel,
            if ((info?.sampleRate ?? 0) > 0) info!.sampleRateLabel,
            if (info?.channels != null) info!.channels![0].toUpperCase() + info.channels!.substring(1),
            fmtDur(src.duration),
          ].join(' · ');
        }
        final lossless = isLossless(st.convFmt);
        final out = src == null ? '—' : '${src.title}.${extFor(st.convFmt)}';
        final streams = info?.audioStreams ?? const <AudioStreamInfo>[];
        final (icon, color) = toolStyle(widget.tool.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SourceCard(
              leading: IconTile(icon, color: color, size: 52),
              title: src == null
                  ? (isVideo ? 'Choose a Video' : 'No Song Selected')
                  : (isVideo ? _fileName(src) : '${src.title}.${extFor(src.formatLabel)}'),
              meta: meta,
              onChoose: _choose,
            ),
            if (isVideo && streams.length > 1)
              OptionBlock(
                label: 'Audio stream',
                child: InsetGroup(
                  children: [
                    for (final (i, s) in streams.indexed)
                      InsetRow(
                        title: s.label,
                        trailing: i == st.stream.clamp(0, streams.length - 1)
                            ? Icon(CupertinoIcons.checkmark, size: 18, color: t.accent)
                            : null,
                        onTap: () {
                          st.stream = i;
                          st.changed();
                        },
                      ),
                  ],
                ),
              ),
            OptionBlock(
              label: 'Output format',
              child: Segmented(
                options: const ['MP3', 'AAC', 'FLAC', 'WAV', 'OGG'],
                value: st.convFmt,
                onChanged: (v) {
                  st.convFmt = v;
                  st.changed();
                },
              ),
            ),
            OptionBlock(
              label: 'Bitrate (kbps)',
              opacity: lossless ? .35 : 1,
              child: Segmented(
                options: const ['128', '192', '256', '320'],
                value: st.br,
                enabled: !lossless,
                onChanged: (v) {
                  st.br = v;
                  st.changed();
                },
              ),
            ),
            OptionBlock(
              label: 'Sample rate (kHz)',
              child: Segmented(
                options: const ['44.1', '48'],
                value: st.sr,
                onChanged: (v) {
                  st.sr = v;
                  st.changed();
                },
              ),
            ),
            if (lossless)
              Note(
                '${st.convFmt} is lossless, but converting from a lossy file does not restore lost quality. Bitrate does not apply.',
              ),
            OptionBlock(
              label: 'File name',
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: t.cell, borderRadius: BorderRadius.circular(25)),
                child: Text(out, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.body),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: widget.tool.cta!,
              enabled:
                  src != null &&
                  studioSupported &&
                  !app.jobs.running &&
                  (!isVideo || info == null || streams.isNotEmpty),
              onTap: src == null ? null : () => _export(src, out),
            ),
            if (isVideo && info != null && info.duration != null && streams.isEmpty)
              const Note('This video has no audio track.'),
          ],
        );
      },
    );
  }

  String _fileName(Track v) {
    final u = Uri.tryParse(v.uri);
    final seg = (u != null && u.pathSegments.isNotEmpty)
        ? Uri.decodeComponent(u.pathSegments.last)
        : v.uri.split('/').last;
    return seg.contains('.') ? seg.split('/').last : '${v.title}.mp4';
  }
}
