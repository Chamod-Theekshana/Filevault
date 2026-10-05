import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/features/operations/widgets/operation_progress_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold with the four-tab navigation bar from the design. The floating
/// operation panel is stacked above the body so it survives tab switches.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          navigationShell,
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OperationProgressPanel(),
          ),
        ],
      ),
      bottomNavigationBar: FvBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class FvBottomNav extends StatelessWidget {
  const FvBottomNav({super.key, required this.currentIndex, required this.onSelect});

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
      color: context.isDark ? context.colors.surfaceContainer : context.colors.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.tokens.cardBorder)),
        ),
        padding: EdgeInsets.only(bottom: context.padding.bottom),
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
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color pill = selected
        ? (context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed)
        : Colors.transparent;
    final Color fg = selected
        ? (context.isDark ? context.colors.primary : context.colors.primary)
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
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 64,
              height: 32,
              decoration: BoxDecoration(color: pill, borderRadius: BorderRadius.circular(999)),
              child: Icon(selected ? item.selectedIcon : item.icon, color: fg, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: context.texts.labelMedium?.copyWith(
                color: selected ? context.colors.onSurface : context.colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
