import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

/// PDF viewer with page navigation.
class PdfViewerView extends StatefulWidget {
  const PdfViewerView({super.key, required this.path});

  final String path;

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  late final PdfControllerPinch _controller =
      PdfControllerPinch(document: PdfDocument.openFile(widget.path));
  int _page = 1;
  int _pages = 0;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: p.basename(widget.path),
        subtitle: _pages == 0 ? null : context.l10n.pageOf(_page, _pages),
        actions: <Widget>[
          FvIconButton(
            icon: Icons.share_outlined,
            tooltip: context.l10n.share,
            onPressed: () =>
                SharePlus.instance.share(ShareParams(files: <XFile>[XFile(widget.path)])),
          ),
        ],
      ),
      body: _failed
          ? FvEmptyState(
              icon: Icons.picture_as_pdf_outlined,
              title: context.l10n.cannotPlay,
              message: context.l10n.noAppToOpen,
            )
          : PdfViewPinch(
              controller: _controller,
              onDocumentLoaded: (PdfDocument doc) => setState(() => _pages = doc.pagesCount),
              onPageChanged: (int page) => setState(() => _page = page),
              onDocumentError: (_) => setState(() => _failed = true),
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
              ),
            ),
      bottomNavigationBar: _pages <= 1 || _failed
          ? null
          : Material(
              color: context.isDark ? context.colors.surfaceContainer : context.colors.surfaceContainerLowest,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.tokens.cardBorder)),
                ),
                padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + context.padding.bottom),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page <= 1 ? null : () => _controller.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _page.toDouble().clamp(1.0, _pages.toDouble()),
                        min: 1,
                        max: _pages.toDouble(),
                        divisions: _pages > 1 ? _pages - 1 : null,
                        label: '$_page',
                        onChanged: (double v) => _controller.jumpToPage(v.round()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page >= _pages ? null : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
