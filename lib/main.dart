import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  runApp(
    const ProviderScope(
      child: DontAskUsApp(),
    ),
  );
}

class DontAskUsApp extends ConsumerWidget {
  const DontAskUsApp({super.key});

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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/groups': (context) => const GroupsScreen(),
        '/join': (context) => const JoinGroupScreen(),
        '/create': (context) => const CreateGroupScreen(),
        '/main': (context) => const MainScreen(),
      },

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
