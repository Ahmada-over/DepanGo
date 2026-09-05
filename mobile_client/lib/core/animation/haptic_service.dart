import 'package:flutter/services.dart';

/// Service centralisé pour gérer les retours haptiques (vibrations) de l'application.
/// Spécialement conçu pour l'expérience de génération IA.
class HapticService {
  HapticService._();

  static bool _hapticsEnabled = true;
  static DateTime? _lastStreamingTick;
  
  /// Cooldown minimum entre deux haptics pendant le streaming (évite le spam)
  static const Duration _streamingThrottle = Duration(milliseconds: 150);

  /// Permet de désactiver globalement les haptics (Accessibilité/Préférences)
  static void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Appelé au tout début de la génération d'une réponse IA
  static Future<void> startGeneration() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignorer si non supporté
    }
  }

  /// Appelé pendant le streaming de texte.
  /// Intègre un throttle pour ne pas vibrer à chaque token.
  static Future<void> streamingTick() async {
    if (!_hapticsEnabled) return;

    final now = DateTime.now();
    if (_lastStreamingTick == null || 
        now.difference(_lastStreamingTick!) >= _streamingThrottle) {
      _lastStreamingTick = now;
      try {
        // Selection click est très léger, parfait pour simuler une frappe
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  /// Appelé à la toute fin de la génération
  static Future<void> finishGeneration() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Feedback générique pour les boutons (ex: Send/Stop, micro-interactions)
  static Future<void> buttonPress() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
