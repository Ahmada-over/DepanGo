import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/pro_providers.dart';
import '../models/models.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  
  String? _selectedCategory;
  String _selectedTransport = 'moto';
  
  final _categories = [
    {'id': 'cat_plumbing', 'name': 'Plomberie'},
    {'id': 'cat_electrical', 'name': 'Électricité'},
    {'id': 'cat_cleaning', 'name': 'Nettoyage'},
    {'id': 'cat_ac', 'name': 'Climatisation'},
  ];

  final _transports = [
    {'id': 'moto', 'name': 'Moto'},
    {'id': 'car', 'name': 'Voiture'},
    {'id': 'bicycle', 'name': 'Vélo'},
    {'id': 'none', 'name': 'Aucun'},
  ];

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || _selectedCategory == null) return;
    
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.put('/users/me', data: {
        'name': name,
        if (email.isNotEmpty) 'email': email,
        'category_id': _selectedCategory,
        'transport_mode': _selectedTransport,
      });
      if (res.statusCode == 200) {
        final res2 = await dio.get('/users/me');
        if (res2.statusCode == 200) {
            final updatedUser = UserModel.fromJson(res2.data);
            await ref.read(authProvider.notifier).updateUser(updatedUser);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                hintText: 'Prénom & Nom (Ex: Ousmane Sy)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: ProTheme.darkCard,
                prefixIcon: const Icon(Icons.person_outline, color: ProTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Adresse Email (Optionnel)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: ProTheme.darkCard,
                prefixIcon: const Icon(Icons.mail_outline, color: ProTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: ProTheme.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Sélectionnez votre profession',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: ProTheme.darkCard,
                prefixIcon: const Icon(Icons.work_outline, color: ProTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _categories.map((cat) => DropdownMenuItem(
                value: cat['id'],
                child: Text(cat['name']!),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTransport,
              dropdownColor: ProTheme.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Moyen de transport',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: ProTheme.darkCard,
                prefixIcon: const Icon(Icons.directions_car_outlined, color: ProTheme.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _transports.map((trans) => DropdownMenuItem(
                value: trans['id'],
                child: Text(trans['name']!),
              )).toList(),
              onChanged: (val) => setState(() => _selectedTransport = val!),
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
