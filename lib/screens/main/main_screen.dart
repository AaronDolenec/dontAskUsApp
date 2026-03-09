import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../groups/groups_screen.dart';
import '../home/home_screen.dart';
import '../members/members_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

/// Main screen with bottom navigation
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  static const _lastTabKey = 'main_last_tab_index';
  late int _currentIndex;

  // Use PageView to maintain state between tabs
  late final PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    MembersScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _restoreLastTab();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToGroups() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GroupsScreen()),
      (route) => false,
    );
  }

  void _onTabTapped(int index) {
    // Tapping Home while already on Home → go back to groups overview
    if (index == 0 && _currentIndex == 0) {
      _goToGroups();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    unawaited(_persistLastTab(index));
    _pageController.jumpToPage(index);
  }

  Future<void> _restoreLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIndex = prefs.getInt(_lastTabKey);
    if (!mounted || storedIndex == null) return;
    if (storedIndex < 0 || storedIndex >= _screens.length) return;
    if (storedIndex == _currentIndex) return;

    setState(() {
      _currentIndex = storedIndex;
    });
    _pageController.jumpToPage(storedIndex);
  }

  Future<void> _persistLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastTabKey, index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goToGroups();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Members',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
