/// Semantic file categories used for colour coding, home tiles and search
/// filters. Order matters: it is the order shown on the home screen.
enum FileCategory {
  images,
  videos,
  audio,
  documents,
  downloads,
  apks,
  archives,
  trash,
  folders,
  other;

  bool get isMedia =>
      this == FileCategory.images || this == FileCategory.videos;

  /// Categories shown as tiles on the home screen.
  static const List<FileCategory> homeTiles = <FileCategory>[
    FileCategory.images,
    FileCategory.videos,
    FileCategory.audio,
    FileCategory.documents,
    FileCategory.downloads,
    FileCategory.apks,
    FileCategory.archives,
    FileCategory.trash,
  ];

  /// Categories that can be browsed as a virtual folder.
  static const List<FileCategory> browsable = <FileCategory>[
    FileCategory.images,
    FileCategory.videos,
    FileCategory.audio,
    FileCategory.documents,
    FileCategory.apks,
    FileCategory.archives,
  ];

  static FileCategory fromName(String? name) {
    for (final FileCategory c in FileCategory.values) {
      if (c.name == name) return c;
    }
    return FileCategory.other;
  }
}
