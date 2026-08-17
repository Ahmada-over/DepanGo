import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../providers/pro_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRegister = false;
  final _phoneController = TextEditingController(text: '+221 77 999 88 77');
  final _passController = TextEditingController(text: 'password123');
  final _nameController = TextEditingController();
  
  final List<String> _selectedCategories = ['cat_plumbing'];
  String _selectedTransport = 'moto';
  bool _loading = false;

  final List<Map<String, String>> _availableCategories = [
    {'id': 'cat_plumbing', 'name': 'Plomberie Express', 'icon': '🚰'},
    {'id': 'cat_hvac', 'name': 'Climatisation & Froid', 'icon': '❄️'},
    {'id': 'cat_electrical', 'name': 'Électricité Générale', 'icon': '⚡'},
    {'id': 'cat_appliances', 'name': 'Électroménager', 'icon': '🔌'},
  ];

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    final pass = _passController.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      AppToast.show(context, title: 'Champs requis', message: 'Veuillez renseigner votre téléphone et mot de passe.', type: AppToastType.warning);
      return;
    }

    setState(() => _loading = true);

    if (_isRegister) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        AppToast.show(context, title: 'Nom requis', message: 'Veuillez saisir votre nom complet.', type: AppToastType.warning);
        setState(() => _loading = false);
        return;
      }
      final success = await ref.read(authProvider.notifier).register(
        name: name,
        phone: phone,
        password: pass,
        categories: _selectedCategories,
        transportMode: _selectedTransport,
      );
      if (mounted) {
        setState(() => _loading = false);
        if (!success) {
          AppToast.show(context, title: 'Erreur d\'inscription', message: 'Impossible de créer le compte. Vérifiez les informations.', type: AppToastType.error);
        }
      }
    } else {
      final success = await ref.read(authProvider.notifier).login(phone, pass);
      if (mounted) {
        setState(() => _loading = false);
        if (!success) {
          AppToast.show(context, title: 'Échec de connexion', message: 'Identifiants invalides ou compte inexistant.', type: AppToastType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pro Badge & App Brand
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ProTheme.primaryEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: ProTheme.primaryEmerald.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.handyman_rounded, color: ProTheme.primaryLight, size: 44),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TechConnect Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ProTheme.textWhite,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Espace Techniciens & Artisans • Dakar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ProTheme.textMuted),
                ),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: ProTheme.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ProTheme.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Selector (Connexion / Inscription)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isRegister = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isRegister ? ProTheme.primaryEmerald : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Connexion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !_isRegister ? Colors.white : ProTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isRegister = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isRegister ? ProTheme.primaryEmerald : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Rejoindre le Réseau',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isRegister ? Colors.white : ProTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_isRegister) ...[
                        const Text('Nom complet ou Raison sociale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ex: Ibrahima Diallo',
                            hintStyle: const TextStyle(color: ProTheme.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: ProTheme.darkSurface,
                            prefixIcon: const Icon(Icons.person_outline, color: ProTheme.primaryLight, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Phone Field
                      const Text('Numéro de Téléphone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '+221 77 000 00 00',
                          hintStyle: const TextStyle(color: ProTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: ProTheme.darkSurface,
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: ProTheme.primaryLight, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      const Text('Mot de Passe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: ProTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: ProTheme.darkSurface,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: ProTheme.primaryLight, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProTheme.darkBorder)),
                        ),
                      ),

                      if (_isRegister) ...[
                        const SizedBox(height: 16),
                        const Text('Spécialités de Dépannage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((cat) {
                            final isSel = _selectedCategories.contains(cat['id']);
                            return FilterChip(
                              label: Text('${cat['icon']} ${cat['name']}', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : ProTheme.textMuted)),
                              selected: isSel,
                              selectedColor: ProTheme.primaryEmerald,
                              backgroundColor: ProTheme.darkSurface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSel ? ProTheme.primaryLight : ProTheme.darkBorder)),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(cat['id']!);
                                  } else if (_selectedCategories.length > 1) {
                                    _selectedCategories.remove(cat['id']);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text('Mode de Déplacement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.two_wheeler_rounded, size: 16), SizedBox(width: 6), Text('Moto')]),
                                selected: _selectedTransport == 'moto',
                                selectedColor: ProTheme.primaryEmerald,
                                backgroundColor: ProTheme.darkSurface,
                                onSelected: (_) => setState(() => _selectedTransport = 'moto'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions_car_rounded, size: 16), SizedBox(width: 6), Text('Voiture')]),
                                selected: _selectedTransport == 'voiture',
                                selectedColor: const Color(0xFF1E40AF),
                                backgroundColor: ProTheme.darkSurface,
                                onSelected: (_) => setState(() => _selectedTransport = 'voiture'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProTheme.primaryEmerald,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _isRegister ? 'Valider mon Inscription' : 'Se Connecter',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
