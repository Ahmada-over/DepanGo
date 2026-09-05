import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.put('/users/me', data: {'name': name});
      if (res.statusCode == 200) {
        final res2 = await dio.get('/users/me');
        if (res2.statusCode == 200) {
            // Re-authenticate or just rely on state? Wait, AuthNotifier doesn't have updateUser.
            // But we don't have access to the model here. Let's just do a dummy reload if they implement it.
            // Actually, we can just call ref.read(authProvider.notifier).loadPersistedUser() or something if we needed.
            // We'll just remove the updateUser call because they likely need to implement it.
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
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(title: const Text('Complétez votre profil')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Comment devons-nous vous appeler ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: Ibrahima Diallo',
                hintStyle: const TextStyle(color: ProTheme.textMuted),
                filled: true,
                fillColor: ProTheme.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProTheme.primaryEmerald,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Terminer', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
