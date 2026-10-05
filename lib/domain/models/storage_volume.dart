enum StorageVolumeKind { internal, sdCard, usb }

/// A mounted storage volume reported by the Android platform channel.
class StorageVolume {
  const StorageVolume({
    required this.id,
    required this.name,
    required this.path,
    required this.totalBytes,
    required this.freeBytes,
    required this.isPrimary,
    required this.isRemovable,
    required this.kind,
  });

  final String id;
  final String name;
  final String path;
  final int totalBytes;
  final int freeBytes;
  final bool isPrimary;
  final bool isRemovable;
  final StorageVolumeKind kind;

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);

  double get usedFraction => totalBytes <= 0 ? 0 : usedBytes / totalBytes;

  int get usedPercent => (usedFraction * 100).round();

  static StorageVolume fromMap(Map<Object?, Object?> map) {
    final String kindName = (map['kind'] as String?) ?? 'internal';
    return StorageVolume(
      id: (map['id'] as String?) ?? (map['path'] as String? ?? 'internal'),
      name: (map['name'] as String?) ?? 'Storage',
      path: (map['path'] as String?) ?? '/storage/emulated/0',
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
      isPrimary: map['isPrimary'] == true,
      isRemovable: map['isRemovable'] == true,
      kind: switch (kindName) {
        'sdCard' => StorageVolumeKind.sdCard,
        'usb' => StorageVolumeKind.usb,
        _ => StorageVolumeKind.internal,
      },
    );
  }

  static const StorageVolume fallback = StorageVolume(
    id: 'internal',
    name: 'Internal storage',
    path: '/storage/emulated/0',
    totalBytes: 0,
    freeBytes: 0,
    isPrimary: true,
    isRemovable: false,
    kind: StorageVolumeKind.internal,
  );
}
