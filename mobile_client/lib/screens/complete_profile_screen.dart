import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techconnect_mobile/screens/home_screen.dart';
import '../core/app_toast.dart';
import '../core/design_tokens.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile({String? fallbackName}) async {
    final name = fallbackName ?? _nameController.text.trim();
    final email = _emailController.text.trim();

    if (fallbackName == null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final currentUser = ref.read(authProvider);
      final success = await ref.read(authProvider.notifier).updateProfile(
            name: name.isNotEmpty ? name : 'Client depanGo',
            email: email,
            phone: currentUser?.phone ?? '',
          );

      if (!mounted) return;

      if (success) {
        AppToast.show(
          context,
          title: 'Bienvenue !',
          message: 'Votre profil a été configuré avec succès.',
          type: AppToastType.success,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        AppToast.show(
          context,
          title: 'Erreur',
          message: 'Impossible de synchroniser avec le serveur. Réessayez.',
          type: AppToastType.error,
        );
      }
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
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Complétez votre profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(LucideIcons.log_out, color: AppTheme.textMuted),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 36,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Comment devons-nous vous appeler ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ces informations permettent à nos artisans de vous identifier lors des interventions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 28),

                // Numéro vérifié (lecture seule)
                if (user?.phone != null && user!.phone.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.phone,
                            color: AppTheme.primaryEmerald, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Numéro vérifié',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Text(
                              user.phone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(LucideIcons.circle_check,
                            color: AppTheme.primaryEmerald, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Champ Nom complet
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez saisir votre prénom et nom';
                    }
                    if (val.trim().length < 2) {
                      return 'Le nom est trop court (min. 2 caractères)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Prénom & Nom (Ex: Ibrahima Diallo)',
                    labelText: 'Nom complet *',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(LucideIcons.user,
                        color: AppTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryEmerald, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Champ Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Adresse Email (Ex: client@mail.com)',
                    labelText: 'Email (optionnel)',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(LucideIcons.mail,
                        color: AppTheme.primaryEmerald),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryEmerald, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton Terminer
                SizedBox(
                  height: AppTouchTarget.standard,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _saveProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Terminer et Accéder à l\'App',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton Passer
                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => _saveProfile(fallbackName: 'Client'),
                    child: const Text(
                      'Passer pour l\'instant',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
