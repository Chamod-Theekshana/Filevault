import 'package:filevault/data/services/directory_cache.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter_test/flutter_test.dart';

FileEntry _e(String name) => FileEntry(
      path: '/storage/emulated/0/$name',
      name: name,
      isDirectory: false,
      size: 1,
      modified: DateTime(2025),
      category: FileCategory.other,
    );

void main() {
  test('returns what was stored, per hidden-files mode', () {
    final DirectoryCache cache = DirectoryCache();
    cache.put('/a', <FileEntry>[_e('x')], showHidden: false);
    expect(cache.get('/a', showHidden: false)!.single.name, 'x');
    expect(cache.get('/a', showHidden: true), isNull);
  });

  test('evicts the least recently used folder', () {
    final DirectoryCache cache = DirectoryCache(capacity: 2);
    cache.put('/a', <FileEntry>[_e('a')], showHidden: false);
    cache.put('/b', <FileEntry>[_e('b')], showHidden: false);
    cache.get('/a', showHidden: false); // touch /a
    cache.put('/c', <FileEntry>[_e('c')], showHidden: false);
    expect(cache.get('/b', showHidden: false), isNull);
    expect(cache.get('/a', showHidden: false), isNotNull);
    expect(cache.get('/c', showHidden: false), isNotNull);
  });

  test('invalidate drops both variants', () {
    final DirectoryCache cache = DirectoryCache();
    cache.put('/a', <FileEntry>[_e('a')], showHidden: false);
    cache.put('/a', <FileEntry>[_e('a')], showHidden: true);
    cache.invalidate('/a');
    expect(cache.get('/a', showHidden: false), isNull);
    expect(cache.get('/a', showHidden: true), isNull);
  });
}
