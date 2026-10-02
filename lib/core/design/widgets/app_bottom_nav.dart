import 'package:flutter/material.dart';

import '../tokens.dart';

/// Destination shown in [AppBottomNav].
enum AppNavItem { home, subjects, progress, more }

/// Bottom tab bar for the Home / Subjects reference screens.
///
/// Four destinations, white surface, hairline top divider, icon over label.
/// The active tab is brand blue, inactive tabs are neutral gray.
///
/// **Progress is intentionally inert.** The approved screens show a
/// Progress tab, but no Progress screen exists in the codebase yet and
/// inventing one would be out of scope — so the tab is rendered for visual
/// parity and disabled until that screen is built. `more` opens Settings
/// rather than switching tabs, so it is handled by the shell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  /// Index of the selected tab — one of 0 (home), 1 (subjects), 3 (more).
  final int currentIndex;

  /// Called with 0, 1 or 3. Never called with 2 (Progress — inert).
  final ValueChanged<int> onSelect;

  static const List<AppNavItem> _items = [
    AppNavItem.home,
    AppNavItem.subjects,
    AppNavItem.progress,
    AppNavItem.more,
  ];

  bool _isEnabled(int index) => index != 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.colorSurface,
        border: Border(top: BorderSide(color: AppColors.colorBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  label: _labelOf(_items[i]),
                  icon: _iconOf(_items[i]),
                  selected: i == currentIndex,
                  enabled: _isEnabled(i),
                  onTap: _isEnabled(i) ? () => onSelect(i) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelOf(AppNavItem item) => switch (item) {
        AppNavItem.home => 'Home',
        AppNavItem.subjects => 'Subjects',
        AppNavItem.progress => 'Progress',
        AppNavItem.more => 'More',
      };

  IconData _iconOf(AppNavItem item) => switch (item) {
        AppNavItem.home => Icons.home_outlined,
        AppNavItem.subjects => Icons.menu_book_outlined,
        AppNavItem.progress => Icons.insights_outlined,
        AppNavItem.more => Icons.more_horiz,
      };
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppBrand.blue : AppBrand.inactive;

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );

    if (!enabled) {
      // No Progress screen exists yet — keep it visually present but
      // hidden from assistive technology and non-interactive.
      return Expanded(
        child: ExcludeSemantics(child: child),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}
