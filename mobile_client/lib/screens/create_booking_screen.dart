import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../core/category_helper.dart';
import '../providers/app_providers.dart';
import 'matching_screen.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final double? basePrice;
  final String? preferredTechnicianId;
  final String? preferredTechnicianName;
  final double? latitude;
  final double? longitude;
  final String? address;

  const CreateBookingScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.basePrice,
    this.preferredTechnicianId,
    this.preferredTechnicianName,
    this.latitude,
    this.longitude,
    this.address,
  });

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _descriptionController = TextEditingController();
  late TextEditingController _addressController;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImageFile;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    String currentLoc = widget.address ?? ref.read(selectedLocationProvider);
    if (currentLoc == 'Position sélectionnée' || currentLoc.isEmpty) {
      if (widget.latitude != null && widget.longitude != null) {
        currentLoc =
            'Dakar (${widget.latitude!.toStringAsFixed(3)}, ${widget.longitude!.toStringAsFixed(3)})';
      } else {
        currentLoc = 'Dakar, Sénégal';
      }
    }
    _addressController = TextEditingController(text: currentLoc);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _selectedImageFile = File(picked.path);
        _isUploadingPhoto = true;
      });

      // Upload image to backend
      final photoUrl = await _uploadImageToServer(_selectedImageFile!);
      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      if (photoUrl != null && mounted) {
        AppToast.show(
          context,
          title: 'Photo ajoutée !',
          message: 'L\'image a été téléchargée avec succès.',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        AppToast.show(
          context,
          title: 'Erreur photo',
          message: 'Impossible de charger la photo : $e',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<String?> _uploadImageToServer(File file) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final token = ref.read(authProvider.notifier).token;
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await dio.post('/bookings/upload_photo', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return response.data['photo_url'];
      }
    } catch (e) {
      debugPrint('[PhotoUpload] Error: $e');
    }
    return null;
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo de la panne / intervention',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prenez une photo claire pour aider l\'artisan à préparer ses outils.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.primaryEmerald),
                ),
                title: const Text('Prendre une photo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Ouvrir l\'appareil photo',
                    style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Colors.blue),
                ),
                title: const Text('Choisir dans la galerie',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sélectionner une photo existante',
                    style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _selectedImageFile = null;
      _uploadedPhotoUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catName = CategoryHelper.getCategoryName(widget.categoryId);
    final catIcon = CategoryHelper.getCategoryIcon(widget.categoryId);
    final catColor = CategoryHelper.getCategoryColor(widget.categoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Dépannage : $catName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: catColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CategoryHelper.getCategoryDescription(
                              widget.categoryId),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Description de la Panne',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Ex: Fuite sous l\'évier, le disjoncteur saute, clim qui ne refroidit plus...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryEmerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Photo Attachment Section
            const Text(
              'Photo de l\'installation / panne (Recommandé)',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),

            if (_selectedImageFile == null)
              InkWell(
                onTap: _showImageSourcePicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_rounded,
                            color: AppTheme.primaryEmerald, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ajouter une photo',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textDark)),
                          Text('Appareil photo ou Galerie',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryEmerald.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(
                            _selectedImageFile!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                          if (_isUploadingPhoto)
                            Container(
                              width: 70,
                              height: 70,
                              color: Colors.black45,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Photo attachée',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textDark)),
                          Text(
                            _isUploadingPhoto
                                ? 'Téléchargement en cours...'
                                : 'Prête pour le technicien ✅',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isUploadingPhoto
                                  ? Colors.amber[800]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      onPressed: _removePhoto,
                      tooltip: 'Supprimer la photo',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            const Text(
              'Adresse d\'intervention à Dakar',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on,
                    color: AppTheme.primaryEmerald),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settlement info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_outlined,
                      color: Color(0xFFD97706), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paiement direct : Le diagnostic et le devis sont convenus sur place. Réglez directement l\'artisan en Espèces ou Wave/Orange Money.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.radar_rounded, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.preferredTechnicianId != null
                                  ? 'Demande directe : ${widget.preferredTechnicianName ?? 'l\'artisan'}'
                                  : 'TROUVER UN DÉPANNEUR EN DIRECT',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submitBooking() async {
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      AppToast.show(
        context,
        title: 'Description requise',
        message: 'Veuillez préciser la panne ou le besoin de dépannage.',
        type: AppToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final lat = widget.latitude ?? 14.6937;
      final lon = widget.longitude ?? -17.4441;
      final addr = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'Dakar, Sénégal';

      final booking =
          await ref.read(activeBookingProvider.notifier).createBooking(
                categoryId: widget.categoryId,
                description: desc,
                latitude: lat,
                longitude: lon,
                addressText: addr,
                photoUrl: _uploadedPhotoUrl,
                preferredTechnicianId: widget.preferredTechnicianId,
              );

      setState(() => _isLoading = false);

      if (booking != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchingScreen(
              bookingId: booking.id,
              categoryId: widget.categoryId,
              categoryName: CategoryHelper.getCategoryName(widget.categoryId),
            ),
          ),
        );
      } else if (mounted) {
        AppToast.show(
          context,
          title: 'Échec de réservation',
          message:
              'Impossible d\'envoyer la demande. Vérifiez votre connexion.',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show(
          context,
          title: 'Erreur',
          message: e.toString(),
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
