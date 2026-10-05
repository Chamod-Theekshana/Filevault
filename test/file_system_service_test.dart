import 'dart:io';

import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/repositories/file_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  const FileSystemService fs = FileSystemService();

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fv_fs_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('lists visible entries and hides dotfiles by default', () async {
    await File(p.join(temp.path, 'a.txt')).writeAsString('a');
    await File(p.join(temp.path, '.hidden')).writeAsString('h');
    await Directory(p.join(temp.path, 'sub')).create();

    final List<FileEntry> visible = <FileEntry>[];
    await for (final List<FileEntry> batch in fs.list(temp.path, showHidden: false)) {
      visible.addAll(batch);
    }
    expect(visible.map((FileEntry e) => e.name).toSet(), <String>{'a.txt', 'sub'});

    final List<FileEntry> all = <FileEntry>[];
    await for (final List<FileEntry> batch in fs.list(temp.path, showHidden: true)) {
      all.addAll(batch);
    }
    expect(all.length, 3);
    expect(all.firstWhere((FileEntry e) => e.name == '.hidden').isHidden, isTrue);
  });

  test('listing a missing folder reports NotFoundFailure', () async {
    expect(
      () async {
        await for (final _ in fs.list(p.join(temp.path, 'nope'), showHidden: false)) {}
      },
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('createFolder refuses duplicates and invalid names', () async {
    await fs.createFolder(temp.path, 'docs');
    expect(Directory(p.join(temp.path, 'docs')).existsSync(), isTrue);
    expect(() => fs.createFolder(temp.path, 'docs'), throwsA(isA<AlreadyExistsFailure>()));
    expect(() => fs.createFolder(temp.path, 'bad/name'), throwsA(isA<InvalidNameFailure>()));
  });

  test('rename moves the entry and keeps its contents', () async {
    final File file = File(p.join(temp.path, 'old.txt'));
    await file.writeAsString('payload');
    final FileEntry renamed = await fs.rename(file.path, 'new.txt');
    expect(renamed.name, 'new.txt');
    expect(await File(renamed.path).readAsString(), 'payload');
    expect(file.existsSync(), isFalse);
  });

  test('duplicate creates a "(1)" copy', () async {
    final File file = File(p.join(temp.path, 'note.txt'));
    await file.writeAsString('x');
    final FileEntry copy = await fs.duplicate(file.path);
    expect(p.basename(copy.path), 'note (1).txt');
    expect(await File(copy.path).readAsString(), 'x');
  });

  test('copyFile streams the whole file and reports bytes', () async {
    final File source = File(p.join(temp.path, 'big.bin'));
    await source.writeAsBytes(List<int>.generate(200000, (int i) => i % 256));
    final String target = p.join(temp.path, 'copy.bin');
    int reported = 0;
    await fs.copyFile(source.path, target, onBytes: (int n) => reported += n);
    expect(await File(target).length(), 200000);
    expect(reported, 200000);
  });

  test('flatten returns every nested file', () async {
    await Directory(p.join(temp.path, 'a', 'b')).create(recursive: true);
    await File(p.join(temp.path, 'a', 'one.txt')).writeAsString('1');
    await File(p.join(temp.path, 'a', 'b', 'two.txt')).writeAsString('22');
    final List<FileEntry> files = await fs.flatten(p.join(temp.path, 'a'));
    expect(files.length, 2);
    expect(files.fold<int>(0, (int a, FileEntry e) => a + e.size), 3);
  });

  test('directoryStats counts files, folders and bytes', () async {
    await Directory(p.join(temp.path, 'x', 'y')).create(recursive: true);
    await File(p.join(temp.path, 'x', 'one.txt')).writeAsString('abc');
    await File(p.join(temp.path, 'x', 'y', 'two.txt')).writeAsString('de');
    final DirectoryStats stats = await fs.directoryStats(p.join(temp.path, 'x'));
    expect(stats.files, 2);
    expect(stats.folders, 1);
    expect(stats.bytes, 5);
  });

  test('computeHash matches a known SHA-256', () async {
    final File file = File(p.join(temp.path, 'hash.txt'));
    await file.writeAsString('abc');
    final String digest = await fs.computeHash(file.path, HashAlgorithm.sha256);
    expect(digest, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('readText detects UTF-8 and writeText round trips', () async {
    final String path = p.join(temp.path, 'text.txt');
    await fs.writeText(path, 'héllo wörld');
    final doc = await fs.readText(path);
    expect(doc.encoding, 'UTF-8');
    expect(doc.content, 'héllo wörld');
  });

  test('sameVolume distinguishes internal storage from an SD card', () {
    expect(
      FileSystemService.sameVolume('/storage/emulated/0/a', '/storage/emulated/0/b/c'),
      isTrue,
    );
    expect(
      FileSystemService.sameVolume('/storage/emulated/0/a', '/storage/1A2B-3C4D/x'),
      isFalse,
    );
  });
}
