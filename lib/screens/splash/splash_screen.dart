import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/app_bootstrap_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../groups/groups_screen.dart';
import '../main/main_screen.dart';
import '../onboarding/auth_screen.dart';
import '../onboarding/create_group_screen.dart';
import '../onboarding/join_group_screen.dart';
import '../onboarding/welcome_screen.dart';

/// Splash screen with token validation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.initialDeepLinkPath,
  });

  final String? initialDeepLinkPath;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Ensure app bootstrap (dotenv + push init) is complete before we touch
    // providers/services that depend on configuration.
    await AppBootstrapService.ensureInitialized();

    // Keep splash very brief for perceived performance.
    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    // Wait briefly for the initial auth restore.
    await _waitForAuthRestore(const Duration(milliseconds: 1400));

    if (!mounted) return;

    var finalAuthState = ref.read(authProvider);
    final hasToken = (await AuthService.getAccessToken())?.isNotEmpty == true;

    // If there is a token but restore didn't yield a user yet, try one explicit
    // reload before we ever send the user back to auth. This prevents false
    // logouts on page refreshes where restore is slower.
    if (hasToken && finalAuthState.user == null && !finalAuthState.isLoading) {
      await ref.read(authProvider.notifier).reloadSession();
      await _waitForAuthRestore(const Duration(milliseconds: 2200));
      if (!mounted) return;
      finalAuthState = ref.read(authProvider);
    }

    // Determine the intended path the user was trying to reach.
    final intendedPath = widget.initialDeepLinkPath;
    final deepLink = AppRoutePaths.parseGroupTabPath(intendedPath);
    final normalizedPath = Uri.tryParse(intendedPath ?? '')?.path;

    final isAuthenticated =
        finalAuthState.user != null || (finalAuthState.isLoading && hasToken);

    // ---- Not authenticated → always go to auth ----
    if (!isAuthenticated) {
      _navigateDirect(const AuthScreen());
      return;
    }

    // ---- Authenticated: honour the intended path ----

    // Deep-link to a specific group+tab  e.g. /groups/:id/members
    if (deepLink != null) {
      _navigateDirect(MainScreen(
        initialIndex: deepLink.tab.index,
        initialGroupId: deepLink.groupId,
      ));
      return;
    }

    // Explicit simple routes the user may have bookmarked / been on
    switch (normalizedPath) {
      case AppRoutePaths.groups:
        final groupsMessage = AppRoutePaths.parseGroupsMessage(intendedPath);
        _navigateDirect(GroupsScreen(initialSnackMessage: groupsMessage));
        return;
      case AppRoutePaths.join:
        _navigateDirect(const JoinGroupScreen());
        return;
      case AppRoutePaths.create:
        _navigateDirect(const CreateGroupScreen());
        return;
      case AppRoutePaths.welcome:
        _navigateDirect(const WelcomeScreen());
        return;
      case AppRoutePaths.main:
        final groupId =
            finalAuthState.groupId ?? await AuthService.getCurrentGroupId();
        _navigateDirect(MainScreen(initialGroupId: groupId));
        return;
      case AppRoutePaths.auth:
        // User is already authenticated but landed on /auth — go to groups
        _navigateDirect(const GroupsScreen());
        return;
    }

    // Fallback: go to the appropriate "home" destination
    if (finalAuthState.groupId != null) {
      _navigateDirect(MainScreen(
        initialIndex: MainTabRoute.home.index,
        initialGroupId: finalAuthState.groupId,
      ));
    } else {
      final storedGroup = await AuthService.getCurrentGroupId();
      if (storedGroup != null && storedGroup.isNotEmpty) {
        _navigateDirect(MainScreen(
          initialIndex: MainTabRoute.home.index,
          initialGroupId: storedGroup,
        ));
      } else {
        _navigateDirect(const GroupsScreen());
      }
    }
  }

  Future<void> _waitForAuthRestore(Duration maxWait) async {
    final authState = ref.read(authProvider);
    if (!authState.isLoading) return;

    final deadline = DateTime.now().add(maxWait);
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 80));
      final state = ref.read(authProvider);
      if (!state.isLoading) break;
    }
  }

  /// Navigate directly to a screen widget, bypassing named routes to avoid
  /// re-entering [onGenerateRoute] (which always creates a SplashScreen).
  void _navigateDirect(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name
              const Text(
                'dontAskUs',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily Questions, Group Fun',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
