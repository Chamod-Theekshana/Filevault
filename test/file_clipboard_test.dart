import 'package:filevault/features/operations/file_clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copy, cut and clear', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final FileClipboard clipboard = container.read(fileClipboardProvider.notifier);

    expect(container.read(fileClipboardProvider), isNull);

    clipboard.copy(<String>['/a', '/b']);
    expect(container.read(fileClipboardProvider)!.isCut, isFalse);
    expect(container.read(fileClipboardProvider)!.paths, <String>['/a', '/b']);

    clipboard.cut(<String>['/c']);
    expect(container.read(fileClipboardProvider)!.isCut, isTrue);

    clipboard.clear();
    expect(container.read(fileClipboardProvider), isNull);
  });

  test('empty selections are ignored', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(fileClipboardProvider.notifier).copy(<String>[]);
    expect(container.read(fileClipboardProvider), isNull);
  });
}
