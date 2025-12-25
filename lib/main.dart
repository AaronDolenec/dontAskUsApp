import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/screens.dart';
import 'utils/utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DontAskUsApp(),
    ),
  );
}

class DontAskUsApp extends StatelessWidget {
  const DontAskUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dontAskUs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/join': (context) => const JoinGroupScreen(),
        '/create': (context) => const CreateGroupScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
