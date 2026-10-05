
import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/domain/models/apk_info.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:flutter/services.dart';

/// Thin Dart wrapper around the Kotlin `FileVaultChannel`. Every call is
/// guarded so a missing implementation degrades gracefully instead of
/// crashing the UI.
class PlatformChannelService {
  PlatformChannelService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(AppConstants.platformChannel);

  final MethodChannel _channel;

  Future<List<StorageVolume>> storageVolumes() async {
    try {
      final List<Object?>? raw =
          await _channel.invokeMethod<List<Object?>>('getStorageVolumes');
      if (raw == null) return const <StorageVolume>[];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(StorageVolume.fromMap)
          .toList(growable: false);
    } on PlatformException catch (e) {
      appLogger.w('getStorageVolumes failed: ${e.message}');
      return const <StorageVolume>[];
    } on MissingPluginException {
      return const <StorageVolume>[];
    }
  }

  Future<Uint8List?> videoThumbnail(String path, {int width = 320}) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'getVideoThumbnail',
        <String, Object?>{'path': path, 'width': width},
      );
    } on PlatformException catch (e) {
      appLogger.d('videoThumbnail failed for $path: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<ApkInfo?> apkInfo(String path) async {
    try {
      final Map<Object?, Object?>? raw = await _channel
          .invokeMethod<Map<Object?, Object?>>('getApkInfo', <String, Object?>{'path': path});
      return raw == null ? null : ApkInfo.fromMap(raw);
    } on PlatformException catch (e) {
      appLogger.w('getApkInfo failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Asks the media scanner to pick up a new/moved file so galleries update.
  Future<void> scanMedia(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('scanMedia', <String, Object?>{'paths': paths});
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> startOperationNotification({
    required String title,
    required String text,
    required int progress,
  }) async {
    try {
      await _channel.invokeMethod<void>('startOperationService', <String, Object?>{
        'title': title,
        'text': text,
        'progress': progress,
      });
    } catch (e) {
      appLogger.d('startOperationService: $e');
    }
  }

  Future<void> updateOperationNotification({
    required String title,
    required String text,
    required int progress,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateOperationService', <String, Object?>{
        'title': title,
        'text': text,
        'progress': progress,
      });
    } catch (_) {}
  }

  Future<void> finishOperationNotification({
    required String title,
    required String text,
  }) async {
    try {
      await _channel.invokeMethod<void>('finishOperationService', <String, Object?>{
        'title': title,
        'text': text,
      });
    } catch (_) {}
  }

  Future<void> stopOperationNotification() async {
    try {
      await _channel.invokeMethod<void>('stopOperationService');
    } catch (_) {}
  }

  Future<void> openAllFilesAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openAllFilesAccessSettings');
    } catch (_) {}
  }
}
