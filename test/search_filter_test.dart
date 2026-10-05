import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/search_models.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchFilter', () {
    test('default filter is inert', () {
      const SearchFilter filter = SearchFilter();
      expect(filter.isDefault, isTrue);
      expect(filter.activeCount, 0);
      expect(filter.minBytes, isNull);
      expect(filter.maxBytes, isNull);
      expect(filter.since(), isNull);
    });

    test('size buckets map to byte bounds', () {
      expect(const SearchFilter(size: SizeBucket.small).maxBytes, 1024 * 1024);
      expect(const SearchFilter(size: SizeBucket.medium).minBytes, 1024 * 1024);
      expect(const SearchFilter(size: SizeBucket.large).minBytes, 100 * 1024 * 1024);
      expect(const SearchFilter(size: SizeBucket.large).maxBytes, isNull);
    });

    test('date buckets map to a cutoff', () {
      final DateTime now = DateTime(2024, 6, 15);
      expect(
        const SearchFilter(date: DateBucket.week).since(now: now),
        DateTime(2024, 6, 8),
      );
      expect(const SearchFilter(date: DateBucket.year).since(now: now), DateTime(2024));
    });

    test('clearCategory wins over a passed category', () {
      const SearchFilter filter = SearchFilter(category: FileCategory.images);
      expect(filter.copyWith(clearCategory: true).category, isNull);
      expect(filter.copyWith(category: FileCategory.videos).category, FileCategory.videos);
    });
  });

  group('SearchHit', () {
    test('locates the matched range case-insensitively', () {
      final FileEntry entry = FileEntry(
        path: '/a/Quarterly_Report_Q3.pdf',
        name: 'Quarterly_Report_Q3.pdf',
        isDirectory: false,
        size: 10,
        modified: DateTime(2024),
        category: FileCategory.documents,
      );
      final SearchHit hit = SearchHit.forQuery(entry, 'report');
      expect(entry.name.substring(hit.matchStart, hit.matchEnd), 'Report');
    });

    test('falls back to a zero range when there is no match', () {
      final FileEntry entry = FileEntry(
        path: '/a/x.txt',
        name: 'x.txt',
        isDirectory: false,
        size: 1,
        modified: DateTime(2024),
        category: FileCategory.documents,
      );
      final SearchHit hit = SearchHit.forQuery(entry, 'zzz');
      expect(hit.matchStart, 0);
      expect(hit.matchEnd, 0);
    });
  });

  group('TrashItem expiry', () {
    TrashItem item(int ageDays) => TrashItem(
          id: 1,
          originalPath: '/a/b.txt',
          trashPath: '/a/.filevault_trash/b.txt',
          name: 'b.txt',
          size: 100,
          isDirectory: false,
          deletedAt: DateTime(2024, 6, 1).subtract(Duration(days: -ageDays)),
          category: FileCategory.documents,
        );

    test('counts the days left before auto-purge', () {
      final TrashItem trashed = TrashItem(
        id: 1,
        originalPath: '/a/b.txt',
        trashPath: '/t/b.txt',
        name: 'b.txt',
        size: 1,
        isDirectory: false,
        deletedAt: DateTime(2024, 6, 1),
        category: FileCategory.documents,
      );
      expect(trashed.daysLeft(30, now: DateTime(2024, 6, 4)), 27);
      expect(trashed.isExpired(30, now: DateTime(2024, 6, 4)), isFalse);
      expect(trashed.isExpired(30, now: DateTime(2024, 7, 4)), isTrue);
    });

    test('auto-purge disabled means no expiry', () {
      expect(item(0).daysLeft(0), isNull);
      expect(item(0).isExpired(0), isFalse);
    });
  });
}
