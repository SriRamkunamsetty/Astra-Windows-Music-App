import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../app_scope.dart';
import '../../data/library_repository.dart';
import '../../platform/native_media.dart';
import '../../studio/media_tools.dart';
import '../../theme/tokens.dart';
import '../studio/studio_state.dart';
import '../studio/studio_widgets.dart';
import '../widgets/controls.dart';
import '../widgets/tappable.dart';

/// Kept in step with `version:` in pubspec.yaml.
const appVersion = '1.0.0';

Future<void> showSettingsSheet(BuildContext context) {
  return showCupertinoSheet<void>(
    context: context,
    scrollableBuilder: (_, controller) => SettingsSheet(controller: controller),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, this.controller});
  final ScrollController? controller;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  int? _tempBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTemp();
    });
  }

  Future<void> _refreshTemp() async {
    if (!mounted) return;
    final b = await AppScope.of(context).jobs.tempBytes();
    if (mounted) setState(() => _tempBytes = b);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final t = context.tk;
    return ListenableBuilder(
      listenable: Listenable.merge([s, app.library]),
      builder: (context, _) {
        final access = app.library.access;
        return ColoredBox(
          color: t.groupedBg,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('Settings', style: t.title2)),
                      Tappable(
                        onTap: () => Navigator.of(context).maybePop(),
                        label: 'Done',
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('Done', style: t.headline.copyWith(color: t.accent)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: widget.controller,
                    padding: EdgeInsets.only(top: 6, bottom: MediaQuery.paddingOf(context).bottom + 30),
                    children: [
                      InsetGroup(
                        header: 'Appearance',
                        children: [
                          _Stack(
                            title: 'Theme',
                            child: Segmented(
                              options: const ['System', 'Light', 'Dark'],
                              value: s.theme[0].toUpperCase() + s.theme.substring(1),
                              onChanged: (v) => s.theme = v.toLowerCase(),
                            ),
                          ),
                          _Stack(
                            title: 'Accent Color',
                            trailing: accentById(s.accent).name,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final a in accents)
                                  _Swatch(
                                    color: a.of(t.dark),
                                    on: a.id == s.accent,
                                    label: a.name,
                                    onTap: () => s.accent = a.id,
                                  ),
                              ],
                            ),
                          ),
                          _Stack(
                            title: 'Liquid Glass',
                            trailing: '${s.glass.round()}%',
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.circle_fill, size: 14, color: t.tertiary),
                                Expanded(
                                  child: CupertinoSlider(
                                    value: s.glass,
                                    min: 0,
                                    max: 100,
                                    activeColor: t.accent,
                                    onChanged: (v) => s.glass = v.roundToDouble(),
                                  ),
                                ),
                                Icon(CupertinoIcons.circle, size: 14, color: t.tertiary),
                              ],
                            ),
                          ),
                          _Toggle(
                            'Reduce Transparency',
                            'Solid surfaces instead of glass',
                            s.reduceTransparency,
                            (v) => s.reduceTransparency = v,
                          ),
                          _Toggle('Reduce Motion', 'Sheets snap in place', s.reduceMotion, (v) => s.reduceMotion = v),
                        ],
                      ),
                      InsetGroup(
                        header: 'Playback',
                        children: [
                          _Toggle('Gapless Playback', 'No pause between songs', s.gapless, (v) => s.gapless = v),
                          _Toggle('Haptic Feedback', 'On play, seek and export', s.haptics, (v) => s.haptics = v),
                          _Stack(
                            title: 'Export Format',
                            child: Segmented(
                              options: const ['M4A', 'MP3', 'FLAC', 'WAV'],
                              value: s.exportFormat,
                              onChanged: (v) {
                                s.exportFormat = v;
                                // Studio formats follow the default.
                                final st = StudioState.instance;
                                if (const ['M4A', 'MP3', 'WAV'].contains(v)) st.trimFmt = v;
                                st.convFmt = v == 'M4A' ? 'AAC' : v;
                                st.changed();
                              },
                            ),
                          ),
                        ],
                      ),
                      InsetGroup(
                        header: 'Library',
                        footer: 'Sample tracks are eight short demo songs you can use to try the app.',
                        children: [
                          _Toggle('Sample Tracks', 'Show demo songs', s.samples, (v) async {
                            s.samples = v;
                            if (v && app.player.current == null) await app.player.restore(app.library);
                          }),
                          if (kIsWeb || !NativeMedia.isAndroid)
                            InsetRow(
                              leading: const IconTile(CupertinoIcons.tray_arrow_down_fill, color: Color(0xFF007AFF)),
                              title: 'Import Files',
                              subtitle: 'Add audio from this device',
                              chevron: true,
                              onTap: () async {
                                final n = await app.library.importFiles();
                                if (n > 0 && app.player.current == null) await app.player.restore(app.library);
                              },
                            ),
                          if (NativeMedia.isAndroid && access != LibraryAccess.granted)
                            InsetRow(
                              leading: const IconTile(CupertinoIcons.lock_fill, color: Color(0xFFFF9500)),
                              title: 'Allow Access to Music',
                              subtitle: 'Astra Music can only play imported files',
                              chevron: true,
                              onTap: access == LibraryAccess.permanentlyDenied
                                  ? app.library.openPermissionSettings
                                  : () => app.library.scan(),
                            ),
                        ],
                      ),
                      InsetGroup(
                        header: 'Storage',
                        footer: 'Everything is processed on this device. No account, analytics or uploads.',
                        children: [
                          InsetRow(
                            title: 'Temporary Files',
                            subtitle: _tempBytes == null ? '…' : fmtBytes(_tempBytes!),
                            trailing: kIsWeb
                                ? null
                                : Tappable(
                                    onTap: () async {
                                      await app.jobs.clearTemp();
                                      _refreshTemp();
                                    },
                                    label: 'Clear temporary files',
                                    child: Text('Clear', style: t.body.copyWith(color: t.accent)),
                                  ),
                          ),
                        ],
                      ),
                      Center(
                        child: Text('Astra Music $appVersion', style: t.footnote.copyWith(color: t.secondary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A row with a title (and optional value) over a control.
class _Stack extends StatelessWidget {
  const _Stack({required this.title, required this.child, this.trailing});
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: t.body)),
              if (trailing != null) Text(trailing!, style: t.body.copyWith(color: t.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.sub, this.on, this.onChanged);
  final String title, sub;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetRow(
      title: title,
      subtitle: sub,
      minHeight: 58,
      trailing: Semantics(
        toggled: on,
        label: title,
        child: CupertinoSwitch(value: on, onChanged: onChanged),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.on, required this.label, required this.onTap});
  final Color color;
  final bool on;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Tappable(
      onTap: onTap,
      label: label,
      selected: on,
      press: Press.scale,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (on)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
            Container(
              width: on ? 24 : 30,
              height: on ? 24 : 30,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            if (on) Icon(CupertinoIcons.checkmark, size: 13, color: t.onAccent),
          ],
        ),
      ),
    );
  }
}
