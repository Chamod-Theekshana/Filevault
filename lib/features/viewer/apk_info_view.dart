import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/apk_info.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final AutoDisposeFutureProviderFamily<ApkInfo?, String> apkInfoProvider =
    FutureProvider.autoDispose.family<ApkInfo?, String>((Ref ref, String path) {
  return ref.watch(platformChannelProvider).apkInfo(path);
});

/// Package details for an APK, with an Install action.
class ApkInfoView extends ConsumerWidget {
  const ApkInfoView({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ApkInfo?> info = ref.watch(apkInfoProvider(path));
    final AsyncValue<FileEntry?> entry = ref.watch(_entryProvider(path));
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.apkInfo,
        subtitle: p.basename(path),
      ),
      body: info.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.l10n.somethingWentWrong)),
        data: (ApkInfo? apk) {
          final int size = entry.valueOrNull?.size ?? 0;
          if (apk == null) {
            return FvEmptyState(
              icon: Icons.android_outlined,
              title: context.l10n.apkInfo,
              message: context.l10n.somethingWentWrong,
              action: FvFilledButton(
                label: context.l10n.openWith,
                expand: false,
                onPressed: () async {
                  final FileEntry? e = entry.valueOrNull;
                  if (e != null) await openWithExternalApp(context, e);
                },
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + context.padding.bottom),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(10),
                    child: apk.icon == null
                        ? Icon(Icons.android, size: 36, color: context.colors.primary)
                        : Image.memory(apk.icon!, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          apk.appName.isEmpty ? p.basename(path) : apk.appName,
                          style: context.texts.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.l10n.versionLabel(apk.versionName)} (${apk.versionCode})',
                          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                        if (apk.isInstalled)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: FvCountBadge(
                              apk.installedVersionName == null
                                  ? context.l10n.granted
                                  : '${context.l10n.version} ${apk.installedVersionName}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FvCard(
                child: Column(
                  children: <Widget>[
                    _InfoRow(label: context.l10n.packageName, value: apk.packageName),
                    _InfoRow(label: context.l10n.size, value: FileSizeFormatter.format(size)),
                    _InfoRow(label: context.l10n.minSdk, value: 'API ${apk.minSdk}'),
                    _InfoRow(label: context.l10n.targetSdk, value: 'API ${apk.targetSdk}', last: true),
                  ],
                ),
              ),
              if (apk.permissions.isNotEmpty) ...<Widget>[
                FvSectionHeader(
                  title: context.l10n.accessControl,
                  count: apk.permissions.length,
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
                ),
                FvCard(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String perm in apk.permissions.take(40))
                        FvChip(
                          label: perm.split('.').last,
                          dense: true,
                          icon: Icons.shield_outlined,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FvInfoBanner(
                tone: FvBannerTone.amber,
                icon: Icons.warning_amber_outlined,
                title: context.l10n.installApk,
                subtitle: context.l10n.installApkBody,
              ),
              const SizedBox(height: 16),
              FvFilledButton(
                label: context.l10n.installApk,
                icon: Icons.download_outlined,
                onPressed: () async {
                  final FileEntry? e = entry.valueOrNull;
                  if (e != null) await openWithExternalApp(context, e);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

final AutoDisposeFutureProviderFamily<FileEntry?, String> _entryProvider =
    FutureProvider.autoDispose.family<FileEntry?, String>((Ref ref, String path) async {
  return (await ref.watch(fileRepositoryProvider).stat(path)).valueOrNull;
});

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          Text(label, style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.texts.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
