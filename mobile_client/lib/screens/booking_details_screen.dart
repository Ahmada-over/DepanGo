import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../core/theme.dart';
import '../core/map_style.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final BookingModel booking;

  const BookingDetailsScreen({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm').format(booking.createdAt);
    final categoryName = booking.categoryId.toUpperCase().replaceAll('CAT_', '');
    
    // Simulate some technician data if available
    final hasTechnician = booking.technicianId != null;
    
    String dynamicTechName = booking.technicianName ?? (hasTechnician ? "Technicien PRO" : "Aucun artisan assigné");
    if (hasTechnician && booking.technicianName == null) {
      final techsAsync = ref.watch(registeredTechniciansProvider);
      techsAsync.whenData((techs) {
        try {
          final tech = techs.firstWhere((t) => t['user_id'] == booking.technicianId);
          dynamicTechName = tech['name'] ?? dynamicTechName;
        } catch (_) {}
      });
    }
    
    final technicianName = dynamicTechName;
    final rating = hasTechnician ? "★ 4.8" : "";
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, categoryName, timeStr, hasTechnician),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHelpButton(),
                  const SizedBox(height: 24),
                  _buildMapAndAddressCard(),
                  const SizedBox(height: 32),
                  const Text('Détails', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildDetailRow(technicianName, hasTechnician ? 'Professionnel' : 'En attente', rating),
                  const SizedBox(height: 16),
                  _buildDetailRow(categoryName, 'Catégorie de service', ''),
                  const SizedBox(height: 32),
                  const Text('Prix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildPriceCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String categoryName, String timeStr, bool hasTechnician) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF80E0D2), // Light emerald/teal gradient to match brand
            Color(0xFFE6F7F5),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Overlapping Avatars
          SizedBox(
            height: 90,
            width: 140,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 10,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Icon(Icons.handyman, size: 36, color: AppTheme.primaryEmerald),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: ClipOval(
                      child: hasTechnician
                          ? Image.network(
                              'https://i.pravatar.cc/150?u=${booking.technicianId}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.grey),
                            )
                          : const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$categoryName, $timeStr',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.headset_mic, color: Colors.black87),
          SizedBox(height: 4),
          Text('Aide', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMapAndAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: IgnorePointer(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(booking.latitude, booking.longitude),
                  zoom: 15,
                ),
                style: kMinimalMapStyle,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(booking.latitude, booking.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  )
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.black87, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.addressText, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(booking.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String subtitle, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ]
          ],
        ),
        if (trailing.isNotEmpty)
          Text(trailing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Prix de la commande', style: TextStyle(fontSize: 15, color: Colors.black87)),
          Row(
            children: const [
              Icon(Icons.bolt, color: Colors.amber, size: 18),
              SizedBox(width: 4),
              Text('Sur devis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          )
        ],
      ),
    );
  }
}
