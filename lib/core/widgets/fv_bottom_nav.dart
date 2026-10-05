import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FvBottomNav extends StatelessWidget {
  const FvBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> items = <_NavItem>[
      _NavItem(Icons.home_outlined, Icons.home, context.l10n.navHome),
      _NavItem(Icons.folder_open_outlined, Icons.folder_open, context.l10n.navBrowse),
      _NavItem(Icons.search, Icons.search, context.l10n.navSearch),
      _NavItem(Icons.settings_outlined, Icons.settings, context.l10n.navSettings),
    ];
    return Material(
      color: (context.isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.lightSurfaceContainerLowest)
          .withValues(alpha: 0.9),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: SizedBox(
          height: 80,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color pill = selected
        ? (context.isDark
            ? AppColors.darkPrimaryContainer
            : AppColors.lightPrimaryFixed)
        : Colors.transparent;
    final Color fg = selected
        ? (context.isDark
            ? AppColors.darkOnPrimaryContainer
            : AppColors.lightOnPrimaryFixed)
        : context.colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: pill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: fg,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: context.texts.labelSmall?.copyWith(
                color: selected ? context.colors.onSurface : fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
