import 'dart:collection';

import 'package:filevault/domain/models/file_entry.dart';

/// Small in-memory LRU of recent folder listings.
///
/// Going back to a folder (or re-opening one from the breadcrumbs) paints the
/// last known listing instantly while a fresh listing runs in the background
/// – the "stale while revalidate" pattern used by fast file managers.
class DirectoryCache {
  DirectoryCache({this.capacity = 32});

  final int capacity;
  final LinkedHashMap<String, List<FileEntry>> _entries =
      LinkedHashMap<String, List<FileEntry>>();

  static String _key(String path, bool showHidden) => '${showHidden ? 1 : 0}|$path';

  List<FileEntry>? get(String path, {required bool showHidden}) {
    final String key = _key(path, showHidden);
    final List<FileEntry>? hit = _entries.remove(key);
    if (hit == null) return null;
    _entries[key] = hit; // move to most-recently-used position
    return hit;
  }

  void put(String path, List<FileEntry> entries, {required bool showHidden}) {
    final String key = _key(path, showHidden);
    _entries.remove(key);
    _entries[key] = List<FileEntry>.unmodifiable(entries);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Drops [path] (both hidden-file variants).
  void invalidate(String path) {
    _entries.remove(_key(path, true));
    _entries.remove(_key(path, false));
  }

  void clear() => _entries.clear();
}
