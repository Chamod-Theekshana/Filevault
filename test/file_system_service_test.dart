import 'dart:io';

import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
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

  test('copyFile handles large files in slices and reports every byte', () async {
    final File source = File(p.join(temp.path, 'large.bin'));
    const int size = FileSystemService.nativeCopyThreshold + 3 * 1024 * 1024 + 17;
    final RandomAccessFile raf = await source.open(mode: FileMode.write);
    await raf.truncate(size);
    await raf.setPosition(size - 1);
    await raf.writeByte(42);
    await raf.close();
    final String target = p.join(temp.path, 'large-copy.bin');
    int reported = 0;
    await fs.copyFile(source.path, target, onBytes: (int n) => reported += n);
    expect(await File(target).length(), size);
    expect(reported, size);
    final RandomAccessFile check = await File(target).open();
    await check.setPosition(size - 1);
    expect(await check.readByte(), 42);
    await check.close();
  });

  test('a cancelled copy leaves no partial file behind', () async {
    final File source = File(p.join(temp.path, 'cancel.bin'));
    final RandomAccessFile raf = await source.open(mode: FileMode.write);
    await raf.truncate(FileSystemService.nativeCopyThreshold + 1024);
    await raf.close();
    final String target = p.join(temp.path, 'cancel-copy.bin');
    final CancelToken token = CancelToken();
    await expectLater(
      fs.copyFile(source.path, target, onBytes: (_) => token.cancel(), cancelToken: token),
      throwsA(isA<CancelledFailure>()),
    );
    expect(File(target).existsSync(), isFalse);
  });

  test('childCounts and existing work in one pass', () async {
    await Directory(p.join(temp.path, 'one')).create();
    await File(p.join(temp.path, 'one', 'a.txt')).writeAsString('a');
    await File(p.join(temp.path, 'one', '.hidden')).writeAsString('h');
    await Directory(p.join(temp.path, 'two')).create();
    final Map<String, int> counts = await fs.childCounts(
      <String>[p.join(temp.path, 'one'), p.join(temp.path, 'two')],
      showHidden: false,
    );
    expect(counts[p.join(temp.path, 'one')], 1);
    expect(counts[p.join(temp.path, 'two')], 0);
    final Set<String> present = await fs.existing(
      <String>[p.join(temp.path, 'one'), p.join(temp.path, 'missing')],
    );
    expect(present, <String>{p.join(temp.path, 'one')});
  });

  test('setNoMedia adds and removes the marker', () async {
    final String folder = p.join(temp.path, 'private');
    await Directory(folder).create();
    await File(p.join(folder, 'photo.jpg')).writeAsString('x');
    final List<String> files = await fs.setNoMedia(folder, hidden: true);
    expect(File(p.join(folder, '.nomedia')).existsSync(), isTrue);
    expect(files, <String>[p.join(folder, 'photo.jpg')]);
    await fs.setNoMedia(folder, hidden: false);
    expect(File(p.join(folder, '.nomedia')).existsSync(), isFalse);
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
