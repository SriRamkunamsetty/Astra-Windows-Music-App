import 'package:flutter/cupertino.dart';

import '../../theme/tokens.dart';
import '../widgets/tappable.dart';
import 'studio_state.dart';

/// Icon + tile colour for each Studio tool.
(IconData, Color) toolStyle(String id) => switch (id) {
  'trim' => (CupertinoIcons.scissors, const Color(0xFFFF9500)),
  'video' => (CupertinoIcons.film, const Color(0xFF007AFF)),
  'conv' => (CupertinoIcons.arrow_2_squarepath, const Color(0xFF34C759)),
  'merge' => (CupertinoIcons.arrow_merge, const Color(0xFFAF52DE)),
  'split' => (CupertinoIcons.rectangle_split_3x1, const Color(0xFFFF2D55)),
  'ring' => (CupertinoIcons.bell_fill, const Color(0xFFFF3B30)),
  _ => (CupertinoIcons.waveform, const Color(0xFF8E8E93)),
};

StudioTool toolById(String id) => studioTools.firstWhere((x) => x.id == id);

/// A card at the top of each tool showing the source and a Choose button.
class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.leading, required this.title, required this.meta, required this.onChoose});
  final Widget leading;
  final String title, meta;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: t.cell,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Row(
        children: [
          SizedBox(width: 52, height: 52, child: leading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.headline),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.footnote.copyWith(color: t.secondary),
                ),
              ],
            ),
          ),
          Tappable(
            onTap: onChoose,
            label: 'Choose source',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Choose', style: t.body.copyWith(color: t.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A caption above a block of options.
class OptionBlock extends StatelessWidget {
  const OptionBlock({super.key, required this.label, required this.child, this.opacity = 1});
  final String label;
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Opacity(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(label.toUpperCase(), style: t.footnote.copyWith(color: t.secondary)),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// iOS segmented control over string options.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final v = options.contains(value) ? value : options.first;
    return IgnorePointer(
      ignoring: !enabled,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: v,
          backgroundColor: t.fill,
          thumbColor: t.dark ? const Color(0xFF636366) : const Color(0xFFFFFFFF),
          children: {
            for (final o in options)
              o: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(o, maxLines: 1, style: t.subhead.copyWith(fontWeight: FontWeight.w600)),
              ),
          },
          onValueChanged: (s) {
            if (s != null) onChanged(s);
          },
        ),
      ),
    );
  }
}

/// A subdued explanatory paragraph under a control.
class Note extends StatelessWidget {
  const Note(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
      child: Text(text, style: t.footnote.copyWith(color: t.secondary)),
    );
  }
}
