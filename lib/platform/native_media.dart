import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'audio_tag_reader.dart';

/// Platform media helper for Windows and other desktop environments.
class NativeMedia {
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<int> sdkInt() async => 0;

  static final volume = ValueNotifier<double>(1.0);

  static Future<void> initVolume() async {}

  static Future<void> setVolume(double v) async {
    volume.value = v.clamp(0.0, 1.0);
  }

  static Future<List<Map<String, Object?>>> queryAudio() async => const [];

  static Future<Uint8List?> albumArt(String uri, int? albumId, {int size = 512}) async =>
      AudioTagReader.extractArtwork(uri);

  /// Copies [path] into shared storage (`%USERPROFILE%/Music/Astra Music`).
  static Future<String?> saveToShared(String path, String displayName, String mime, {bool ringtone = false}) async {
    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final outDir = Directory(p.join(userProfile, 'Music', 'Astra Music'));
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final destPath = p.join(outDir.path, displayName);
      await File(path).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  static Future<bool> canWriteSettings() async => false;

  static Future<void> requestWriteSettings() async {}

  static Future<bool> setRingtone(String contentUri) async => false;
}
