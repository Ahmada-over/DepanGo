import 'dart:async';
import 'package:flutter/services.dart';

/// Service haptique d'urgence et de gestuelle pour l'application Pro (Artisans Dakar).
/// Gère les vibrations cadencées d'offres entrantes, le glissement des sliders
/// et les confirmations irréversibles selon les normes industrielles (Uber/Bolt Driver).
class ProHapticService {
  ProHapticService._();
  static final ProHapticService instance = ProHapticService._();

  Timer? _cadenceTimer;
  bool _isPlaying = false;

  /// Démarre la pulsation d'urgence cadencée pour l'alerte d'offre entrante
  void startOfferAlert({required Duration duration}) {
    stopAlert();
    _isPlaying = true;

    // Premier impact lourd immédiat
    HapticFeedback.heavyImpact();

    int elapsedSeconds = 0;
    final totalSeconds = duration.inSeconds;

    _cadenceTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      elapsedSeconds += 1;
      final remaining = totalSeconds - elapsedSeconds;

      try {
        if (remaining <= 10) {
          // PHASE CRITIQUE (< 10s) : Triple impact rapide
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 90));
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 90));
          await HapticFeedback.heavyImpact();
        } else {
          // PHASE NORMALE : Double battement cardiaque
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 120));
          await HapticFeedback.mediumImpact();
        }
      } catch (_) {
        // Silencieux si non supporté sur la plateforme
      }
    });
  }

  /// Clic de sélection tactile (onglets, chips, filtres)
  void onSelectionClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Retour haptique discret pendant le glissement du slider
  void onSliderDragProgress() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Validation irréversible du slider (seuil franchi)
  void onSliderConfirmed() {
    stopAlert();
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Rejet, timeout ou annulation de l'offre
  void onOfferDismissed() {
    stopAlert();
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Arrêt immédiat et propre de toutes les vibrations
  void stopAlert() {
    _isPlaying = false;
    _cadenceTimer?.cancel();
    _cadenceTimer = null;
  }
}
