import 'package:filevault/domain/models/file_entry.dart';

enum SortField { name, size, date, type }

enum SortDirection { asc, desc }

enum ViewMode { list, grid }

/// How a listing is ordered. Folders can be pinned to the top regardless of
/// the active field.
class SortSpec {
  const SortSpec({
    this.field = SortField.name,
    this.direction = SortDirection.asc,
    this.foldersFirst = true,
  });

  final SortField field;
  final SortDirection direction;
  final bool foldersFirst;

  SortSpec copyWith({
    SortField? field,
    SortDirection? direction,
    bool? foldersFirst,
  }) {
    return SortSpec(
      field: field ?? this.field,
      direction: direction ?? this.direction,
      foldersFirst: foldersFirst ?? this.foldersFirst,
    );
  }

  static SortSpec fromNames(String field, String direction, bool foldersFirst) {
    return SortSpec(
      field: SortField.values.firstWhere((SortField f) => f.name == field,
          orElse: () => SortField.name),
      direction: direction == 'desc' ? SortDirection.desc : SortDirection.asc,
      foldersFirst: foldersFirst,
    );
  }

  /// Returns a new sorted list; never mutates [entries].
  List<FileEntry> apply(List<FileEntry> entries) {
    final List<FileEntry> out = List<FileEntry>.of(entries);
    out.sort(compare);
    return out;
  }

  int compare(FileEntry a, FileEntry b) {
    if (foldersFirst && a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }
    int result = switch (field) {
      SortField.name => _compareNames(a.name, b.name),
      SortField.size => a.size.compareTo(b.size),
      SortField.date => a.modified.compareTo(b.modified),
      SortField.type => _compareTypes(a, b),
    };
    if (result == 0 && field != SortField.name) {
      result = _compareNames(a.name, b.name);
    }
    return direction == SortDirection.asc ? result : -result;
  }

  static int _compareTypes(FileEntry a, FileEntry b) {
    final int byCategory = a.category.index.compareTo(b.category.index);
    if (byCategory != 0) return byCategory;
    return a.extension.compareTo(b.extension);
  }

  /// Natural ordering so "file2" sorts before "file10". Implemented as a
  /// single allocation-light scan (no RegExp) because it runs O(n log n)
  /// times when sorting folders with thousands of entries.
  static int _compareNames(String a, String b) => naturalCompare(a, b);

  static bool _isDigit(int c) => c >= 48 && c <= 57;

  static int naturalCompare(String a, String b) {
    final String x = a.toLowerCase();
    final String y = b.toLowerCase();
    int i = 0;
    int j = 0;
    while (i < x.length && j < y.length) {
      final int cx = x.codeUnitAt(i);
      final int cy = y.codeUnitAt(j);
      if (_isDigit(cx) && _isDigit(cy)) {
        int si = i;
        while (si < x.length && x.codeUnitAt(si) == 48) {
          si++;
        }
        int sj = j;
        while (sj < y.length && y.codeUnitAt(sj) == 48) {
          sj++;
        }
        int ei = si;
        while (ei < x.length && _isDigit(x.codeUnitAt(ei))) {
          ei++;
        }
        int ej = sj;
        while (ej < y.length && _isDigit(y.codeUnitAt(ej))) {
          ej++;
        }
        final int lenX = ei - si;
        final int lenY = ej - sj;
        if (lenX != lenY) return lenX < lenY ? -1 : 1;
        for (int k = 0; k < lenX; k++) {
          final int d = x.codeUnitAt(si + k) - y.codeUnitAt(sj + k);
          if (d != 0) return d < 0 ? -1 : 1;
        }
        final int runX = ei - i;
        final int runY = ej - j;
        if (runX != runY) return runX < runY ? -1 : 1;
        i = ei;
        j = ej;
      } else {
        if (cx != cy) return cx < cy ? -1 : 1;
        i++;
        j++;
      }
    }
    final int restX = x.length - i;
    final int restY = y.length - j;
    if (restX == restY) return 0;
    return restX < restY ? -1 : 1;
  }
}
