import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';

/// Everything on the Settings screen, persisted and applied live.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._p);

  final SharedPreferences _p;

  /// 'system' | 'light' | 'dark'
  String get theme => _p.getString('theme') ?? 'system';
  set theme(String v) => _set('theme', v);

  /// One of [accents]. Values from older builds fall back to red.
  String get accent {
    final id = _p.getString('accent') ?? 'red';
    return accents.any((a) => a.id == id) ? id : 'red';
  }

  set accent(String v) => _set('accent', v);

  /// Liquid Glass transparency, 0–100.
  double get glass => _p.getDouble('glass') ?? kDefaultGlass;
  set glass(double v) => _set('glass', v);

  /// Solid surfaces instead of translucent glass, as iOS's Reduce Transparency.
  bool get reduceTransparency => _p.getBool('reduceTransparency') ?? false;
  set reduceTransparency(bool v) => _set('reduceTransparency', v);

  bool get reduceMotion => _p.getBool('rm') ?? false;
  set reduceMotion(bool v) => _set('rm', v);

  bool get haptics => _p.getBool('haptics') ?? true;
  set haptics(bool v) => _set('haptics', v);

  bool get gapless => _p.getBool('gapless') ?? true;
  set gapless(bool v) => _set('gapless', v);

  /// 'M4A' | 'MP3' | 'FLAC' | 'WAV'
  String get exportFormat => _p.getString('exportFmt') ?? 'M4A';
  set exportFormat(String v) => _set('exportFmt', v);

  /// Show the bundled sample tracks. On by default in browsers, where the
  /// device library can't be scanned.
  bool get samples => _p.getBool('samples') ?? kIsWeb;
  set samples(bool v) => _set('samples', v);

  /// Songs list ordering: 'Title' | 'Artist' | 'Recently Added' | 'Duration'.
  String get songSort => _p.getString('songSort') ?? 'Title';
  set songSort(String v) => _set('songSort', v);

  void _set(String k, Object v) {
    switch (v) {
      case final String s:
        _p.setString(k, s);
      case final bool b:
        _p.setBool(k, b);
      case final double d:
        _p.setDouble(k, d);
    }
    notifyListeners();
  }
}
