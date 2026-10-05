import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

/// Opens [entry] with the built-in viewer when FileVault can render it,
/// otherwise hands it to another app. Also records it in "recent files".
Future<void> openFileEntry(
  BuildContext context,
  WidgetRef ref,
  FileEntry entry, {
  List<FileEntry> siblings = const <FileEntry>[],
}) async {
  if (entry.isDirectory) {
    context.push(AppRoutes.withPath(AppRoutes.browse, entry.path));
    return;
  }
  await ref.read(collectionsRepositoryProvider).recordOpened(entry);
  if (!context.mounted) return;

  if (entry.isImage) {
    final List<FileEntry> images =
        siblings.where((FileEntry e) => e.isImage).toList(growable: false);
    final int index = images.indexWhere((FileEntry e) => e.path == entry.path);
    context.push(
      AppRoutes.withPath(AppRoutes.imageViewer, entry.path),
      extra: <String, Object?>{
        'siblings': images.isEmpty ? <FileEntry>[entry] : images,
        'index': index < 0 ? 0 : index,
      },
    );
    return;
  }
  if (entry.isVideo) {
    context.push(AppRoutes.withPath(AppRoutes.videoViewer, entry.path));
    return;
  }
  if (entry.isAudio) {
    final List<FileEntry> tracks =
        siblings.where((FileEntry e) => e.isAudio).toList(growable: false);
    context.push(
      AppRoutes.withPath(AppRoutes.audioPlayer, entry.path),
      extra: <String, Object?>{'queue': tracks.isEmpty ? <FileEntry>[entry] : tracks},
    );
    return;
  }
  if (FileUtils.isPdf(entry)) {
    context.push(AppRoutes.withPath(AppRoutes.pdfViewer, entry.path));
    return;
  }
  if (entry.isApk) {
    context.push(AppRoutes.withPath(AppRoutes.apkInfo, entry.path));
    return;
  }
  if (entry.isArchive && ref.read(archiveRepositoryProvider).canOpen(entry.path)) {
    context.push(AppRoutes.withPath(AppRoutes.archive, entry.path));
    return;
  }
  if (FileUtils.isTextLike(entry)) {
    context.push(AppRoutes.withPath(AppRoutes.textEditor, entry.path));
    return;
  }
  await openWithExternalApp(context, entry);
}

/// Hands the file to another installed app.
Future<void> openWithExternalApp(BuildContext context, FileEntry entry) async {
  final OpenResult result = await OpenFilex.open(entry.path, type: entry.mimeType);
  if (!context.mounted) return;
  if (result.type != ResultType.done) {
    context.showSnack(
      result.type == ResultType.noAppToOpen
          ? context.l10n.noAppToOpen
          : context.l10n.somethingWentWrong,
    );
  }
}
