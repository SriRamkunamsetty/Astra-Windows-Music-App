import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../studio/jobs.dart';
import '../../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/tappable.dart';

/// Export progress: Exporting → Saved / Cancelled / Failed.
class JobSheet extends StatelessWidget {
  const JobSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 12.0);
    return ListenableBuilder(
      listenable: app.jobs,
      builder: (context, _) {
        final job = app.jobs.job;
        final shown = job != null;
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !shown,
                child: GestureDetector(
                  onTap: app.jobs.dismiss,
                  child: AnimatedOpacity(
                    opacity: shown ? 1 : 0,
                    duration: t.fastDur,
                    child: const ColoredBox(color: Color(0x66000000)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: bottom,
              child: IgnorePointer(
                ignoring: !shown,
                child: AnimatedSlide(
                  offset: shown ? Offset.zero : const Offset(0, 1.4),
                  duration: t.sheetDur,
                  curve: AstraTokens.ease,
                  child: job == null ? const SizedBox(height: 200) : _Card(job: job),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = context.tk;
    final jobs = app.jobs;
    const green = Color(0xFF34C759);
    final (headline, status, icon, tone) = switch (job.status) {
      JobStatus.done => (
        'Saved',
        job.spec.ringtone ? 'Set as your ringtone' : 'Output verified',
        CupertinoIcons.checkmark_circle_fill,
        green,
      ),
      JobStatus.cancelled => ('Cancelled', 'Partial file removed', CupertinoIcons.xmark_circle_fill, t.secondary),
      JobStatus.failed => (
        'Export Failed',
        job.error ?? 'Something went wrong',
        CupertinoIcons.exclamationmark_circle_fill,
        const Color(0xFFFF3B30),
      ),
      JobStatus.running => (
        'Exporting',
        'Writing ${job.spec.kind.toLowerCase()} file…',
        CupertinoIcons.waveform_circle_fill,
        t.accent,
      ),
    };
    final buttons = switch (job.status) {
      JobStatus.done => [_Btn('Done', primary: true, onTap: jobs.dismiss)],
      JobStatus.running => [_Btn('Cancel', onTap: jobs.cancel)],
      _ => [_Btn('Close', onTap: jobs.dismiss), _Btn('Retry', primary: true, onTap: jobs.retry)],
    };
    return Glass(
      radius: 34,
      fill: t.dark ? const Color(0xF21C1C1E) : const Color(0xF2F2F2F7),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: t.title3),
                    Text(
                      job.spec.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.subhead.copyWith(color: t.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: t.fillStrong)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 200),
                    widthFactor: (job.progress / 100).clamp(0.0, 1.0),
                    child: ColoredBox(color: job.status == JobStatus.done ? green : t.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(status, maxLines: 2, style: t.footnote.copyWith(color: t.secondary)),
              ),
              Text('${job.progress.round()}%', style: t.footnote.copyWith(color: t.secondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (i, b) in buttons.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: b)],
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, {required this.onTap, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      label: label,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: primary ? t.accent : t.fillStrong, borderRadius: BorderRadius.circular(25)),
        child: Text(label, style: t.headline.copyWith(color: primary ? t.onAccent : t.label)),
      ),
    );
  }
}
