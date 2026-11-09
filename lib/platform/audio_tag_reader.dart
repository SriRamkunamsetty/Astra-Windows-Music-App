import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TagInfo {
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;

  const TagInfo({this.title, this.artist, this.album, this.artwork});
}

/// High-performance metadata and embedded album art reader for Windows.
/// Supports MP3 (ID3v2.2, ID3v2.3, ID3v2.4), FLAC, MP4/M4A, and directory covers.
class AudioTagReader {
  static final _artCache = <String, Uint8List?>{};
  static final _tagCache = <String, TagInfo>{};

  /// Extracts embedded album artwork bytes for the audio file at [filePath].
  static Future<Uint8List?> extractArtwork(String filePath) async {
    if (_artCache.containsKey(filePath)) {
      return _artCache[filePath];
    }
    final info = await readMetadata(filePath);
    _artCache[filePath] = info.artwork;
    return info.artwork;
  }

  /// Reads audio metadata (title, artist, album, artwork).
  static Future<TagInfo> readMetadata(String filePath) async {
    if (_tagCache.containsKey(filePath)) {
      return _tagCache[filePath]!;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      const empty = TagInfo();
      _tagCache[filePath] = empty;
      return empty;
    }

    TagInfo info = const TagInfo();
    try {
      final ext = filePath.toLowerCase();
      if (ext.endsWith('.mp3')) {
        info = await _readMp3(file);
      } else if (ext.endsWith('.flac')) {
        info = await _readFlac(file);
      } else if (ext.endsWith('.m4a') || ext.endsWith('.mp4') || ext.endsWith('.aac')) {
        info = await _readMp4(file);
      }
    } catch (_) {
      // Fallback
    }

    // If no artwork was embedded inside the audio file, check the folder
    if (info.artwork == null) {
      final dirArt = await _findDirectoryArt(file);
      if (dirArt != null) {
        info = TagInfo(
          title: info.title,
          artist: info.artist,
          album: info.album,
          artwork: dirArt,
        );
      }
    }

    _tagCache[filePath] = info;
    if (info.artwork != null) {
      _artCache[filePath] = info.artwork;
    }
    return info;
  }

  static Future<Uint8List?> _findDirectoryArt(File file) async {
    try {
      final parent = file.parent;
      final base = file.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '');
      final candidates = [
        'cover.jpg', 'cover.png', 'folder.jpg', 'folder.png', 'albumart.jpg', 'albumart.png',
        '$base.jpg', '$base.png',
      ];
      for (final name in candidates) {
        final f = File('${parent.path}${Platform.pathSeparator}$name');
        if (await f.exists()) {
          return await f.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<TagInfo> _readMp3(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(10);
      if (header.length < 10) return const TagInfo();

      // Check ID3v2 header: 'ID3'
      if (header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) {
        final major = header[3];
        final size = ((header[6] & 0x7F) << 21) |
            ((header[7] & 0x7F) << 14) |
            ((header[8] & 0x7F) << 7) |
            (header[9] & 0x7F);

        // Read up to 8MB of the ID3 tag data
        final readSize = size.clamp(0, 8 * 1024 * 1024);
        final tagBytes = await raf.read(readSize);
        return _parseId3v2(tagBytes, major);
      }
    } finally {
      await raf.close();
    }
    return const TagInfo();
  }

  static TagInfo _parseId3v2(Uint8List bytes, int major) {
    String? title;
    String? artist;
    String? album;
    Uint8List? artwork;

    var offset = 0;
    final len = bytes.length;

    while (offset + 10 <= len) {
      // Padding reached
      if (bytes[offset] == 0) {
        artwork ??= _scanForApic(bytes, offset);
        break;
      }

      final frameId = ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
      int frameSize;
      if (major == 4) {
        frameSize = ((bytes[offset + 4] & 0x7F) << 21) |
            ((bytes[offset + 5] & 0x7F) << 14) |
            ((bytes[offset + 6] & 0x7F) << 7) |
            (bytes[offset + 7] & 0x7F);
      } else {
        frameSize = (bytes[offset + 4] << 24) |
            (bytes[offset + 5] << 16) |
            (bytes[offset + 6] << 8) |
            bytes[offset + 7];
      }

      final payloadStart = offset + 10;
      final payloadEnd = (payloadStart + frameSize).clamp(payloadStart, len);
      if (payloadStart >= len || frameSize <= 0) break;

      final payload = bytes.sublist(payloadStart, payloadEnd);

      if (frameId == 'APIC' && artwork == null) {
        artwork = _extractApicImage(payload);
      } else if (frameId == 'TIT2' && title == null) {
        title = _cleanString(_decodeTextFrame(payload));
      } else if (frameId == 'TPE1' && artist == null) {
        artist = _cleanString(_decodeTextFrame(payload));
      } else if (frameId == 'TPE2' && artist == null) {
        artist = _cleanString(_decodeTextFrame(payload));
      } else if (frameId == 'TALB' && album == null) {
        album = _cleanString(_decodeTextFrame(payload));
      }

      offset = payloadEnd;
    }

    artwork ??= _scanForApic(bytes, 0);

    return TagInfo(title: title, artist: artist, album: album, artwork: artwork);
  }

  static String? _cleanString(String? val) {
    if (val == null) return null;
    var s = val.replaceAll('\x00', '').trim();
    // Clean up excessive web promo trailers if needed
    s = s.replaceAll(RegExp(r'\s*::\s*.*$'), '');
    s = s.replaceAll(RegExp(r'\s*-\s*\(?www\.[^)]+\)?', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'-?\s*SenSongsMp3\.Co[m]?', caseSensitive: false), '');
    s = s.trim();
    return s.isEmpty ? null : s;
  }

  static Uint8List? _scanForApic(Uint8List bytes, int start) {
    for (var i = start; i < bytes.length - 20; i++) {
      if (bytes[i] == 0x41 && bytes[i + 1] == 0x50 && bytes[i + 2] == 0x49 && bytes[i + 3] == 0x43) {
        final frameSize = (bytes[i + 4] << 24) |
            (bytes[i + 5] << 16) |
            (bytes[i + 6] << 8) |
            bytes[i + 7];
        final pStart = i + 10;
        final pEnd = (pStart + frameSize).clamp(pStart, bytes.length);
        if (pStart < bytes.length) {
          final art = _extractApicImage(bytes.sublist(pStart, pEnd));
          if (art != null) return art;
        }
      }
    }
    return null;
  }

  static Uint8List? _extractApicImage(Uint8List payload) {
    if (payload.length < 4) return null;

    final scanLimit = payload.length < 256 ? payload.length : 256;
    var imgStart = -1;

    for (var i = 0; i < scanLimit - 3; i++) {
      // JPEG: FF D8 FF
      if (payload[i] == 0xFF && payload[i + 1] == 0xD8 && payload[i + 2] == 0xFF) {
        imgStart = i;
        break;
      }
      // PNG: 89 50 4E 47
      if (payload[i] == 0x89 && payload[i + 1] == 0x50 && payload[i + 2] == 0x4E && payload[i + 3] == 0x47) {
        imgStart = i;
        break;
      }
      // WebP: 52 49 46 46 (RIFF)
      if (payload[i] == 0x52 && payload[i + 1] == 0x49 && payload[i + 2] == 0x46 && payload[i + 3] == 0x46) {
        imgStart = i;
        break;
      }
      // GIF: 47 49 46 38
      if (payload[i] == 0x47 && payload[i + 1] == 0x49 && payload[i + 2] == 0x46 && payload[i + 3] == 0x38) {
        imgStart = i;
        break;
      }
    }

    if (imgStart >= 0) {
      return payload.sublist(imgStart);
    }
    return null;
  }

  static String? _decodeTextFrame(Uint8List payload) {
    if (payload.isEmpty) return null;
    final encoding = payload[0];
    final data = payload.sublist(1);

    try {
      String s;
      switch (encoding) {
        case 0: // ISO-8859-1
          s = latin1.decode(data, allowInvalid: true);
          break;
        case 1: // UTF-16 with BOM
          s = _decodeUtf16(data);
          break;
        case 2: // UTF-16BE
          s = _decodeUtf16Be(data);
          break;
        case 3: // UTF-8
        default:
          s = utf8.decode(data, allowMalformed: true);
          break;
      }
      return s;
    } catch (_) {
      return null;
    }
  }

  static String _decodeUtf16(Uint8List bytes) {
    if (bytes.length < 2) return '';
    final bom = (bytes[0] << 8) | bytes[1];
    if (bom == 0xFEFF) {
      return _decodeUtf16Be(bytes.sublist(2));
    } else if (bom == 0xFFFE) {
      return _decodeUtf16Le(bytes.sublist(2));
    }
    return _decodeUtf16Le(bytes);
  }

  static String _decodeUtf16Le(Uint8List bytes) {
    final units = <int>[];
    for (var i = 0; i < bytes.length - 1; i += 2) {
      units.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(units);
  }

  static String _decodeUtf16Be(Uint8List bytes) {
    final units = <int>[];
    for (var i = 0; i < bytes.length - 1; i += 2) {
      units.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }

  static Future<TagInfo> _readFlac(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(4);
      if (header.length < 4 || ascii.decode(header, allowInvalid: true) != 'fLaC') return const TagInfo();

      Uint8List? artwork;
      var isLast = false;
      while (!isLast) {
        final blockHdr = await raf.read(4);
        if (blockHdr.length < 4) break;
        isLast = (blockHdr[0] & 0x80) != 0;
        final type = blockHdr[0] & 0x7F;
        final length = (blockHdr[1] << 16) | (blockHdr[2] << 8) | blockHdr[3];

        if (type == 6 && artwork == null) {
          // METADATA_BLOCK_PICTURE
          final data = await raf.read(length);
          if (data.length >= 32) {
            final mimeLen = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
            var off = 8 + mimeLen;
            if (off + 4 <= data.length) {
              final descLen = (data[off] << 24) | (data[off + 1] << 16) | (data[off + 2] << 8) | data[off + 3];
              off += 4 + descLen + 16;
              if (off + 4 <= data.length) {
                final picLen = (data[off] << 24) | (data[off + 1] << 16) | (data[off + 2] << 8) | data[off + 3];
                off += 4;
                if (off + picLen <= data.length) {
                  artwork = data.sublist(off, off + picLen);
                }
              }
            }
          }
        } else {
          await raf.setPosition(await raf.position() + length);
        }
      }

      return TagInfo(artwork: artwork);
    } finally {
      await raf.close();
    }
  }

  static Future<TagInfo> _readMp4(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final fileSize = await file.length();
      final readLen = fileSize.clamp(0, 4 * 1024 * 1024);
      final buf = await raf.read(readLen);
      for (var i = 0; i < buf.length - 16; i++) {
        if (buf[i] == 0x63 && buf[i + 1] == 0x6F && buf[i + 2] == 0x76 && buf[i + 3] == 0x72) {
          for (var j = i + 4; j < (i + 128).clamp(0, buf.length - 8); j++) {
            if (buf[j] == 0x64 && buf[j + 1] == 0x61 && buf[j + 2] == 0x74 && buf[j + 3] == 0x61) {
              final dataLen = (buf[j - 4] << 24) | (buf[j - 3] << 16) | (buf[j - 2] << 8) | buf[j - 1];
              final imgStart = j + 12;
              final imgEnd = (j - 4 + dataLen).clamp(imgStart, buf.length);
              if (imgStart < imgEnd) {
                return TagInfo(artwork: buf.sublist(imgStart, imgEnd));
              }
            }
          }
        }
      }
    } finally {
      await raf.close();
    }
    return const TagInfo();
  }
}
