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

  /// Natural ordering so "file2" sorts before "file10".
  static int _compareNames(String a, String b) {
    final RegExp chunks = RegExp(r'(\d+|\D+)');
    final List<String> pa =
        chunks.allMatches(a.toLowerCase()).map((Match m) => m.group(0)!).toList();
    final List<String> pb =
        chunks.allMatches(b.toLowerCase()).map((Match m) => m.group(0)!).toList();
    final int n = pa.length < pb.length ? pa.length : pb.length;
    for (int i = 0; i < n; i++) {
      final int? na = int.tryParse(pa[i]);
      final int? nb = int.tryParse(pb[i]);
      final int c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }
}
