import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:flutter/material.dart';

class FvCategoryTile extends StatelessWidget {
  const FvCategoryTile({
    super.key,
    required this.category,
    required this.icon,
    this.size = 44,
  });

  final FileCategory category;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CategoryColors.container(brightness, category),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: CategoryColors.ink(brightness, category),
        size: 24,
      ),
    );
  }
}

class FvEmptyState extends StatelessWidget {
  const FvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.lightSurfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: context.colors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: context.texts.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FvFilledButton extends StatelessWidget {
  const FvFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !busy,
      label: label,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (icon != null)
              Icon(icon, size: 18),
            if (busy || icon != null) const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
