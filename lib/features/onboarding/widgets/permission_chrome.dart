import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/features/onboarding/widgets/permission_hero.dart';
import 'package:flutter/material.dart';

class PermissionBenefitRow extends StatelessWidget {
  const PermissionBenefitRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.lightSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.labelLarge),
                Text(
                  subtitle,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionPrivacyBanner extends StatelessWidget {
  const PermissionPrivacyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              size: 18,
              color: context.isDark
                  ? AppColors.darkOnPrimary
                  : AppColors.lightOnPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.permissionPrivacyNote,
              style: context.texts.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: context.l10n.back,
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.permissionTitle,
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 18,
              color: context.isDark
                  ? AppColors.darkOnPrimary
                  : AppColors.lightOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionHero extends StatelessWidget {
  const PermissionHero({super.key});

  @override
  Widget build(BuildContext context) {
    return const PermissionHeroArt();
  }
}
