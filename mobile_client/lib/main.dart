import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/app_toast.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/complete_profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
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
      onGenerateRoute: (settings) {
        if (settings.name != null && (settings.name!.startsWith('/link') || settings.name!.startsWith('/__'))) {
          // Ignore Firebase Auth deep links that are automatically intercepted by Flutter
          return MaterialPageRoute(
            builder: (context) {
              Future.microtask(() {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
              return const Scaffold(backgroundColor: Colors.transparent);
            }
          );
        }
        return null;
      },
      home: ref.watch(sharedPreferencesProvider).getBool('has_seen_onboarding') == true
          ? (user == null ? const LoginScreen() : (user.name == 'Utilisateur Inconnu' ? const CompleteProfileScreen() : const HomeScreen()))
          : const OnboardingScreen(),
    );
  }
}
