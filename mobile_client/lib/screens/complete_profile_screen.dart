import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techconnect_mobile/screens/home_screen.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.put('/users/me', data: {
        'name': name,
        if (email.isNotEmpty) 'email': email,
      });
      if (res.statusCode == 200) {
        // Force refresh user
        final res2 = await dio.get('/users/me');
        if (res2.statusCode == 200) {
            ref.read(authProvider.notifier).updateUser(res2.data);
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Complétez votre profil')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Comment devons-nous vous appeler ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Ces informations sont nécessaires pour finaliser votre compte.', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Prénom & Nom (Ex: Ibrahima Diallo)',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Adresse Email (Optionnel mais recommandé)',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.mail_outline, color: AppTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Terminer', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
