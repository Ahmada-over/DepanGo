import 'package:flutter/services.dart';

/// Service de retours haptiques pour TekService Client.
/// Fournit des signatures haptiques subtiles pour la navigation, la recherche radar et la validation contractuelle.
class ClientHapticService {
  ClientHapticService._();
  static final ClientHapticService instance = ClientHapticService._();

  /// Clic de sélection d'onglet ou de filtre
  Future<void> onSelectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Retour haptique doux (progression slider, pulsation radar)
  Future<void> onSoftPulse() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Confirmation ferme lors du verrouillage d'un slider (devis, commande)
  Future<void> onConfirmed() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
