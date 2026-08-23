import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/app_toast.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TechConnectApp(),
    ),
  );
}

class TechConnectApp extends ConsumerWidget {
  const TechConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'depanGo Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ref.watch(sharedPreferencesProvider).getBool('has_seen_onboarding') == true
          ? (user == null ? const LoginScreen() : const HomeScreen())
          : const OnboardingScreen(),
    );
  }
}
