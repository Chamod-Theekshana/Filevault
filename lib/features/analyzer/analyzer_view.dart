import 'dart:math' as math;

import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/analyzer_models.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyzerState {
  const AnalyzerState({
    this.breakdown,
    this.loading = true,
    this.progress = 0,
    this.largeFilesCount = 0,
    this.largeFilesBytes = 0,
    this.duplicateCount = 0,
    this.duplicateBytes = 0,
    this.junkBytes = 0,
    this.junkCount = 0,
    this.emptyFolders = 0,
    this.scannedTools = false,
  });

  final StorageBreakdown? breakdown;
  final bool loading;
  final double progress;
  final int largeFilesCount;
  final int largeFilesBytes;
  final int duplicateCount;
  final int duplicateBytes;
  final int junkBytes;
  final int junkCount;
  final int emptyFolders;

  /// True once duplicates/junk have been scanned at least once.
  final bool scannedTools;

  int get recoverableBytes => largeFilesBytes + duplicateBytes + junkBytes;

  AnalyzerState copyWith({
    StorageBreakdown? breakdown,
    bool? loading,
    double? progress,
    int? largeFilesCount,
    int? largeFilesBytes,
    int? duplicateCount,
    int? duplicateBytes,
    int? junkBytes,
    int? junkCount,
    int? emptyFolders,
    bool? scannedTools,
  }) {
    return AnalyzerState(
      breakdown: breakdown ?? this.breakdown,
      loading: loading ?? this.loading,
      progress: progress ?? this.progress,
      largeFilesCount: largeFilesCount ?? this.largeFilesCount,
      largeFilesBytes: largeFilesBytes ?? this.largeFilesBytes,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      duplicateBytes: duplicateBytes ?? this.duplicateBytes,
      junkBytes: junkBytes ?? this.junkBytes,
      junkCount: junkCount ?? this.junkCount,
      emptyFolders: emptyFolders ?? this.emptyFolders,
      scannedTools: scannedTools ?? this.scannedTools,
    );
  }
}

final AutoDisposeNotifierProvider<AnalyzerViewModel, AnalyzerState>
analyzerProvider =
    NotifierProvider.autoDispose<AnalyzerViewModel, AnalyzerState>(
      AnalyzerViewModel.new,
    );

class AnalyzerViewModel extends AutoDisposeNotifier<AnalyzerState> {
  bool _disposed = false;
  final CancelToken _cancel = CancelToken();

  @override
  AnalyzerState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancel.cancel();
    });
    Future<void>.microtask(load);
    return const AnalyzerState();
  }

  /// Writes [next] only while the provider is still alive – these scans
  /// outlive the screen when the user navigates away mid-run.
  void _set(AnalyzerState next) {
    if (_disposed) return;
    state = next;
  }

  Future<void> load() async {
    if (_disposed) return;
    _set(state.copyWith(loading: true, progress: 0));
    final StorageBreakdown breakdown = await ref
        .read(analyzerRepositoryProvider)
        .breakdown(
          cancelToken: _cancel,
          onProgress: (double f, String? _) =>
              _set(state.copyWith(progress: f)),
        );
    if (_disposed) return;
    final List<FileEntry> large = await ref
        .read(analyzerRepositoryProvider)
        .largeFiles();
    _set(
      state.copyWith(
        breakdown: breakdown,
        loading: false,
        progress: 1,
        largeFilesCount: large.length,
        largeFilesBytes: large.fold<int>(0, (int a, FileEntry e) => a + e.size),
      ),
    );
  }

  Future<void> scanTools() async {
    if (_disposed) return;
    _set(state.copyWith(loading: true, progress: 0));
    final List<DuplicateGroup> dups = await ref
        .read(analyzerRepositoryProvider)
        .findDuplicates(
          cancelToken: _cancel,
          onProgress: (double f, String? _) =>
              _set(state.copyWith(progress: f * 0.6)),
        );
    if (_disposed) return;
    final JunkReport junk = await ref
        .read(analyzerRepositoryProvider)
        .scanJunk(
          cancelToken: _cancel,
          onProgress: (double f, String? _) =>
              _set(state.copyWith(progress: 0.6 + f * 0.4)),
        );
    _set(
      state.copyWith(
        loading: false,
        progress: 1,
        duplicateCount: dups.fold<int>(0, (a, g) => a + g.files.length - 1),
        duplicateBytes: dups.fold<int>(0, (a, g) => a + g.wastedBytes),
        junkBytes: junk.junkFiles.fold<int>(0, (a, i) => a + i.bytes),
        junkCount: junk.junkFiles.length,
        emptyFolders: junk.emptyFolders.length,
        scannedTools: true,
      ),
    );
  }

  Future<void> rebuildIndex() async {
    if (_disposed) return;
    _set(state.copyWith(loading: true, progress: 0));
    await ref
        .read(indexRepositoryProvider)
        .rebuild(
          includeHidden: ref.read(settingsProvider).showHiddenFiles,
          cancelToken: _cancel,
          onProgress: (double f, String? _) =>
              _set(state.copyWith(progress: f)),
        );
    if (_disposed) return;
    await load();
  }
}

/// Storage breakdown + optimization tools.
class AnalyzerView extends ConsumerWidget {
  const AnalyzerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyzerState state = ref.watch(analyzerProvider);
    final AnalyzerViewModel vm = ref.read(analyzerProvider.notifier);
    final StorageBreakdown? b = state.breakdown;
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.storageBreakdown,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.refresh,
            tooltip: context.l10n.rescan,
            onPressed: state.loading ? null : vm.rebuildIndex,
          ),
        ],
      ),
      body: b == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 180,
                    child: FvLoadingBar(
                      value: state.progress == 0 ? null : state.progress,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.analyzing, style: context.texts.bodyMedium),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                140 + context.padding.bottom,
              ),
              children: <Widget>[
                if (state.loading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FvLoadingBar(
                      value: state.progress == 0 ? null : state.progress,
                    ),
                  ),
                _BreakdownCard(breakdown: b),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.l10n.optimizationTools,
                            style: context.texts.headlineSmall,
                          ),
                          Text(
                            context.l10n.optimizationSub,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.recoverableBytes > 0)
                      Text(
                        context.l10n.recoverable(
                          FileSizeFormatter.format(state.recoverableBytes),
                        ),
                        style: context.texts.labelLarge?.copyWith(
                          color: context.colors.primary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _ToolRow(
                  icon: Icons.inventory_2_outlined,
                  category: FileCategory.documents,
                  title: context.l10n.largeFiles,
                  highlight: FileSizeFormatter.format(state.largeFilesBytes),
                  subtitle: context.l10n.largeFilesSub(
                    state.largeFilesCount,
                    '100 MB',
                  ),
                  actionLabel: context.l10n.review,
                  onTap: () => context.push(AppRoutes.largeFiles),
                ),
                const SizedBox(height: 10),
                _ToolRow(
                  icon: Icons.copy_all_outlined,
                  category: FileCategory.archives,
                  title: context.l10n.duplicateFiles,
                  highlight: state.scannedTools
                      ? FileSizeFormatter.format(state.duplicateBytes)
                      : '—',
                  subtitle: state.scannedTools
                      ? context.l10n.duplicatesSub(state.duplicateCount)
                      : context.l10n.deepScanBody,
                  actionLabel: context.l10n.review,
                  onTap: () => context.push(AppRoutes.duplicates),
                ),
                const SizedBox(height: 10),
                _ToolRow(
                  icon: Icons.cleaning_services_outlined,
                  category: FileCategory.apks,
                  title: context.l10n.junkCache,
                  highlight: state.scannedTools
                      ? FileSizeFormatter.format(state.junkBytes)
                      : '—',
                  subtitle: context.l10n.junkSub,
                  actionLabel: context.l10n.clean,
                  primaryAction: true,
                  onTap: () => context.push(AppRoutes.junk),
                ),
                const SizedBox(height: 10),
                _ToolRow(
                  icon: Icons.folder_off_outlined,
                  category: FileCategory.trash,
                  title: context.l10n.emptyFolders,
                  highlight: state.scannedTools ? '${state.emptyFolders}' : '—',
                  subtitle: context.l10n.emptyFoldersSub(state.emptyFolders),
                  actionLabel: context.l10n.review,
                  onTap: () => context.push(AppRoutes.junk),
                ),
                const SizedBox(height: 20),
                _SmartSweepCard(busy: state.loading, onPressed: vm.scanTools),
                const SizedBox(height: 20),
                if (b.largestFolders.isNotEmpty) ...<Widget>[
                  FvSectionHeader(
                    title: context.l10n.largestFolders,
                    uppercase: false,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  ),
                  FvCard(
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < b.largestFolders.length; i++)
                          _FolderRow(
                            folder: b.largestFolders[i],
                            maxBytes: b.largestFolders.first.bytes,
                            last: i == b.largestFolders.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});

  final StorageBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final List<CategorySummary> parts =
        <CategorySummary>[
          for (final FileCategory c in <FileCategory>[
            FileCategory.images,
            FileCategory.videos,
            FileCategory.audio,
            FileCategory.documents,
            FileCategory.apks,
            FileCategory.archives,
          ])
            breakdown.summaryOf(c),
        ]..sort(
          (CategorySummary a, CategorySummary b) =>
              b.totalBytes.compareTo(a.totalBytes),
        );
    final int used = breakdown.volume.usedBytes;
    final List<(double, Color, String)> segments = <(double, Color, String)>[
      for (final CategorySummary s in parts)
        if (s.totalBytes > 0)
          (
            used == 0 ? 0 : s.totalBytes / used,
            CategoryColors.ink(brightness, s.category),
            categoryLabel(context.l10n, s.category),
          ),
      if (breakdown.unaccountedBytes > 0)
        (
          used == 0 ? 0 : breakdown.unaccountedBytes / used,
          CategoryColors.ink(brightness, FileCategory.other),
          context.l10n.categoryAppsSystem,
        ),
    ];
    return FvCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.smartphone, size: 18, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  breakdown.volume.name,
                  style: context.texts.titleMedium,
                ),
              ),
              FvCountBadge(
                '${FileSizeFormatter.format(breakdown.volume.freeBytes)} ${context.l10n.free}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                context.l10n.usedOfTotal(
                  FileSizeFormatter.format(used),
                  FileSizeFormatter.format(breakdown.volume.totalBytes),
                ),
                style: context.texts.titleSmall?.copyWith(
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, size: 4, color: context.colors.outline),
              const SizedBox(width: 8),
              Text(
                context.l10n.percentFull(breakdown.volume.usedPercent),
                style: context.texts.labelMedium?.copyWith(
                  color: context.tokens.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _RingPainter(
                segments: segments.map((e) => (e.$1, e.$2)).toList(),
                track: context.isDark
                    ? context.colors.surfaceContainerHigh
                    : context.colors.surfaceContainer,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FileSizeFormatter.format(used),
                      style: context.texts.displaySmall?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    Text(
                      context.l10n.usedLabel,
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FvSegmentedBar(segments: segments.map((e) => (e.$1, e.$2)).toList()),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: segments.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 44,
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (BuildContext context, int i) {
              final (double fraction, Color color, String label) = segments[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? context.colors.surfaceContainer
                      : context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.labelMedium,
                      ),
                    ),
                    Text(
                      FileSizeFormatter.format((fraction * used).round()),
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.segments, required this.track});

  final List<(double, Color)> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 26;
    final double radius =
        math.min(size.width, size.height) / 2 - stroke / 2 - 4;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    double start = -math.pi / 2;
    for (final (double fraction, Color color) in segments) {
      if (fraction <= 0) continue;
      final double sweep = math.pi * 2 * fraction;
      canvas.drawArc(
        rect,
        start,
        sweep - 0.02,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments || old.track != track;
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.category,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.primaryAction = false,
  });

  final IconData icon;
  final FileCategory category;
  final String title;
  final String highlight;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    return FvCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          FvCategoryTile(category: category, icon: icon, size: 48, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      highlight,
                      style: context.texts.labelMedium?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• $subtitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (primaryAction)
            FvFilledButton(label: actionLabel, expand: false, onPressed: onTap)
          else
            FvTonalButton(label: actionLabel, onPressed: onTap),
        ],
      ),
    );
  }
}

class _SmartSweepCard extends StatelessWidget {
  const _SmartSweepCard({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[context.tokens.fabShadow],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_fix_high, color: context.colors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.smartSweep,
                  style: context.texts.titleMedium?.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
                Text(
                  context.l10n.smartSweepBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: busy ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: context.isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
              foregroundColor: context.isDark ? Colors.white : context.colors.primaryContainer,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.18),
              minimumSize: const Size(64, 40),
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.l10n.scan),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.maxBytes,
    required this.last,
  });

  final FolderSize folder;
  final int maxBytes;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.tokens.cardBorder),
              ),
            ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          const FvCategoryTile(category: FileCategory.folders, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: maxBytes == 0 ? 0 : folder.bytes / maxBytes,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                FileSizeFormatter.format(folder.bytes),
                style: context.texts.labelMedium?.copyWith(
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                context.l10n.fileCount(folder.fileCount),
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
