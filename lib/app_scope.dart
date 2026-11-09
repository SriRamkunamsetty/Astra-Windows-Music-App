import 'package:flutter/cupertino.dart';

import 'audio/player_controller.dart';
import 'data/library_repository.dart';
import 'data/playlist_store.dart';
import 'data/settings_store.dart';
import 'studio/jobs.dart';

enum AppTab { home, library, studio, search }

/// Which tab is showing, whether Now Playing is open, and a navigator per
/// tab so each keeps its own back stack.
class NavState extends ChangeNotifier {
  AppTab tab = AppTab.home;
  bool nowPlaying = false;

  final navigators = {for (final t in AppTab.values) t: GlobalKey<NavigatorState>(debugLabel: t.name)};

  NavigatorState? get navigator => navigators[tab]!.currentState;

  /// Selects [t]. Tapping the selected tab again returns to its root.
  void go(AppTab t) {
    if (t == tab) {
      navigators[t]!.currentState?.popUntil((r) => r.isFirst);
    } else {
      tab = t;
      notifyListeners();
    }
  }

  Future<T?> push<T>(Route<T> route, {AppTab? on}) {
    if (on != null && on != tab) {
      tab = on;
      notifyListeners();
    }
    final nav = navigators[tab]!.currentState;
    if (nav == null) return Future.value();
    return nav.push(route);
  }

  void setNowPlaying(bool v) {
    if (nowPlaying == v) return;
    nowPlaying = v;
    notifyListeners();
  }
}

/// Hands the app's controllers to every screen.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.library,
    required this.player,
    required this.jobs,
    required this.playlists,
    required this.nav,
    required super.child,
  });

  final SettingsStore settings;
  final LibraryRepository library;
  final PlayerController player;
  final JobController jobs;
  final PlaylistStore playlists;
  final NavState nav;

  static AppScope of(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => false;
}
