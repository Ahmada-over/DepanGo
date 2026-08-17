import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/pro_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TechConnectProApp(),
    ),
  );
}

class TechConnectProApp extends ConsumerWidget {
  const TechConnectProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'TechConnect Pro',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.darkTheme,
      home: user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
