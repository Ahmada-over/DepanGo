import 'package:flutter/material.dart';
import '../core/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppTheme.primaryDark)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        elevation: 0,
      ),
      body: Center(
        child: Text('$title - Bientôt disponible',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
      ),
    );
  }
}
