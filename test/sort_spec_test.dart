import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:flutter_test/flutter_test.dart';

FileEntry entry(
  String name, {
  bool dir = false,
  int size = 0,
  int day = 1,
  FileCategory category = FileCategory.other,
}) {
  return FileEntry(
    path: '/storage/emulated/0/$name',
    name: name,
    isDirectory: dir,
    size: size,
    modified: DateTime(2024, 1, day),
    category: dir ? FileCategory.folders : category,
  );
}

void main() {
  group('SortSpec', () {
    final List<FileEntry> entries = <FileEntry>[
      entry('file10.txt', size: 300, day: 3),
      entry('Alpha', dir: true, day: 5),
      entry('file2.txt', size: 100, day: 1),
      entry('beta.zip', size: 900, day: 2, category: FileCategory.archives),
    ];

    test('puts folders first by default', () {
      final List<FileEntry> sorted = const SortSpec().apply(entries);
      expect(sorted.first.isDirectory, isTrue);
    });

    test('sorts names naturally so file2 precedes file10', () {
      final List<FileEntry> sorted = const SortSpec().apply(entries);
      final List<String> names =
          sorted.where((FileEntry e) => !e.isDirectory).map((FileEntry e) => e.name).toList();
      expect(names.indexOf('file2.txt'), lessThan(names.indexOf('file10.txt')));
    });

    test('sorts by size descending', () {
      final List<FileEntry> sorted = const SortSpec(
        field: SortField.size,
        direction: SortDirection.desc,
        foldersFirst: false,
      ).apply(entries);
      expect(sorted.first.name, 'beta.zip');
      expect(sorted.last.name, 'Alpha');
    });

    test('sorts by date ascending', () {
      final List<FileEntry> sorted = const SortSpec(
        field: SortField.date,
        foldersFirst: false,
      ).apply(entries);
      expect(sorted.first.name, 'file2.txt');
      expect(sorted.last.name, 'Alpha');
    });

    test('does not mutate the input list', () {
      final List<FileEntry> input = List<FileEntry>.of(entries);
      const SortSpec(field: SortField.size).apply(input);
      expect(input.first.name, entries.first.name);
    });
  });
}
