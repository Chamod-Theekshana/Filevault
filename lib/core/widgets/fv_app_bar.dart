import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Frosted top bar matching Stitch (shield wordmark or custom leading).
class FvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FvAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions = const <Widget>[],
    this.showBrand = false,
    this.background,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final bool showBrand;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (background ?? context.colors.surface).withValues(alpha: 0.85),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              if (leading != null) leading!,
              if (showBrand) const _Brand(),
              if (title != null)
                Expanded(
                  child: DefaultTextStyle(
                    style: context.texts.headlineSmall!.copyWith(
                      color: context.colors.onSurface,
                    ),
                    child: title!,
                  ),
                )
              else
                const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.darkPrimaryContainer
                : AppColors.lightPrimaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: context.isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.l10n.appName,
          style: context.texts.headlineLarge?.copyWith(
            color: context.colors.onSurface,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class FvIconButton extends StatelessWidget {
  const FvIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class FvAvatarButton extends StatelessWidget {
  const FvAvatarButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.accountAction,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            size: 18,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkOnPrimary
                : AppColors.lightOnPrimary,
          ),
        ),
      ),
    );
  }
}
