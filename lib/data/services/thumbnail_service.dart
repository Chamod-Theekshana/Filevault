import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/debouncer.dart';
import 'package:filevault/data/services/platform_channel_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lazily produced, disk-cached thumbnails for videos and APK icons.
/// Image thumbnails are decoded by Flutter directly with a resize hint, so
/// they never go through this service.
class ThumbnailService {
  ThumbnailService(this._platform);

  final PlatformChannelService _platform;
  final Semaphore _slots = Semaphore(3);
  /// Bounded in-memory cache (insertion-ordered map used as an LRU) so long
  /// scrolling sessions through big galleries cannot grow memory forever.
  final Map<String, Uint8List?> _memory = <String, Uint8List?>{};
  static const int _memoryCapacity = 240;

  Uint8List? _remember(String key, Uint8List? bytes) {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > _memoryCapacity) {
      _memory.remove(_memory.keys.first);
    }
    return bytes;
  }
  Directory? _cacheDir;

  Future<Directory> _dir() async {
    final Directory? existing = _cacheDir;
    if (existing != null) return existing;
    final Directory tmp = await getTemporaryDirectory();
    final Directory dir = Directory(p.join(tmp.path, AppConstants.thumbCacheFolderName));
    await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  String _key(String path, int size, DateTime modified) =>
      md5.convert('$path|$size|${modified.millisecondsSinceEpoch}'.codeUnits).toString();

  /// JPEG bytes of a frame from the video, or null when it cannot be decoded.
  Future<Uint8List?> video(String path, {required int size, required DateTime modified}) async {
    final String key = _key(path, size, modified);
    if (_memory.containsKey(key)) return _memory[key];
    final Directory dir = await _dir();
    final File cached = File(p.join(dir.path, '$key.jpg'));
    if (await cached.exists()) {
      final Uint8List bytes = await cached.readAsBytes();
      return _remember(key, bytes);
    }
    await _slots.acquire();
    try {
      final Uint8List? bytes = await _platform.videoThumbnail(path, width: 320);
      _remember(key, bytes);
      if (bytes != null) {
        try {
          await cached.writeAsBytes(bytes);
        } catch (_) {}
      }
      return bytes;
    } finally {
      _slots.release();
    }
  }

  Future<Uint8List?> apkIcon(String path, {required int size, required DateTime modified}) async {
    final String key = 'apk-${_key(path, size, modified)}';
    if (_memory.containsKey(key)) return _memory[key];
    await _slots.acquire();
    try {
      final Uint8List? icon = (await _platform.apkInfo(path))?.icon;
      return _remember(key, icon);
    } finally {
      _slots.release();
    }
  }

  /// Forgets every cached thumbnail of [path] – used when a file is moved
  /// into the Secure Folder so no preview of it survives anywhere.
  Future<void> evict(String path, {required int size, required DateTime modified}) async {
    final String key = _key(path, size, modified);
    _memory.remove(key);
    _memory.remove('apk-$key');
    try {
      final File cached = File(p.join((await _dir()).path, '$key.jpg'));
      if (await cached.exists()) await cached.delete();
    } catch (_) {}
  }

  Future<void> clear() async {
    _memory.clear();
    try {
      final Directory dir = await _dir();
      await dir.delete(recursive: true);
      _cacheDir = null;
    } catch (_) {}
  }
}
