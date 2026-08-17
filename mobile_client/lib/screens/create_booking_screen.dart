import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
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
  bool _isPhotoAttached = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réserver: ${widget.categoryName}'),
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
                color: AppTheme.primaryLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle,
                      color: AppTheme.primaryEmerald, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.categoryName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                        if (widget.basePrice != null)
                          Text('À partir de ${widget.basePrice} FCFA',
                              style: const TextStyle(
                                  color: AppTheme.primaryEmerald,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Votre Problème',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Le disjoncteur saute toutes les 5 minutes...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Photo attachment (Mocked)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isPhotoAttached = !_isPhotoAttached);
                  },
                  icon: Icon(_isPhotoAttached ? Icons.check_circle : Icons.camera_alt,
                      color: _isPhotoAttached ? Colors.green : Colors.grey),
                  label: Text(
                      _isPhotoAttached ? 'Photo ajoutée' : 'Ajouter une photo',
                      style: TextStyle(
                          color:
                              _isPhotoAttached ? Colors.green : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Adresse de prise en charge',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.location_on, color: AppTheme.primaryEmerald),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Information Paiement : Le tarif est fixé sur devis direct avec le technicien. Réglez en espèces ou Mobile Money lors de l\'intervention.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  shape: const StadiumBorder(),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.preferredTechnicianId != null 
                            ? 'Envoyer la demande' 
                            : 'Trouver un technicien à proximité',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      AppToast.show(
        context,
        title: 'Description Requise',
        message: 'Veuillez décrire le problème avant de lancer le matching.',
        type: AppToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final booking =
        await ref.read(activeBookingProvider.notifier).createBooking(
              categoryId: widget.categoryId,
              description: desc,
              addressText: _addressController.text,
              latitude: widget.latitude ?? 14.6937,
              longitude: widget.longitude ?? -17.4441,
              preferredTechnicianId: widget.preferredTechnicianId,
            );

    setState(() => _isLoading = false);

    if (mounted) {
      if (booking != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MatchingScreen(
            preferredTechnicianName: widget.preferredTechnicianName,
          )),
        );
      } else {
        AppToast.show(
          context,
          title: 'Erreur',
          message: 'Impossible de créer la réservation. Veuillez réessayer.',
          type: AppToastType.error,
        );
      }
    }
  }
}
