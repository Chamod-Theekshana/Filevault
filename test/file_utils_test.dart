import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileUtils.categoryFor', () {
    test('classifies by extension', () {
      expect(FileUtils.categoryFor('IMG_0001.JPG'), FileCategory.images);
      expect(FileUtils.categoryFor('clip.mkv'), FileCategory.videos);
      expect(FileUtils.categoryFor('song.flac'), FileCategory.audio);
      expect(FileUtils.categoryFor('report.pdf'), FileCategory.documents);
      expect(FileUtils.categoryFor('backup.zip'), FileCategory.archives);
      expect(FileUtils.categoryFor('app.apk'), FileCategory.apks);
      expect(FileUtils.categoryFor('data.bin'), FileCategory.other);
    });

    test('directories are folders', () {
      expect(FileUtils.categoryFor('Download', isDirectory: true), FileCategory.folders);
    });
  });

  group('FileUtils.extensionOf', () {
    test('returns the last extension in lower case', () {
      expect(FileUtils.extensionOf('archive.TAR.GZ'), 'gz');
      expect(FileUtils.extensionOf('noext'), '');
    });
  });

  group('FileUtils.isValidName', () {
    test('rejects separators and reserved names', () {
      expect(FileUtils.isValidName('report.pdf'), isTrue);
      expect(FileUtils.isValidName('a/b'), isFalse);
      expect(FileUtils.isValidName(''), isFalse);
      expect(FileUtils.isValidName('..'), isFalse);
      expect(FileUtils.isValidName('a' * 256), isFalse);
    });
  });

  group('FileUtils.uniqueName', () {
    test('appends an incrementing suffix before the extension', () {
      final Set<String> taken = <String>{'report.pdf', 'report (1).pdf'};
      expect(FileUtils.uniqueName('report.pdf', taken.contains), 'report (2).pdf');
      expect(FileUtils.uniqueName('fresh.pdf', taken.contains), 'fresh.pdf');
    });
  });

  group('FileUtils.isWithin', () {
    test('detects nesting and self', () {
      expect(FileUtils.isWithin('/a/b', '/a/b/c'), isTrue);
      expect(FileUtils.isWithin('/a/b', '/a/b'), isTrue);
      expect(FileUtils.isWithin('/a/b', '/a/bc'), isFalse);
    });
  });

  group('FileUtils.isReadableArchive', () {
    test('accepts the pure-Dart formats only', () {
      expect(FileUtils.isReadableArchive('a.zip'), isTrue);
      expect(FileUtils.isReadableArchive('a.tar.gz'), isTrue);
      expect(FileUtils.isReadableArchive('a.rar'), isFalse);
      expect(FileUtils.isReadableArchive('a.7z'), isFalse);
    });
  });

  group('FileSizeFormatter', () {
    test('formats bytes into human units', () {
      expect(FileSizeFormatter.format(0), '0 B');
      expect(FileSizeFormatter.format(512), '512 B');
      expect(FileSizeFormatter.format(1024), '1 KB');
      expect(FileSizeFormatter.format(1536), '1.5 KB');
      expect(FileSizeFormatter.format(4404019), '4.2 MB');
    });

    test('groups counts with commas', () {
      expect(FileSizeFormatter.count(4280), '4,280');
      expect(FileSizeFormatter.count(999), '999');
      expect(FileSizeFormatter.count(1000000), '1,000,000');
    });

    test('formats durations', () {
      expect(FileSizeFormatter.duration(const Duration(seconds: 12)), '12s');
      expect(FileSizeFormatter.duration(const Duration(seconds: 125)), '2m 05s');
    });
  });
}
