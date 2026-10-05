import 'dart:io';

import 'package:filevault/data/services/archive_service.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  const ArchiveService service = ArchiveService();

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('fv_archive_test');
    await Directory(p.join(temp.path, 'src', 'nested')).create(recursive: true);
    await File(p.join(temp.path, 'src', 'one.txt')).writeAsString('hello');
    await File(p.join(temp.path, 'src', 'nested', 'two.txt')).writeAsString('world!!');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('canOpen accepts supported formats only', () {
    expect(service.canOpen('a.zip'), isTrue);
    expect(service.canOpen('a.tar'), isTrue);
    expect(service.canOpen('a.rar'), isFalse);
  });

  test('creates a zip, lists it and extracts everything back', () async {
    final String archive = p.join(temp.path, 'out.zip');
    await service.create(archive, <String>[p.join(temp.path, 'src')]);
    expect(File(archive).existsSync(), isTrue);

    final List<ArchiveEntryInfo> entries = await service.listEntries(archive);
    final Set<String> paths = entries.map((ArchiveEntryInfo e) => e.path).toSet();
    expect(paths.contains('src/one.txt'), isTrue);
    expect(paths.contains('src/nested/two.txt'), isTrue);
    expect(entries.any((ArchiveEntryInfo e) => e.isDirectory && e.path == 'src'), isTrue);

    final String dest = p.join(temp.path, 'out');
    final int written = await service.extract(archive, dest);
    expect(written, 2);
    expect(await File(p.join(dest, 'src', 'one.txt')).readAsString(), 'hello');
    expect(await File(p.join(dest, 'src', 'nested', 'two.txt')).readAsString(), 'world!!');
  });

  test('extracts only the selected entries', () async {
    final String archive = p.join(temp.path, 'sel.zip');
    await service.create(archive, <String>[p.join(temp.path, 'src')]);
    final String dest = p.join(temp.path, 'partial');
    final int written =
        await service.extract(archive, dest, entryPaths: <String>['src/one.txt']);
    expect(written, 1);
    expect(File(p.join(dest, 'src', 'one.txt')).existsSync(), isTrue);
    expect(File(p.join(dest, 'src', 'nested', 'two.txt')).existsSync(), isFalse);
  });

  test('tar.gz round trips', () async {
    final String archive = p.join(temp.path, 'out.tar.gz');
    await service.create(
      archive,
      <String>[p.join(temp.path, 'src')],
      format: ArchiveFormat.tarGz,
    );
    final List<ArchiveEntryInfo> entries = await service.listEntries(archive);
    expect(entries.any((ArchiveEntryInfo e) => e.path == 'src/one.txt'), isTrue);

    final String dest = p.join(temp.path, 'tgz-out');
    await service.extract(archive, dest);
    expect(await File(p.join(dest, 'src', 'one.txt')).readAsString(), 'hello');
  });

  test('reports progress while creating', () async {
    final List<double> ticks = <double>[];
    await service.create(
      p.join(temp.path, 'progress.zip'),
      <String>[p.join(temp.path, 'src')],
      onProgress: (double f, String? _) => ticks.add(f),
    );
    expect(ticks, isNotEmpty);
    expect(ticks.last, closeTo(1, 0.001));
  });
}
