import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:flutter/material.dart';

/// 44dp rounded tile with the category colour at low alpha behind an icon.
class FvCategoryTile extends StatelessWidget {
  const FvCategoryTile({
    super.key,
    required this.category,
    this.icon,
    this.size = 44,
    this.radius = 12,
    this.iconSize = 24,
    this.child,
  });

  final FileCategory category;
  final IconData? icon;
  final double size;
  final double radius;
  final double iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CategoryColors.container(b, category),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child ??
          Icon(
            icon ?? CategoryColors.icon(category),
            color: CategoryColors.ink(b, category),
            size: iconSize,
          ),
    );
  }
}

/// White/dark card with the 1dp ghost border used for grouped lists.
class FvCard extends StatelessWidget {
  const FvCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
    this.color,
    this.elevated = false,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool elevated;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final Color bg = color ??
        (context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLowest);
    final Widget body = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
    final Widget decorated = elevated
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: <BoxShadow>[context.tokens.ambientShadow],
            ),
            child: body,
          )
        : body;
    return margin == null ? decorated : Padding(padding: margin!, child: decorated);
  }
}

/// Small rounded count badge ("156", "3").
class FvCountBadge extends StatelessWidget {
  const FvCountBadge(this.text, {super.key, this.color, this.textColor, this.amber = false});

  final String text;
  final Color? color;
  final Color? textColor;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final Color bg = amber
        ? context.tokens.amber
        : color ?? (context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed);
    final Color fg = amber
        ? context.tokens.onAmber
        : textColor ?? (context.isDark ? context.colors.onPrimaryContainer : context.colors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: context.texts.labelSmall?.copyWith(color: fg, fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// Uppercase section label with optional count badge and trailing widget.
class FvSectionHeader extends StatelessWidget {
  const FvSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.uppercase = true,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  final String title;
  final int? count;
  final Widget? trailing;
  final bool uppercase;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Text(
            uppercase ? title.toUpperCase() : title,
            style: uppercase
                ? context.texts.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  )
                : context.texts.headlineSmall,
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 8),
            FvCountBadge('$count'),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Pill-shaped chip used for filters and breadcrumbs.
class FvChip extends StatelessWidget {
  const FvChip({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.selected = false,
    this.onTap,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? context.colors.primary;
    final Color bg = selected
        ? (context.isDark ? accent.withValues(alpha: 0.18) : context.colors.primaryContainer)
        : context.tokens.chipFill;
    final Color fg = selected
        ? (context.isDark ? accent : context.colors.onPrimary)
        : context.tokens.chipText;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: selected && context.isDark ? BorderSide(color: accent, width: 1.5) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 6 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: context.texts.labelLarge?.copyWith(color: fg)),
              if (trailingIcon != null) ...<Widget>[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Illustration-style empty state block.
class FvEmptyState extends StatelessWidget {
  const FvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.category = FileCategory.downloads,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final FileCategory category;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: context.isDark
                    ? context.colors.surfaceContainerHigh
                    : context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: <BoxShadow>[context.tokens.fabShadow],
                  ),
                  child: Icon(icon, size: 32, color: context.colors.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: context.texts.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...<Widget>[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Tinted informational banner (primary-fixed background, icon tile).
class FvInfoBanner extends StatelessWidget {
  const FvInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    this.onTap,
    this.tone = FvBannerTone.primary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;
  final FvBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color tile, Color ink) = switch (tone) {
      FvBannerTone.primary => (
          context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow,
          context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
          context.colors.primary,
        ),
      FvBannerTone.amber => (
          context.tokens.amber.withValues(alpha: context.isDark ? 0.16 : 0.14),
          context.tokens.amber.withValues(alpha: 0.35),
          context.isDark ? context.tokens.amber : context.colors.onSecondaryContainer,
        ),
      FvBannerTone.error => (
          context.colors.errorContainer.withValues(alpha: context.isDark ? 0.4 : 1),
          context.colors.error.withValues(alpha: 0.18),
          context.isDark ? context.colors.error : context.colors.onErrorContainer,
        ),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: ink),
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
                            title,
                            style: context.texts.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...<Widget>[const SizedBox(width: 8), badge!],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

enum FvBannerTone { primary, amber, error }

/// Multi-segment storage meter (12dp track, rounded caps).
class FvSegmentedBar extends StatelessWidget {
  const FvSegmentedBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.gap = 2,
  });

  /// (fraction 0..1, colour)
  final List<(double, Color)> segments;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final double total =
        segments.fold<double>(0, (double a, (double, Color) s) => a + s.$1).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        color: context.isDark ? context.colors.surface : context.tokens.chipFill,
        child: Row(
          children: <Widget>[
            for (final (double f, Color c) in segments)
              if (f > 0)
                Expanded(
                  flex: (f * 1000).round().clamp(1, 1000),
                  child: Container(
                    margin: EdgeInsets.only(right: gap),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
            if (total < 1) Expanded(flex: ((1 - total) * 1000).round().clamp(1, 1000), child: const SizedBox()),
          ],
        ),
      ),
    );
  }
}

/// Filled primary button at 48dp with optional leading icon and busy state.
class FvFilledButton extends StatelessWidget {
  const FvFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Widget button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: destructive
          ? FilledButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.isDark ? context.colors.error : context.colors.onErrorContainer,
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (icon != null)
            Icon(icon, size: 20),
          if (busy || icon != null) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tonal (soft) button: primary-fixed background with primary text.
class FvTonalButton extends StatelessWidget {
  const FvTonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
        foregroundColor: context.isDark ? context.colors.onPrimaryContainer : context.colors.primary,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: context.texts.labelLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Circular check indicator used for multi-select rows and grid tiles.
class FvSelectCircle extends StatelessWidget {
  const FvSelectCircle({super.key, required this.selected, this.size = 24, this.onDark = false});

  final bool selected;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? context.colors.primaryContainer
            : (onDark ? Colors.black.withValues(alpha: 0.35) : context.tokens.chipFill),
        border: Border.all(
          color: selected
              ? context.colors.primaryContainer
              : (onDark ? Colors.white.withValues(alpha: 0.8) : context.colors.outlineVariant),
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.65, color: context.colors.onPrimary)
          : null,
    );
  }
}

/// Bottom-sheet row with a leading icon, used by action sheets.
class FvSheetAction extends StatelessWidget {
  const FvSheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color fg = !enabled
        ? context.colors.outline
        : destructive
            ? context.colors.error
            : context.colors.onSurface;
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      minTileHeight: 56,
      leading: Icon(icon, color: fg),
      title: Text(label, style: context.texts.titleSmall?.copyWith(color: fg)),
      trailing: trailing,
    );
  }
}

/// Drag-handle + title header for bottom sheets.
class FvSheetHeader extends StatelessWidget {
  const FvSheetHeader({super.key, required this.title, this.subtitle, this.leading, this.onClose});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onClose != null)
            FvIconButtonPlain(icon: Icons.close, tooltip: context.l10n.close, onPressed: onClose!),
        ],
      ),
    );
  }
}

class FvIconButtonPlain extends StatelessWidget {
  const FvIconButtonPlain({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon)),
    );
  }
}

/// Thin progress line for inline loading states.
class FvLoadingBar extends StatelessWidget {
  const FvLoadingBar({super.key, this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(value: value, minHeight: 4),
    );
  }
}
