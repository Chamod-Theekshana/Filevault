import 'dart:io';

import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/browser/widgets/file_actions_sheet.dart';
import 'package:filevault/features/browser/widgets/properties_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen image viewer with pinch-zoom, swipe between images and a
/// filmstrip of neighbours.
class ImageViewerView extends ConsumerStatefulWidget {
  const ImageViewerView({
    super.key,
    required this.entries,
    required this.initialIndex,
  });

  final List<FileEntry> entries;
  final int initialIndex;

  @override
  ConsumerState<ImageViewerView> createState() => _ImageViewerViewState();
}

class _ImageViewerViewState extends ConsumerState<ImageViewerView> {
  late PageController _controller;
  late int _index;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _index = widget.entries.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.entries.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  FileEntry get _entry => widget.entries[_index];

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: FvEmptyState(
          icon: Icons.image_not_supported_outlined,
          title: context.l10n.errorNotFound,
          message: context.l10n.noResultsBody,
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            PhotoViewGallery.builder(
              pageController: _controller,
              itemCount: widget.entries.length,
              onPageChanged: (int i) => setState(() => _index = i),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (BuildContext context, ImageChunkEvent? event) =>
                  const Center(child: CircularProgressIndicator()),
              builder: (BuildContext context, int i) => PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(widget.entries[i].path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.entries[i].path),
                onTapUp: (_, _, _) => setState(() => _chromeVisible = !_chromeVisible),
              ),
            ),
            AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Column(
                  children: <Widget>[
                    _TopBar(entry: _entry, onBack: () => Navigator.of(context).maybePop()),
                    const Spacer(),
                    _BottomBar(
                      entry: _entry,
                      index: _index,
                      total: widget.entries.length,
                      entries: widget.entries,
                      onSelect: (int i) {
                        setState(() => _index = i);
                        _controller.jumpToPage(i);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.entry, required this.onBack});

  final FileEntry entry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(top: context.padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall?.copyWith(color: Colors.white),
                ),
                Text(
                  '${FileSizeFormatter.format(entry.size)} • ${DateFormatter.short(entry.modified)}',
                  style: context.texts.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => SharePlus.instance.share(ShareParams(files: <XFile>[XFile(entry.path)])),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => showPropertiesDialog(context, entry),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => showFileActionsSheet(context, ref, entry),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.entry,
    required this.index,
    required this.total,
    required this.entries,
    required this.onSelect,
  });

  final FileEntry entry;
  final int index;
  final int total;
  final List<FileEntry> entries;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: context.padding.bottom + 10, top: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                context.l10n.ofCount(index + 1, total),
                style: context.texts.labelMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (total > 1)
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: total,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int i) {
                  final bool active = i == index;
                  return GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 56 : 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? context.colors.primary : Colors.white24,
                          width: active ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(entries[i].path),
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white10),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
