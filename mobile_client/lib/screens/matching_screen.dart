import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/design_tokens.dart';
import '../services/client_haptic_service.dart';
import '../providers/app_providers.dart';
import 'tracking_chat_screen.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? categoryId;
  final String? categoryName;
  final String? preferredTechnicianName;

  const MatchingScreen({
    super.key,
    this.bookingId,
    this.categoryId,
    this.categoryName,
    this.preferredTechnicianName,
  });

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _lastTickWave = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(_handlePulseHaptics)
     ..repeat();
  }

  void _handlePulseHaptics() {
    final val = _pulseController.value;
    final currentWave = (val * 3).floor();
    if (currentWave != _lastTickWave) {
      _lastTickWave = currentWave;
      ClientHapticService.instance.onSoftPulse();
    }
  }

  @override
  void dispose() {
    _pulseController.removeListener(_handlePulseHaptics);
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
    if (activeBooking != null &&
        (activeBooking.status == 'matched' ||
            activeBooking.status == 'in_progress')) {
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
          child: noTechFound
              ? _buildNoTechWidget()
              : _buildSearchingWidget(
                  activeBooking?.categoryId ?? widget.categoryId),
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

          // Multi-ring concentric radar animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final val = _pulseController.value;
              return SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wave 1
                    _buildWaveRing(val, 0.0, 0.7),
                    // Wave 2
                    _buildWaveRing(val, 0.2, 0.9),
                    // Wave 3
                    _buildWaveRing(val, 0.4, 1.0),

                    // Glowing aura
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      ),
                    ),

                    // Pulsing Center Core (84px) with breathing scale
                    Transform.scale(
                      scale: 1.0 + 0.06 * math.sin(val * 2 * math.pi),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryEmerald.withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.search, size: 36, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 40),
          Text(
            widget.preferredTechnicianName != null
                ? 'En attente de ${widget.preferredTechnicianName}...'
                : 'Recherche d\'un artisan disponible $categoryLabel...',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Show only qualified technicians count if not targeted
          if (widget.preferredTechnicianName == null && categoryId != null)
            ref.watch(categoryFilteredTechniciansProvider(categoryId)).when(
                  data: (techs) {
                    final online = techs
                        .where((t) => t['availability_status'] == 'online')
                        .length;
                    return Text(
                      '$online technicien(s) en ligne dans la zone',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
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

          SizedBox(
            height: AppTouchTarget.standard,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: const Text(
                'Annuler la recherche',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveRing(double controllerVal, double begin, double end) {
    if (controllerVal < begin || controllerVal > end) {
      return const SizedBox.shrink();
    }
    final progress = ((controllerVal - begin) / (end - begin)).clamp(0.0, 1.0);
    final curvedProgress = Curves.easeOutQuad.transform(progress);
    final size = 84.0 + (226.0 * curvedProgress);
    final opacity = (1.0 - curvedProgress) * 0.45;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryEmerald.withValues(alpha: opacity),
          width: 2.0,
        ),
        color: AppTheme.primaryEmerald.withValues(alpha: opacity * 0.25),
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
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.search_x,
                size: 64, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          const Text(
            'Aucun technicien disponible',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
            icon: const Icon(LucideIcons.arrow_left, size: 18),
            label: const Text('Retour',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            child: const Text('Réessayer (Créer une nouvelle demande)',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _categoryLabel(String catId) {
    switch (catId) {
      case 'cat_plumbing':
        return 'en Plomberie';
      case 'cat_electrical':
        return 'en Électricité';
      case 'cat_hvac':
        return 'en Climatisation';
      case 'cat_appliances':
        return 'en Électroménager';
      default:
        return '';
    }
  }
}
