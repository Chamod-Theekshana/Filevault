import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ClipboardMode { copy, cut }

/// Files waiting to be pasted. Lives across navigation so the user can pick
/// items, walk to any folder and paste them there – the classic file-manager
/// workflow.
class FileClipboardState {
  const FileClipboardState({required this.paths, required this.mode});

  final List<String> paths;
  final ClipboardMode mode;

  bool get isCut => mode == ClipboardMode.cut;
}

final NotifierProvider<FileClipboard, FileClipboardState?> fileClipboardProvider =
    NotifierProvider<FileClipboard, FileClipboardState?>(FileClipboard.new);

class FileClipboard extends Notifier<FileClipboardState?> {
  @override
  FileClipboardState? build() => null;

  void copy(List<String> paths) {
    if (paths.isEmpty) return;
    state = FileClipboardState(paths: List<String>.unmodifiable(paths), mode: ClipboardMode.copy);
  }

  void cut(List<String> paths) {
    if (paths.isEmpty) return;
    state = FileClipboardState(paths: List<String>.unmodifiable(paths), mode: ClipboardMode.cut);
  }

  void clear() => state = null;
}
