import 'dart:io';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/data/services/platform_channel_service.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/domain/repositories/storage_repository.dart';
import 'package:path/path.dart' as p;

class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl(this._platform, this._fs);

  final PlatformChannelService _platform;
  final FileSystemService _fs;

  List<StorageVolume>? _cache;
  DateTime? _cachedAt;

  @override
  String get downloadsPath =>
      p.join(AppConstants.primaryStoragePath, AppConstants.downloadsFolder);

  @override
  Future<List<StorageVolume>> volumes() async {
    final DateTime? at = _cachedAt;
    final List<StorageVolume>? cached = _cache;
    if (cached != null && at != null && DateTime.now().difference(at).inSeconds < 15) {
      return cached;
    }
    List<StorageVolume> list = await _platform.storageVolumes();
    if (list.isEmpty) list = <StorageVolume>[StorageVolume.fallback];
    list.sort((StorageVolume a, StorageVolume b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    _cache = list;
    _cachedAt = DateTime.now();
    return list;
  }

  @override
  Future<StorageVolume> primaryVolume() async {
    final List<StorageVolume> all = await volumes();
    return all.firstWhere((StorageVolume v) => v.isPrimary, orElse: () => all.first);
  }

  @override
  Future<List<String>> scanRoots() async {
    final List<StorageVolume> all = await volumes();
    return all.map((StorageVolume v) => v.path).toList(growable: false);
  }

  @override
  Future<List<QuickAccessEntry>> quickAccess() async {
    const String root = AppConstants.primaryStoragePath;
    final List<QuickAccessEntry> candidates = <QuickAccessEntry>[
      QuickAccessEntry(
        id: 'downloads',
        title: 'Downloads',
        path: p.join(root, 'Download'),
        category: FileCategory.downloads,
      ),
      QuickAccessEntry(
        id: 'camera',
        title: 'Camera',
        path: p.join(root, 'DCIM', 'Camera'),
        category: FileCategory.images,
      ),
      QuickAccessEntry(
        id: 'whatsapp',
        title: 'WhatsApp',
        path: p.join(root, 'Android', 'media', 'com.whatsapp', 'WhatsApp', 'Media'),
        category: FileCategory.folders,
      ),
      QuickAccessEntry(
        id: 'screenshots',
        title: 'Screenshots',
        path: p.join(root, 'Pictures', 'Screenshots'),
        category: FileCategory.images,
      ),
      QuickAccessEntry(
        id: 'documents',
        title: 'Documents',
        path: p.join(root, 'Documents'),
        category: FileCategory.documents,
      ),
      QuickAccessEntry(
        id: 'telegram',
        title: 'Telegram',
        path: p.join(root, 'Telegram'),
        category: FileCategory.folders,
      ),
    ];
    final List<QuickAccessEntry> resolved = <QuickAccessEntry>[];
    for (final QuickAccessEntry c in candidates) {
      String path = c.path;
      if (c.id == 'screenshots' && !Directory(path).existsSync()) {
        path = p.join(root, 'DCIM', 'Screenshots');
      }
      final bool exists = Directory(path).existsSync();
      if (!exists && c.id != 'downloads') continue;
      resolved.add(QuickAccessEntry(
        id: c.id,
        title: c.title,
        path: path,
        category: c.category,
        exists: exists,
      ));
    }
    // One background pass for every folder count instead of one per folder.
    Map<String, int> counts = const <String, int>{};
    try {
      counts = await _fs.childCounts(
        <String>[
          for (final QuickAccessEntry e in resolved)
            if (e.exists) e.path,
        ],
        showHidden: false,
      );
    } catch (_) {}
    final List<QuickAccessEntry> out = <QuickAccessEntry>[
      for (final QuickAccessEntry e in resolved) e.copyWith(itemCount: counts[e.path] ?? 0),
    ];
    return out;
  }
}
