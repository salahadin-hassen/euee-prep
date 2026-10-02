import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/widgets/app_bottom_nav.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/subjects/presentation/subject_list_screen.dart';

/// Root shell introduced by the Home / Subjects reference screens: a single
/// Scaffold owning the bottom tab bar, with Home and Subjects kept alive in
/// an [IndexedStack] (Decision 014 — Home → Subjects → Subject).
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  /// Tab to show first — 0 (Home) or 1 (Subjects).
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _onSelect(int index) {
    if (index == 3) {
      // "More" reaches Settings, which is a pushed route with its own
      // back affordance — not a tab, so the selected tab does not change.
      Navigator.of(context).pushNamed('/settings');
      return;
    }
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBrand.cream,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onViewAll: () => setState(() => _index = 1)),
          const SubjectListScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onSelect: _onSelect,
      ),
    );
  }
}
