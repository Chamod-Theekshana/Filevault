import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/features/onboarding/onboarding_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Permission onboarding screen (Stitch "Permission Setup").
class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState state = ref.watch(onboardingProvider);
    final OnboardingViewModel vm = ref.read(onboardingProvider.notifier);
    ref.listen<OnboardingState>(onboardingProvider, (OnboardingState? prev, OnboardingState next) {
      if (next.status == StoragePermissionStatus.granted && prev?.status != StoragePermissionStatus.granted) {
        context.go(AppRoutes.home);
      }
    });
    final bool denied = state.status == StoragePermissionStatus.denied;
    final bool blocked = state.status == StoragePermissionStatus.permanentlyDenied;
    return Scaffold(
      appBar: FvAppBar(
        title: context.l10n.permissionSetup,
        leading: state.onboardingDone ? const FvBackButton() : null,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: <Widget>[
                  const SizedBox(height: 8),
                  const _HeroIllustration(),
                  const SizedBox(height: 24),
                  Text(context.l10n.permissionTitle, style: context.texts.headlineMedium),
                  const SizedBox(height: 10),
                  _BodyText(usesAllFilesAccess: state.usesAllFilesAccess),
                  const SizedBox(height: 20),
                  _FeatureRow(
                    category: FileCategory.downloads,
                    icon: Icons.folder_open_outlined,
                    title: context.l10n.permissionFeatureBrowse,
                    subtitle: context.l10n.permissionFeatureBrowseSub,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    category: FileCategory.documents,
                    icon: Icons.lock_outline,
                    title: context.l10n.permissionFeatureVault,
                    subtitle: context.l10n.permissionFeatureVaultSub,
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    category: FileCategory.archives,
                    icon: Icons.cleaning_services_outlined,
                    title: context.l10n.permissionFeatureClean,
                    subtitle: context.l10n.permissionFeatureCleanSub,
                  ),
                  const SizedBox(height: 16),
                  FvInfoBanner(
                    icon: Icons.verified_user_outlined,
                    title: context.l10n.permissionPrivacyNote,
                  ),
                  if (denied || blocked) ...<Widget>[
                    const SizedBox(height: 12),
                    FvInfoBanner(
                      tone: FvBannerTone.error,
                      icon: Icons.block_outlined,
                      title: context.l10n.permissionDeniedTitle,
                      subtitle: blocked
                          ? context.l10n.permissionPermanentlyDenied
                          : context.l10n.permissionDeniedBody,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                children: <Widget>[
                  FvFilledButton(
                    label: blocked ? context.l10n.openSystemSettings : context.l10n.grantAccess,
                    icon: blocked ? Icons.open_in_new : Icons.arrow_forward,
                    busy: state.busy,
                    onPressed: blocked ? vm.openSettings : vm.grantAccess,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: state.busy
                        ? null
                        : () async {
                            await vm.skip();
                            if (context.mounted) context.go(AppRoutes.home);
                          },
                    child: Text(
                      denied || blocked ? context.l10n.continueLimited : context.l10n.notNow,
                      style: context.isDark
                          ? null
                          : context.texts.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText({required this.usesAllFilesAccess});

  final bool usesAllFilesAccess;

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);
    if (!usesAllFilesAccess) return Text(context.l10n.permissionLegacyBody, style: base);
    final String body = context.l10n.permissionBody;
    final int idx = body.indexOf('All Files Access');
    if (idx < 0) return Text(body, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(text: body.substring(0, idx)),
          TextSpan(
            text: 'All Files Access',
            style: base?.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
          ),
          const TextSpan(text: ' ('),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.tokens.chipFill,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'MANAGE_EXTERNAL_STORAGE',
                style: context.texts.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colors.primary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const TextSpan(text: ')'),
          TextSpan(text: body.substring(idx + 'All Files Access'.length)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final FileCategory category;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          FvCategoryTile(category: category, icon: icon, size: 40, iconSize: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.titleSmall),
                Text(
                  subtitle,
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-built illustration: tilted document card, folder with lock badge,
/// amber accent dot – echoing the hero in the design.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final Color panel = context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow;
    return Container(
      height: 200,
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 36,
            top: 28,
            child: Transform.rotate(
              angle: -0.18,
              child: _Sheet(width: 120, height: 92, color: context.isDark ? context.colors.surfaceContainerHigh : Colors.white),
            ),
          ),
          Positioned(
            right: 40,
            top: 42,
            child: Transform.rotate(
              angle: 0.12,
              child: _Sheet(width: 110, height: 86, color: context.isDark ? context.colors.surfaceContainerHigh : Colors.white),
            ),
          ),
          const Positioned(
            bottom: 30,
            child: FvAppIcon(size: 100),
          ),
          Positioned(
            right: 48,
            bottom: 60,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: CategoryColors.ink(b, FileCategory.images), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: 54,
            bottom: 52,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: CategoryColors.ink(b, FileCategory.apks), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[context.tokens.ambientShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final double w in <double>[0.8, 0.55, 0.7, 0.4])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FractionallySizedBox(
                widthFactor: w,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.colors.primaryFixed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
