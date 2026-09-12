import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../providers/pro_providers.dart';
import '../models/models.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      AppToast.show(
        context,
        title: 'Profession requise',
        message: 'Veuillez sélectionner votre métier d\'intervention.',
        type: AppToastType.warning,
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.put('/users/me', data: {
        'name': name,
        if (email.isNotEmpty) 'email': email,
        'category_id': _selectedCategory,
        'transport_mode': _selectedTransport,
      });

      if (!mounted) return;

      if (res.statusCode == 200) {
        final res2 = await dio.get('/users/me');
        if (res2.statusCode == 200 && mounted) {
          final updatedUser = UserModel.fromJson(res2.data);
          await ref.read(authProvider.notifier).updateUser(updatedUser);
          AppToast.show(
            context,
            title: 'Bienvenue Pro !',
            message: 'Votre profil artisan est configuré.',
            type: AppToastType.success,
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }
      }

      AppToast.show(
        context,
        title: 'Erreur',
        message: 'Impossible de synchroniser le profil avec le serveur.',
        type: AppToastType.error,
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Erreur réseau',
          message: 'Vérifiez votre connexion au serveur ($e).',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(
        title: const Text('Complétez votre profil Pro'),
        backgroundColor: ProTheme.darkSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(LucideIcons.log_out, color: Colors.white70),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: ProTheme.primaryEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ProTheme.primaryEmerald,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.hard_hat,
                      size: 34,
                      color: ProTheme.primaryEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Comment devons-nous vous appeler ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ces informations apparaîtront sur vos devis et auprès des clients de Dakar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez saisir votre prénom et nom';
                    }
                    if (val.trim().length < 2) {
                      return 'Nom trop court (min. 2 caractères)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Prénom & Nom (Ex: Ousmane Sy)',
                    labelText: 'Nom complet *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: ProTheme.darkCard,
                    prefixIcon: const Icon(LucideIcons.user,
                        color: ProTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Adresse Email (Optionnel)',
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: ProTheme.darkCard,
                    prefixIcon: const Icon(LucideIcons.mail,
                        color: ProTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: ProTheme.darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Sélectionnez votre profession *',
                    hintStyle: const TextStyle(color: Colors.white54),
                    labelText: 'Métier d\'intervention *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: ProTheme.darkCard,
                    prefixIcon: const Icon(LucideIcons.briefcase,
                        color: ProTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['id'],
                            child: Text(cat['name']!),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTransport,
                  dropdownColor: ProTheme.darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Moyen de transport',
                    labelText: 'Mode de transport',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: ProTheme.darkCard,
                    prefixIcon: const Icon(LucideIcons.bike,
                        color: ProTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _transports
                      .map((trans) => DropdownMenuItem(
                            value: trans['id'],
                            child: Text(trans['name']!),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedTransport = val!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProTheme.primaryEmerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Terminer et Commencer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
