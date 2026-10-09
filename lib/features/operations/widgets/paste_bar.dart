import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/features/operations/file_clipboard.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:flutter/material.dart';

/// Bottom bar shown in a folder while files are waiting to be pasted.
class PasteBar extends StatelessWidget {
  const PasteBar({
    super.key,
    required this.clipboard,
    required this.onPaste,
    required this.onCancel,
  });

  final FileClipboardState clipboard;
  final VoidCallback onPaste;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final int n = clipboard.paths.length;
    return ReserveBottomSpace(
      height: 66,
      child: Material(
      color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.tokens.cardBorder))),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: SafeArea(
          top: false,
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.tokens.tonal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  clipboard.isCut ? Icons.content_cut_rounded : Icons.content_copy_rounded,
                  size: 18,
                  color: context.tokens.onTonal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      clipboard.isCut ? context.l10n.readyToMove(n) : context.l10n.readyToCopy(n),
                      style: context.texts.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l10n.pasteHint,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                tooltip: context.l10n.cancel,
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FilledButton.icon(
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: Text(context.l10n.pasteHere, maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 42)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
