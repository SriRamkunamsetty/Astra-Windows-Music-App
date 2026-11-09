import 'dart:typed_data';

/// Only used in browsers.
String createBlobUrl(Uint8List bytes, String mime) => throw UnsupportedError('blob URLs are web-only');
