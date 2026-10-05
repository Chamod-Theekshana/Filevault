import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/storage_volume.dart';

/// Volumes and well-known folders.
abstract class StorageRepository {
  Future<List<StorageVolume>> volumes();

  /// The primary (internal) volume, or a fallback when the platform channel
  /// is unavailable.
  Future<StorageVolume> primaryVolume();

  /// Common folders (Downloads, Camera, Screenshots, WhatsApp…) with live
  /// item counts. Missing folders are flagged with `exists == false`.
  Future<List<QuickAccessEntry>> quickAccess();

  /// The folder new downloads land in.
  String get downloadsPath;

  /// All root paths that should be scanned for indexing.
  Future<List<String>> scanRoots();
}
