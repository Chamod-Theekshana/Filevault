import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// 64dp top bar. Either shows the shield wordmark ([showBrand]) or a custom
/// [title] with an optional [subtitle] and [leading] button.
class FvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FvAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.showBrand = false,
    this.backgroundColor,
    this.bottom,
    this.titleWidget,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBrand;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  /// Fills the flexible middle slot instead of [title] – used by the inline
  /// search field so it stretches across the bar.
  final Widget? titleWidget;

  @override
  Size get preferredSize => Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? context.colors.surface;
    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 64,
              child: Padding(
                padding: EdgeInsets.only(left: leading == null ? 16 : 4, right: 8),
                child: Row(
                  children: <Widget>[
                    ?leading,
                    if (leading != null) const SizedBox(width: 4),
                    if (showBrand) const FvBrand(),
                    if (titleWidget != null)
                      Expanded(child: titleWidget!)
                    else if (title != null)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.headlineSmall?.copyWith(
                                fontSize: subtitle == null ? 20 : 18,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    ...actions,
                  ],
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Shield badge + "FileVault" wordmark.
class FvBrand extends StatelessWidget {
  const FvBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double box = compact ? 32 : 40;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          child: Icon(
            Icons.shield_outlined,
            size: compact ? 18 : 22,
            color: context.isDark ? context.colors.primary : context.colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.l10n.appName,
          style: context.texts.headlineLarge?.copyWith(
            fontSize: compact ? 22 : 28,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// 48dp touch target around a 24dp icon.
class FvIconButton extends StatelessWidget {
  const FvIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.selected = false,
    this.size = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: selected
            ? IconButton.styleFrom(
                backgroundColor: context.isDark
                    ? context.colors.primaryContainer
                    : context.colors.primaryFixed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )
            : null,
        icon: Icon(icon, size: size),
        color: color ?? (selected ? context.colors.primary : context.colors.onSurfaceVariant),
      ),
    );
  }
}

/// Round avatar button that opens Settings in the mock-ups.
class FvAvatarButton extends StatelessWidget {
  const FvAvatarButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.settings,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Material(
            color: context.isDark ? context.colors.primary : context.colors.primaryContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back arrow used by every pushed screen.
class FvBackButton extends StatelessWidget {
  const FvBackButton({super.key, this.onPressed, this.icon = Icons.arrow_back});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FvIconButton(
      icon: icon,
      tooltip: context.l10n.back,
      color: context.colors.onSurface,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
