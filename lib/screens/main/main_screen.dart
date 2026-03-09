import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/question_provider.dart';
import '../../providers/history_provider.dart';
import '../../utils/app_routes.dart';
import '../home/home_screen.dart';
import '../members/members_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

/// Main screen with bottom navigation
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.initialGroupId,
  });

  final int initialIndex;
  final String? initialGroupId;

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

    if (widget.initialGroupId == null && widget.initialIndex == 0) {
      _restoreLastTab();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_applyDeepLinkContext());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToGroups() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutePaths.groups, (route) => false);
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
    _syncUrlWithCurrentState();
  }

  Future<void> _applyDeepLinkContext() async {
    final deepLinkedGroupId = widget.initialGroupId;
    if (deepLinkedGroupId != null) {
      final shouldStayOnMain =
          await _switchToDeepLinkedGroup(deepLinkedGroupId);
      if (!shouldStayOnMain || !mounted) {
        return;
      }
    }
    _syncUrlWithCurrentState(replace: true);
  }

  Future<bool> _switchToDeepLinkedGroup(String groupId) async {
    for (var i = 0; i < 20; i++) {
      if (!mounted) return false;
      final authState = ref.read(authProvider);
      if (!authState.isLoading) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return false;
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null || authState.groupId == groupId) {
      return true;
    }

    final isMemberOfDeepLinkedGroup =
        user.groups.any((membership) => membership.groupId == groupId);
    if (!isMemberOfDeepLinkedGroup) {
      _redirectToGroupsWithMessage(
        'That group link is no longer available for your account.',
      );
      return false;
    }

    final switched = await ref.read(authProvider.notifier).switchGroup(groupId);
    if (!mounted) return false;

    if (!switched) {
      _redirectToGroupsWithMessage(
        'Could not open that group. Please choose one from your groups list.',
      );
      return false;
    }

    ref.invalidate(groupInfoProvider);
    ref.invalidate(groupMembersProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(paginatedHistoryProvider);
    return true;
  }

  void _redirectToGroupsWithMessage(String message) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutePaths.groupsWithMessage(message),
      (route) => false,
    );
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

  void _syncUrlWithCurrentState({bool replace = false}) {
    if (!kIsWeb) return;

    final groupId = ref.read(authProvider).groupId;
    if (groupId == null || groupId.isEmpty) return;

    final tab = AppRoutePaths.tabFromIndex(_currentIndex);
    final location = AppRoutePaths.groupTab(groupId, tab);
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(location),
      replace: replace,
    );
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
