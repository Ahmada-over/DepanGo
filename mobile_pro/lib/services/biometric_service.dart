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
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('[BiometricService] Error checking availability: $e');
      return false;
    }
  }

  /// Tente de ré-authentifier l'utilisateur via biométrie.
  /// En cas d'échec ou d'erreur, ne retourne jamais la raison exacte (Anti-Enumération).
  Future<bool> authenticateAction(String reason) async {
    try {
      if (!(await isBiometricAvailable())) {
        return false;
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
          biometricOnly: true, // Désactive le fallback vers le code PIN du téléphone pour des raisons de sécurité
          stickyAuth: true, // Garde l'auth active même si l'app est mise en pause temporairement (ex: appel entrant)
          sensitiveTransaction: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      // Pour des raisons de sécurité, nous catchons les exceptions (ex: NotEnrolled, LockedOut)
      // mais nous retournons toujours false sans exposer l'erreur à l'appelant.
      debugPrint('[BiometricService] PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return false;
    }
  }
}

// Provider global (Optionnel, si Riverpod est utilisé, sinon l'instance globale suffit)
final biometricService = BiometricService();
