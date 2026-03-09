import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/auth_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/onboarding/join_group_screen.dart';
import 'screens/onboarding/create_group_screen.dart';
import 'screens/main/main_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'services/app_bootstrap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (not supported on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  // Kick off app bootstrap without blocking first frame.
  unawaited(AppBootstrapService.ensureInitialized());

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(
    const ProviderScope(
      child: DontAskUsApp(),
    ),
  );
}

class DontAskUsApp extends ConsumerWidget {
  const DontAskUsApp({super.key});

  /// Whether the very first route has already been processed through the
  /// splash screen.  Once true, subsequent `pushNamed` / `pushReplacementNamed`
  /// calls build the target screen directly instead of showing splash again.
  static bool _initialRouteProcessed = false;

  /// Central route generator.
  ///
  /// The *first* route the app sees (the browser URL on load / the initial
  /// deep-link) is always routed through [SplashScreen] so that session
  /// restore has time to complete.  Every subsequent in-app navigation builds
  /// the target screen directly — no extra splash screen in between.
  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final path = settings.name ?? AppRoutePaths.root;

    // ----- First route: always go through splash for auth restore -----
    if (!_initialRouteProcessed) {
      _initialRouteProcessed = true;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SplashScreen(
          initialDeepLinkPath: path == AppRoutePaths.root ? null : path,
        ),
      );
    }

    // ----- Subsequent in-app navigations: build the target directly -----
    final deepLink = AppRoutePaths.parseGroupTabPath(path);
    if (deepLink != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => MainScreen(
          initialIndex: deepLink.tab.index,
          initialGroupId: deepLink.groupId,
        ),
      );
    }

    final groupsMessage = AppRoutePaths.parseGroupsMessage(path);
    final normalizedPath = Uri.tryParse(path)?.path;

    switch (normalizedPath) {
      case AppRoutePaths.root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case AppRoutePaths.auth:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthScreen(),
        );
      case AppRoutePaths.welcome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      case AppRoutePaths.groups:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GroupsScreen(
            initialSnackMessage: groupsMessage,
          ),
        );
      case AppRoutePaths.join:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const JoinGroupScreen(),
        );
      case AppRoutePaths.create:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateGroupScreen(),
        );
      case AppRoutePaths.main:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'dontAskUs',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // Routes
      initialRoute: AppRoutePaths.root,
      onGenerateRoute: _onGenerateRoute,

      // Accessibility
      builder: (context, child) {
        return MediaQuery(
          // Ensure text doesn't scale beyond 1.3x for layout stability
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
