import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_scope.dart';
import 'audio/player_controller.dart';
import 'data/library_repository.dart';
import 'data/playlist_store.dart';
import 'data/settings_store.dart';
import 'studio/jobs.dart';
import 'theme/tokens.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsStore(prefs);
  final library = LibraryRepository(prefs, settings);
  final player = PlayerController(prefs, settings);
  player.library = library;
  final jobs = JobController(prefs, settings);
  final playlists = PlaylistStore(prefs);
  await player.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(AstraApp(settings: settings, library: library, player: player, jobs: jobs, playlists: playlists));
  await library.scan();
  await player.restore(library);
}

class AstraApp extends StatefulWidget {
  const AstraApp({
    super.key,
    required this.settings,
    required this.library,
    required this.player,
    required this.jobs,
    required this.playlists,
  });

  final SettingsStore settings;
  final LibraryRepository library;
  final PlayerController player;
  final JobController jobs;
  final PlaylistStore playlists;

  @override
  State<AstraApp> createState() => _AstraAppState();
}

class _AstraAppState extends State<AstraApp> with WidgetsBindingObserver {
  final nav = NavState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from system settings may have granted access.
    if (state == AppLifecycleState.resumed &&
        widget.library.access != LibraryAccess.granted &&
        widget.library.access != LibraryAccess.notNeeded) {
      widget.library.scan(ask: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final platformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        final dark = s.theme == 'dark' || (s.theme == 'system' && platformDark);
        final tokens = AstraTokens.resolve(
          dark: dark,
          accentId: s.accent,
          glass: s.glass,
          reduceTransparency: s.reduceTransparency,
          reduceMotion: s.reduceMotion,
        );
        return AstraTheme(
          tokens: tokens,
          child: AppScope(
            settings: s,
            library: widget.library,
            player: widget.player,
            jobs: widget.jobs,
            playlists: widget.playlists,
            nav: nav,
            child: CupertinoApp(
              title: 'Astra Music',
              debugShowCheckedModeBanner: false,
              scrollBehavior: const AstraScrollBehavior(),
              theme: tokens.cupertinoTheme(),
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                minScaleFactor: .85,
                maxScaleFactor: 1.35,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                    statusBarColor: const Color(0x00000000),
                    systemNavigationBarColor: const Color(0x00000000),
                    systemNavigationBarContrastEnforced: false,
                  ),
                  child: ColoredBox(color: tokens.bg, child: child!),
                ),
              ),
              home: const Shell(),
            ),
          ),
        );
      },
    );
  }
}

class AstraScrollBehavior extends CupertinoScrollBehavior {
  const AstraScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (details.direction == AxisDirection.left || details.direction == AxisDirection.right) {
      return child;
    }
    return super.buildScrollbar(context, child, details);
  }
}
