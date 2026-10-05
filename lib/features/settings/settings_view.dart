import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/features/onboarding/onboarding_viewmodel.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/vault/vault_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FutureProvider<String> appVersionProvider = FutureProvider<String>((Ref ref) async {
  try {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (_) {
    return '1.0.0 (1)';
  }
});

/// Settings: permission card, appearance, browsing, trash, security, about.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final OnboardingState permission = ref.watch(onboardingProvider);
    final VaultState vault = ref.watch(vaultProvider);
    final String version = ref.watch(appVersionProvider).valueOrNull ?? '1.0.0';
    final bool granted = permission.status == StoragePermissionStatus.granted;
    return Scaffold(
      appBar: FvAppBar(
        title: context.l10n.settingsTitle,
        actions: <Widget>[
          FvIconButton(
            icon: Icons.search,
            tooltip: context.l10n.search,
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 140 + context.padding.bottom),
        children: <Widget>[
          FvCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: granted
                            ? (context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed)
                            : context.colors.errorContainer.withValues(alpha: context.isDark ? 0.4 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        granted ? Icons.verified_user_outlined : Icons.gpp_maybe_outlined,
                        color: granted ? context.colors.primary : context.colors.error,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  permission.usesAllFilesAccess
                                      ? context.l10n.allFilesAccess
                                      : context.l10n.storageAccess,
                                  style: context.texts.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FvCountBadge(
                                granted ? context.l10n.granted : context.l10n.notGranted,
                                color: granted ? null : context.colors.errorContainer,
                                textColor: granted ? null : context.colors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            granted ? context.l10n.allFilesAccessSub : context.l10n.allFilesAccessMissing,
                            style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: context.isDark ? context.colors.surfaceContainer : context.colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          context.l10n.scopedStorageNote,
                          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.read(onboardingProvider.notifier).openSettings(),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(context.l10n.systemAppInfo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SectionTitle(icon: Icons.palette_outlined, label: context.l10n.appearance),
          FvCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(context.l10n.theme, style: context.texts.titleMedium),
                Text(
                  context.l10n.themeSub,
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SegmentedButton<AppThemeMode>(
                  segments: <ButtonSegment<AppThemeMode>>[
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.system,
                      icon: const Icon(Icons.phone_android, size: 18),
                      label: Text(context.l10n.themeSystem),
                    ),
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined, size: 18),
                      label: Text(context.l10n.themeLight),
                    ),
                    ButtonSegment<AppThemeMode>(
                      value: AppThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 18),
                      label: Text(context.l10n.themeDark),
                    ),
                  ],
                  selected: <AppThemeMode>{settings.themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<AppThemeMode> s) => controller.setThemeMode(s.first),
                ),
                const SizedBox(height: 20),
                Text(context.l10n.accentColor, style: context.texts.titleMedium),
                Text(
                  _accentName(context, settings.accentArgb),
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    for (final int argb in AppColors.accentPresets)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: GestureDetector(
                          onTap: () => controller.setAccent(argb),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Color(argb),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: settings.accentArgb == argb
                                    ? context.colors.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: settings.accentArgb == argb
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _SectionTitle(icon: Icons.folder_outlined, label: context.l10n.browsing),
          FvCard(
            child: Column(
              children: <Widget>[
                _NavRow(
                  icon: Icons.view_list_outlined,
                  title: context.l10n.defaultLayout,
                  subtitle: settings.defaultViewMode == ViewMode.list
                      ? context.l10n.listView
                      : context.l10n.gridView,
                  trailingText: settings.defaultViewMode == ViewMode.list
                      ? context.l10n.listView
                      : context.l10n.gridView,
                  onTap: () => controller.setDefaultViewMode(
                    settings.defaultViewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
                  ),
                ),
                _NavRow(
                  icon: Icons.sort_by_alpha,
                  title: context.l10n.sortOrder,
                  subtitle:
                      '${_sortName(context, settings.defaultSort.field)} • ${settings.defaultSort.foldersFirst ? context.l10n.foldersFirst : context.l10n.name}',
                  onTap: () async {
                    final SortField? field = await showOptionSheet<SortField>(
                      context,
                      title: context.l10n.sortBy,
                      selected: settings.defaultSort.field,
                      options: <(SortField, String, IconData?)>[
                        (SortField.name, context.l10n.name, Icons.sort_by_alpha),
                        (SortField.size, context.l10n.size, Icons.data_usage),
                        (SortField.date, context.l10n.date, Icons.schedule),
                        (SortField.type, context.l10n.type, Icons.category_outlined),
                      ],
                    );
                    if (field != null) {
                      controller.setDefaultSort(settings.defaultSort.copyWith(field: field));
                    }
                  },
                ),
                _SwitchRow(
                  icon: Icons.visibility_outlined,
                  title: context.l10n.showHiddenFiles,
                  subtitle: context.l10n.showHiddenSub,
                  value: settings.showHiddenFiles,
                  onChanged: controller.setShowHidden,
                ),
                _SwitchRow(
                  icon: Icons.delete_outline,
                  title: context.l10n.confirmDeletion,
                  subtitle: context.l10n.confirmDeletionSub,
                  value: settings.confirmBeforeDelete,
                  onChanged: controller.setConfirmDelete,
                  last: true,
                ),
              ],
            ),
          ),
          _SectionTitle(icon: Icons.auto_delete_outlined, label: context.l10n.trashAndStorage),
          FvCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_delete_outlined, color: context.colors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(context.l10n.autoCleanTrash, style: context.texts.titleSmall),
                          Text(
                            context.l10n.autoCleanTrashSub,
                            style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int days in <int>[7, 30, 60, 0])
                      FvChip(
                        label: days == 0 ? context.l10n.never : context.l10n.nDays(days),
                        icon: settings.trashAutoCleanDays == days ? Icons.check : null,
                        selected: settings.trashAutoCleanDays == days,
                        onTap: () => controller.setTrashDays(days),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.trash),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(context.l10n.trash),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.analyzer),
                        icon: const Icon(Icons.donut_small_outlined, size: 18),
                        label: Text(context.l10n.cleanUp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _SectionTitle(icon: Icons.lock_outline, label: context.l10n.security),
          FvCard(
            child: Column(
              children: <Widget>[
                _NavRow(
                  icon: Icons.lock_outline,
                  title: context.l10n.secureFolder,
                  subtitle: vault.status == VaultStatus.notConfigured
                      ? context.l10n.vaultNotSetUp
                      : '${context.l10n.itemCount(vault.items.length)} • ${context.l10n.vaultSubtitle}',
                  onTap: () => context.push(AppRoutes.vault),
                ),
                if (vault.biometricsAvailable)
                  _SwitchRow(
                    icon: Icons.fingerprint,
                    title: context.l10n.vaultEnableBiometric,
                    subtitle: context.l10n.vaultEnableBiometricSub,
                    value: settings.vaultBiometric,
                    onChanged: (bool v) => ref.read(vaultProvider.notifier).setBiometrics(v),
                  ),
                _NavRow(
                  icon: Icons.timer_outlined,
                  title: context.l10n.vaultAutoLock,
                  subtitle: context.l10n.vaultAutoLockSub,
                  trailingText: context.l10n.vaultAfterMinutes(settings.vaultAutoLockMinutes),
                  onTap: () async {
                    final int? minutes = await showOptionSheet<int>(
                      context,
                      title: context.l10n.vaultAutoLock,
                      selected: settings.vaultAutoLockMinutes,
                      options: <(int, String, IconData?)>[
                        (0, context.l10n.vaultAfterMinutes(0), Icons.lock_clock),
                        (1, context.l10n.vaultAfterMinutes(1), null),
                        (5, context.l10n.vaultAfterMinutes(5), null),
                        (15, context.l10n.vaultAfterMinutes(15), null),
                      ],
                    );
                    if (minutes != null) await controller.setVaultAutoLock(minutes);
                  },
                  last: true,
                ),
              ],
            ),
          ),
          _SectionTitle(icon: Icons.info_outline, label: context.l10n.about),
          FvCard(
            child: Column(
              children: <Widget>[
                _NavRow(
                  icon: Icons.shield_outlined,
                  title: context.l10n.appName,
                  subtitle: '${context.l10n.versionLabel(version)} • ${context.l10n.release}',
                  trailingText: 'ARM64',
                  onTap: () {},
                ),
                _NavRow(
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.privacyAndEncryption,
                  subtitle: context.l10n.privacySub,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      icon: const Icon(Icons.privacy_tip_outlined, size: 32),
                      title: Text(context.l10n.privacyAndEncryption),
                      content: SingleChildScrollView(child: Text(context.l10n.privacyBody)),
                      actions: <Widget>[
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.close),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavRow(
                  icon: Icons.code,
                  title: context.l10n.openSourceLicenses,
                  subtitle: context.l10n.licensesSub,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: version,
                  ),
                ),
                _NavRow(
                  icon: Icons.refresh,
                  title: context.l10n.resetIndex,
                  subtitle: context.l10n.resetIndexSub,
                  onTap: () async {
                    await ref
                        .read(indexRepositoryProvider)
                        .rebuild(includeHidden: settings.showHiddenFiles);
                    if (context.mounted) context.showSnack(context.l10n.indexRebuilt);
                  },
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _accentName(BuildContext context, int argb) => switch (argb) {
        0xFF0B6E99 => context.l10n.accentOcean,
        0xFF2E7D32 => context.l10n.accentForest,
        0xFF6750A4 => context.l10n.accentViolet,
        0xFFC2185B => context.l10n.accentRose,
        0xFFE65100 => context.l10n.accentAmber,
        _ => context.l10n.accentColor,
      };

  String _sortName(BuildContext context, SortField field) => switch (field) {
        SortField.name => context.l10n.name,
        SortField.size => context.l10n.size,
        SortField.date => context.l10n.date,
        SortField.type => context.l10n.type,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: context.colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: context.texts.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: context.texts.labelMedium?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: context.colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
