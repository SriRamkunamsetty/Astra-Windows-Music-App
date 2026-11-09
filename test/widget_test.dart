import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra_music_windows/data/settings_store.dart';
import 'package:astra_music_windows/theme/tokens.dart';

void main() {
  test('Astra Music Windows settings smoke test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsStore(prefs);
    expect(settings.glass, kDefaultGlass);
    expect(settings.theme, 'system');
    expect(settings.haptics, true);
  });
}
