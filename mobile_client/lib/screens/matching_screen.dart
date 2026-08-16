import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../providers/app_providers.dart';
import 'tracking_chat_screen.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  final String? preferredTechnicianName;

  const MatchingScreen({
    super.key,
    this.preferredTechnicianName,
  });

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBooking = ref.watch(activeBookingProvider);
    final noTechFound = activeBooking?.status == 'no_technician_found';

    if (noTechFound && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    // Auto navigate when WS updates status to matched
    if (activeBooking != null && (activeBooking.status == 'matched' || activeBooking.status == 'in_progress')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackingChatScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: noTechFound ? _buildNoTechWidget() : _buildSearchingWidget(activeBooking?.categoryId),
        ),
      ),
    );
  }

  Widget _buildSearchingWidget(String? categoryId) {
    final categoryLabel = _categoryLabel(categoryId ?? '');

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),

        // Pulse radar animation
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140 + (_pulseController.value * 60),
                  height: 140 + (_pulseController.value * 60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryEmerald.withOpacity(1.0 - _pulseController.value),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryEmerald,
                  ),
                  child: const Icon(Icons.search, size: 50, color: Colors.white),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 40),
        Text(
          widget.preferredTechnicianName != null
              ? 'En attente de ${widget.preferredTechnicianName}...'
              : 'En attente d\'une réponse...',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Show only qualified technicians count if not targeted
        if (widget.preferredTechnicianName == null && categoryId != null)
          ref.watch(categoryFilteredTechniciansProvider(categoryId)).when(
            data: (techs) {
              final online = techs.where((t) => t['availability_status'] == 'online').length;
              return Text(
                '$online technicien(s) en ligne dans la zone',
                style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
              );
            },
            loading: () => const Text(
              'Transmission de votre demande...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            error: (_, __) => const Text(
              'Connexion au serveur...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )
        else if (widget.preferredTechnicianName != null)
          const Text(
            'Transmission exclusive à ce technicien.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          )
        else
          const Text(
            'Transmission de la demande en cours.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),

        const Spacer(),

        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white38),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Annuler la recherche', style: TextStyle(color: Colors.white70)),
        ),
      ],
      ),
    );
  }

  Widget _buildNoTechWidget() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.search_off_rounded, size: 64, color: Colors.white54),
        ),
        const SizedBox(height: 32),
        const Text(
          'Aucun technicien disponible',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Aucun technicien qualifié pour cette catégorie n\'est disponible dans votre zone pour le moment.\nRéessayez dans quelques instants.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Retour', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryEmerald,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // Actually, to retry, they would need to create a new booking
            // For now, just navigate back so they can try again
            Navigator.pop(context);
          },
          child: const Text('Réessayer (Créer une nouvelle demande)', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        const SizedBox(height: 24),
      ],
      ),
    );
  }

  String _categoryLabel(String catId) {
    switch (catId) {
      case 'cat_plumbing': return 'en Plomberie';
      case 'cat_electrical': return 'en Électricité';
      case 'cat_hvac': return 'en Climatisation';
      case 'cat_appliances': return 'en Électroménager';
      default: return '';
    }
  }
}
