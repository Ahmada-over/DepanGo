import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/app_toast.dart';
import 'providers/pro_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TechConnectProApp(),
    ),
  );
}

class TechConnectProApp extends ConsumerWidget {
  const TechConnectProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'depanGo Pro',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.darkTheme,
      home: ref.watch(sharedPreferencesProvider).getBool('has_seen_onboarding') == true
          ? (user != null ? const HomeScreen() : const LoginScreen())
          : const OnboardingScreen(),
    );
  }
}
