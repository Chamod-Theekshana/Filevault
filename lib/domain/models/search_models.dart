import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';

enum SizeBucket { any, small, medium, large }

enum DateBucket { any, week, month, year }

/// Filters applied to a search query.
class SearchFilter {
  const SearchFilter({
    this.category,
    this.size = SizeBucket.any,
    this.date = DateBucket.any,
    this.includeHidden = false,
  });

  final FileCategory? category;
  final SizeBucket size;
  final DateBucket date;
  final bool includeHidden;

  bool get isDefault =>
      category == null &&
      size == SizeBucket.any &&
      date == DateBucket.any &&
      !includeHidden;

  int get activeCount =>
      (category == null ? 0 : 1) +
      (size == SizeBucket.any ? 0 : 1) +
      (date == DateBucket.any ? 0 : 1);

  int? get minBytes => switch (size) {
        SizeBucket.medium => 1024 * 1024,
        SizeBucket.large => 100 * 1024 * 1024,
        _ => null,
      };

  int? get maxBytes => switch (size) {
        SizeBucket.small => 1024 * 1024,
        SizeBucket.medium => 100 * 1024 * 1024,
        _ => null,
      };

  DateTime? since({DateTime? now}) {
    final DateTime n = now ?? DateTime.now();
    return switch (date) {
      DateBucket.week => n.subtract(const Duration(days: 7)),
      DateBucket.month => n.subtract(const Duration(days: 30)),
      DateBucket.year => DateTime(n.year),
      DateBucket.any => null,
    };
  }

  SearchFilter copyWith({
    FileCategory? category,
    bool clearCategory = false,
    SizeBucket? size,
    DateBucket? date,
    bool? includeHidden,
  }) {
    return SearchFilter(
      category: clearCategory ? null : (category ?? this.category),
      size: size ?? this.size,
      date: date ?? this.date,
      includeHidden: includeHidden ?? this.includeHidden,
    );
  }
}

/// A search hit with the matched range inside the file name.
class SearchHit {
  const SearchHit({required this.entry, required this.matchStart, required this.matchEnd});

  final FileEntry entry;
  final int matchStart;
  final int matchEnd;

  static SearchHit forQuery(FileEntry entry, String query) {
    final int idx = entry.name.toLowerCase().indexOf(query.toLowerCase());
    return SearchHit(
      entry: entry,
      matchStart: idx < 0 ? 0 : idx,
      matchEnd: idx < 0 ? 0 : idx + query.length,
    );
  }
}

/// Progress of the background indexer.
class IndexStatus {
  const IndexStatus({
    this.isRunning = false,
    this.indexedFiles = 0,
    this.lastIndexedAt,
  });

  final bool isRunning;
  final int indexedFiles;
  final DateTime? lastIndexedAt;

  IndexStatus copyWith({bool? isRunning, int? indexedFiles, DateTime? lastIndexedAt}) {
    return IndexStatus(
      isRunning: isRunning ?? this.isRunning,
      indexedFiles: indexedFiles ?? this.indexedFiles,
      lastIndexedAt: lastIndexedAt ?? this.lastIndexedAt,
    );
  }
}
