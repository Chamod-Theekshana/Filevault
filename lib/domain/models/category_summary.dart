import 'package:filevault/domain/models/file_category.dart';

/// Aggregated count and byte total for one category on one volume.
class CategorySummary {
  const CategorySummary({
    required this.category,
    required this.itemCount,
    required this.totalBytes,
  });

  final FileCategory category;
  final int itemCount;
  final int totalBytes;

  CategorySummary add(int bytes) => CategorySummary(
        category: category,
        itemCount: itemCount + 1,
        totalBytes: totalBytes + bytes,
      );

  static CategorySummary empty(FileCategory c) =>
      CategorySummary(category: c, itemCount: 0, totalBytes: 0);
}

/// A folder that is reachable in one tap from the home screen.
class QuickAccessEntry {
  const QuickAccessEntry({
    required this.id,
    required this.title,
    required this.path,
    required this.category,
    this.itemCount = 0,
    this.exists = true,
  });

  final String id;
  final String title;
  final String path;
  final FileCategory category;
  final int itemCount;
  final bool exists;

  QuickAccessEntry copyWith({int? itemCount, bool? exists}) => QuickAccessEntry(
        id: id,
        title: title,
        path: path,
        category: category,
        itemCount: itemCount ?? this.itemCount,
        exists: exists ?? this.exists,
      );
}
