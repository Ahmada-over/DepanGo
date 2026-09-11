import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      if (!canAuthenticateWithBiometrics && !isSupported) return false;

      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      debugPrint('[BiometricService] Error checking availability: $e');
      return false;
    }
  }

  /// Tente de ré-authentifier l'utilisateur via biométrie.
  /// Si l'appareil ne dispose pas de biométrie enrôlée (ex: émulateur de test,
  /// ou téléphone sans empreinte configurée), l'action est autorisée avec bypass gracieux.
  Future<bool> authenticateAction(String reason) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        debugPrint('[BiometricService] Aucune biométrie configurée sur cet appareil, validation directe.');
        return true;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Authentification requise',
            cancelButton: 'Annuler',
          ),
          IOSAuthMessages(
            cancelButton: 'Annuler',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false, // Permet le fallback vers le code PIN si nécessaire
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException: ${e.code} - ${e.message}');
      // Si les identifiants ne sont pas configurés sur l'appareil (ex: NotAvailable sur émulateur)
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        debugPrint('[BiometricService] Identifiants de sécurité non configurés (${e.code}) -> bypass gracieux.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return false;
    }
  }
}

// Provider global (Optionnel, si Riverpod est utilisé, sinon l'instance globale suffit)
final biometricService = BiometricService();
