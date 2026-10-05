import 'dart:io';
import 'dart:typed_data';

import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thumbnail or category tile for a file entry, with the small extension
/// badge from the design ("PDF", "ZIP", "JPG").
class FvThumbnail extends ConsumerWidget {
  const FvThumbnail({
    super.key,
    required this.entry,
    this.size = 44,
    this.radius = 12,
    this.showBadge = true,
    this.fit = BoxFit.cover,
  });

  final FileEntry entry;
  final double size;
  final double radius;
  final bool showBadge;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget base = _content(context, ref);
    if (!showBadge || entry.isDirectory || entry.extension.isEmpty) return base;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          base,
          Positioned(
            right: -2,
            bottom: -2,
            child: _Badge(entry: entry, compact: size < 56),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    if (entry.isDirectory) {
      return FvCategoryTile(
        category: FileCategory.folders,
        icon: Icons.folder_outlined,
        size: size,
        radius: radius,
        iconSize: size * 0.5,
      );
    }
    if (entry.isImage && entry.extension != 'svg') {
      return _frame(
        Image.file(
          File(entry.path),
          cacheWidth: (size * 3).round().clamp(96, 720),
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    if (entry.isVideo) {
      return _AsyncThumb(
        key: ValueKey<String>('v:${entry.path}:${entry.modified.millisecondsSinceEpoch}'),
        load: () => ref.read(thumbnailServiceProvider).video(
              entry.path,
              size: entry.size,
              modified: entry.modified,
            ),
        fallback: _fallback(),
        builder: (Uint8List bytes) => _frame(
          Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.memory(bytes, fit: fit, gaplessPlayback: true),
              Center(
                child: Container(
                  width: size * 0.4,
                  height: size * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: size * 0.28),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (entry.isApk) {
      return _AsyncThumb(
        key: ValueKey<String>('a:${entry.path}:${entry.modified.millisecondsSinceEpoch}'),
        load: () => ref.read(thumbnailServiceProvider).apkIcon(
              entry.path,
              size: entry.size,
              modified: entry.modified,
            ),
        fallback: _fallback(),
        builder: (Uint8List bytes) => FvCategoryTile(
          category: FileCategory.apks,
          size: size,
          radius: radius,
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      );
    }
    return _fallback();
  }

  Widget _frame(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _fallback() {
    return FvCategoryTile(
      category: entry.category,
      icon: _iconFor(entry),
      size: size,
      radius: radius,
      iconSize: size * 0.5,
    );
  }

  static IconData _iconFor(FileEntry e) {
    if (e.isDirectory) return Icons.folder_outlined;
    switch (e.extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return Icons.article_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Icons.slideshow_outlined;
      case 'txt':
      case 'md':
      case 'log':
        return Icons.notes_outlined;
      case 'json':
      case 'xml':
      case 'html':
      case 'dart':
      case 'kt':
      case 'java':
      case 'py':
      case 'js':
      case 'ts':
      case 'sql':
      case 'sh':
        return Icons.code_outlined;
      case 'm4a':
      case 'amr':
      case 'wav':
        return Icons.mic_none_outlined;
      case 'epub':
      case 'mobi':
        return Icons.menu_book_outlined;
      case 'ttf':
      case 'otf':
        return Icons.text_fields_outlined;
      default:
        return CategoryColors.icon(e.category);
    }
  }
}

/// Holds the thumbnail future across rebuilds so lists do not flicker.
class _AsyncThumb extends StatefulWidget {
  const _AsyncThumb({
    super.key,
    required this.load,
    required this.fallback,
    required this.builder,
  });

  final Future<Uint8List?> Function() load;
  final Widget fallback;
  final Widget Function(Uint8List bytes) builder;

  @override
  State<_AsyncThumb> createState() => _AsyncThumbState();
}

class _AsyncThumbState extends State<_AsyncThumb> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snap) {
        final Uint8List? bytes = snap.data;
        if (bytes == null || bytes.isEmpty) return widget.fallback;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.builder(bytes),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.entry, required this.compact});

  final FileEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final Color ink = CategoryColors.ink(b, entry.category);
    final bool onMedia = entry.isImage || entry.isVideo;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 1 : 2),
      decoration: BoxDecoration(
        color: onMedia ? Colors.black.withValues(alpha: 0.65) : ink,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.isDark ? context.colors.surfaceContainerLow : Colors.white,
          width: 1.5,
        ),
      ),
      child: Text(
        FileUtils.badge(entry),
        style: context.texts.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: compact ? 8 : 9,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      ),
    );
  }
}
