import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../core/category_helper.dart';
import '../providers/pro_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _expController;

  String _transportMode = 'moto';
  List<String> _selectedCategories = [];
  String _selectedZone = 'Tout Dakar';
  String? _profilePhotoUrl;
  File? _localImageFile;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _initialized = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _dakarZones = [
    'Tout Dakar',
    'Dakar Plateau & Médina',
    'Almadies & Ngor',
    'Ouakam & Mermoz / Sacré-Cœur',
    'Fann, Point E & Amitié',
    'Grand Yoff & HLM',
    'Parcelles Assainies',
    'Pikine & Guédiawaye',
    'Rufisque & Keur Massar',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = ref.read(authProvider);
      final profile = ref.read(technicianProfileProvider);

      _nameController = TextEditingController(text: user?.name ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      _emailController = TextEditingController(text: user?.email ?? '');
      _bioController = TextEditingController(text: '');
      _expController = TextEditingController(text: '');

      _transportMode = profile?.transportMode ?? 'moto';
      _selectedCategories = List.from(profile?.categoryIds ?? ['cat_plumbing']);
      _initialized = true;
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _localImageFile = File(picked.path);
        _isUploadingImage = true;
      });

      // Upload to backend
      final dio = ref.read(apiClientProvider);
      final fileName = picked.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: fileName),
      });

      final res = await dio.post('/bookings/upload_photo', data: formData);
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _profilePhotoUrl = res.data['photo_url'];
          _isUploadingImage = false;
        });
        if (mounted) {
          AppToast.show(context, title: 'Photo mise à jour !', message: 'Votre photo a été enregistrée.', type: AppToastType.success);
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        AppToast.show(context, title: 'Erreur', message: 'Impossible d\'uploader la photo : $e', type: AppToastType.error);
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      AppToast.show(context, title: 'Spécialité requise', message: 'Veuillez cocher au moins un corps de métier.', type: AppToastType.warning);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(apiClientProvider);
      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'transport_mode': _transportMode,
        'category_ids': _selectedCategories,
        if (_profilePhotoUrl != null) 'photo_url': _profilePhotoUrl,
      };

      final res = await dio.patch('/technicians/me/profile', data: payload);
      if (res.statusCode == 200) {
        await ref.read(technicianProfileProvider.notifier).fetchProfile();
        if (mounted) {
          AppToast.show(context, title: 'Profil Mis à Jour !', message: 'Vos informations professionnelles ont été enregistrées.', type: AppToastType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, title: 'Erreur d\'enregistrement', message: e.toString(), type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final profile = ref.watch(technicianProfileProvider);
    final isVerified = profile?.verified ?? false;

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(
        title: const Text('Fiche Profil & Spécialités Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: ProTheme.primaryLight),
            onPressed: _isSaving ? null : _saveProfileChanges,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & KYC Header Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: ProTheme.primaryEmerald,
                          backgroundImage: _localImageFile != null
                              ? FileImage(_localImageFile!)
                              : null,
                          child: _localImageFile == null
                              ? Text(
                                  (user?.name.isNotEmpty == true ? user!.name[0] : 'T').toUpperCase(),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        InkWell(
                          onTap: _pickProfilePhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ProTheme.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: ProTheme.darkBg, width: 2.5),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.name ?? 'Artisan Dépanneur',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                          color: isVerified ? ProTheme.primaryLight : Colors.amber,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isVerified ? ProTheme.primaryEmerald.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isVerified ? ProTheme.primaryEmerald : Colors.amber),
                      ),
                      child: Text(
                        isVerified ? 'STATUT KYC : ARTISAN CERTIFIÉ ' : 'STATUT KYC : EN ATTENTE DE VALIDATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? ProTheme.primaryLight : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. INFORMATIONS PERSONNELLES
              const Text('INFORMATIONS PERSONNELLES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProTheme.darkBorder),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Nom et Prénom',
                        labelStyle: TextStyle(color: ProTheme.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.person_rounded, color: ProTheme.primaryLight, size: 20),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ProTheme.darkBorder)),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Numéro de Téléphone (Joignable par le client)',
                        labelStyle: TextStyle(color: ProTheme.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.phone_rounded, color: ProTheme.primaryLight, size: 20),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ProTheme.darkBorder)),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Téléphone requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Adresse Email (Optionnelle)',
                        labelStyle: TextStyle(color: ProTheme.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.email_rounded, color: ProTheme.primaryLight, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. MOYEN DE TRANSPORT
              const Text('VÉHICULE D\'INTERVENTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _transportMode = 'moto'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _transportMode == 'moto' ? ProTheme.primaryEmerald.withValues(alpha: 0.2) : ProTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _transportMode == 'moto' ? ProTheme.primaryLight : ProTheme.darkBorder,
                            width: _transportMode == 'moto' ? 2 : 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.two_wheeler_rounded, color: ProTheme.primaryLight, size: 22),
                            SizedBox(width: 8),
                            Flexible(child: Text('Moto Express', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _transportMode = 'voiture'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _transportMode == 'voiture' ? Colors.blue.withValues(alpha: 0.2) : ProTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _transportMode == 'voiture' ? Colors.blue : ProTheme.darkBorder,
                            width: _transportMode == 'voiture' ? 2 : 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_rounded, color: Colors.blue, size: 22),
                            SizedBox(width: 8),
                            Flexible(child: Text('Voiture / Fourgon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. CORPS DE MÉTIER & SPÉCIALITÉS
              const Text('VOS MÉTIERS & COMPÉTENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProTheme.darkBorder),
                ),
                child: Column(
                  children: CategoryHelper.getAllCategories().map((cat) {
                    final isSelected = _selectedCategories.contains(cat['id']);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(cat['id']);
                            } else {
                              _selectedCategories.add(cat['id']);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Text(cat['emoji'], style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : ProTheme.textMuted,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                activeColor: ProTheme.primaryEmerald,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedCategories.add(cat['id']);
                                    } else {
                                      _selectedCategories.remove(cat['id']);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 4. ZONE D'INTERVENTION À DAKAR
              const Text('ZONE D\'INTERVENTION PRINCIPALE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProTheme.darkBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    dropdownColor: ProTheme.darkSurface,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: ProTheme.primaryLight),
                    items: _dakarZones.map((z) {
                      return DropdownMenuItem(
                        value: z,
                        child: Row(
                          children: [
                            const Icon(Icons.location_city_rounded, color: ProTheme.primaryLight, size: 18),
                            const SizedBox(width: 10),
                            Text(z, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedZone = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 5. BOUTON ENREGISTRER
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfileChanges,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: Colors.black, size: 20),
                  label: Text(
                    _isSaving ? 'ENREGISTREMENT...' : 'ENREGISTRER LES MODIFICATIONS',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProTheme.primaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Déconnexion
              Center(
                child: TextButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 18),
                  label: const Text('Se Déconnecter', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
