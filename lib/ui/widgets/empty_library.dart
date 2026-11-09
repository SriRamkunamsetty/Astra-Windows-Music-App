import 'package:flutter/cupertino.dart';

import '../../app_scope.dart';
import '../../data/library_repository.dart';
import '../../theme/tokens.dart';
import 'tappable.dart';

/// Shown when there is nothing to play: ask for access, import files or
/// turn on the sample tracks.
class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.library, app.settings]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final app = AppScope.of(context);
    final lib = app.library;
    final t = context.tk;
    if (!lib.ready) {
      // Still checking permission and reading the library.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }
    final denied = lib.access == LibraryAccess.denied || lib.access == LibraryAccess.permanentlyDenied;
    final (title, text) = switch (lib.access) {
      LibraryAccess.denied || LibraryAccess.permanentlyDenied => (
        'Allow Access to Your Music',
        'Astra Music reads the songs already on this phone. Nothing is uploaded.',
      ),
      LibraryAccess.granted => (
        'No Music Found',
        'There are no songs on this phone yet. Import files or try the samples.',
      ),
      _ => ('Add Some Music', 'Import audio files from this device, or try the sample tracks.'),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: t.dark ? t.cell : t.groupedBg,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: ShapeDecoration(
              color: t.accentTint(.14),
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Icon(CupertinoIcons.music_note_2, size: 32, color: t.accent),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: t.title3),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: t.subhead.copyWith(color: t.secondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (denied)
                _Btn(
                  label: lib.access == LibraryAccess.permanentlyDenied ? 'Open Settings' : 'Allow Access',
                  primary: true,
                  onTap: lib.access == LibraryAccess.permanentlyDenied ? lib.openPermissionSettings : () => lib.scan(),
                ),
              _Btn(
                label: 'Import Files',
                primary: !denied,
                onTap: () async {
                  final n = await lib.importFiles();
                  if (n > 0 && app.player.current == null) await app.player.restore(lib);
                },
              ),
              if (!app.settings.samples)
                _Btn(
                  label: 'Use Sample Tracks',
                  onTap: () async {
                    app.settings.samples = true;
                    if (app.player.current == null) await app.player.restore(lib);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onTap, this.primary = false});
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: primary ? t.accent : t.fillStrong, borderRadius: BorderRadius.circular(22)),
        child: Text(
          label,
          style: t.callout.copyWith(fontWeight: FontWeight.w600, color: primary ? t.onAccent : t.accent),
        ),
      ),
    );
  }
}
