import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../../core/utils/file_utils.dart';
import '../models/conflict_resolution.dart';

class ConflictDialog extends StatefulWidget {
  final String conflictFilePath;
  final void Function(ConflictResolution resolution, bool applyAll) onResolve;

  const ConflictDialog({
    super.key,
    required this.conflictFilePath,
    required this.onResolve,
  });

  @override
  State<ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<ConflictDialog> {
  bool _applyAll = false;
  FileStat? _existingStat;
  FileStat? _newStat; // Typically we don't have new stat if it's coming from stream, but let's assume we can get it if it's a direct copy. We'll leave it simple for now.

  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    final stat = await FileStat.stat(widget.conflictFilePath);
    setState(() {
      _existingStat = stat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fileName = p.basename(widget.conflictFilePath);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(Icons.drive_file_rename_outline, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 16),
            Text('File already exists', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'A file named '),
                  TextSpan(text: fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' already exists in this folder.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats comparison
            if (_existingStat != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Existing size:', style: TextStyle(fontSize: 12)),
                        Text(FileUtils.formatBytes(_existingStat!.size, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Existing date:', style: TextStyle(fontSize: 12)),
                        Text(DateFormat('MMM d, yyyy HH:mm').format(_existingStat!.modified), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 16),
            
            // Checkbox
            CheckboxListTile(
              value: _applyAll,
              onChanged: (val) {
                setState(() => _applyAll = val ?? false);
              },
              title: const Text('Apply to remaining conflicts', style: TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            
            const SizedBox(height: 16),
            
            // Buttons
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onResolve(ConflictResolution.replace, _applyAll);
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Replace existing'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onResolve(ConflictResolution.keepBoth, _applyAll);
                    },
                    icon: const Icon(Icons.copy_all, size: 18),
                    label: const Text('Keep both', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onResolve(ConflictResolution.skip, _applyAll);
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: const Text('Skip file', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
