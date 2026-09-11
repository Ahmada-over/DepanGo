import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConfig {
  // =========================================================================
  //  BASCULE ENVIRONNEMENT (PROD vs LOCAL)
  //
  // true  -> Mode PRODUCTION (Cloud Run: backend-depango-...run.app)
  // false -> Mode LOCAL (10.0.2.2 pour émulateur Android, 127.0.0.1 pour simulateur iOS)
  // =========================================================================
  static const bool isProduction = kReleaseMode;

  // Configuration des hôtes
  static const String _cloudHost = 'backend-depango-346078879462.europe-west1.run.app';

  // IP locale de la machine hôte pour les appareils PHYSIQUES (ex: iPhone en Wi-Fi)
  static const String _physicalDeviceHost = '192.168.1.75';
  static const String _localPort = '8001';

  // true  -> Vrai téléphone physique connecté au Wi-Fi (utilise _physicalDeviceHost: 192.168.1.75)
  // false -> Émulateur Android Pixel (utilise 10.0.2.2) ou Simulateur iOS (utilise 127.0.0.1)
  static const bool isPhysicalDevice = false;

  static String get baseUrl {
    if (isProduction) {
      return _cloudHost;
    }
    // Web utilise localhost
    if (kIsWeb) return '127.0.0.1:$_localPort';

    // Vrai appareil physique
    if (isPhysicalDevice) return '$_physicalDeviceHost:$_localPort';

    // Émulateur Android vs Simulateur iOS
    if (Platform.isAndroid) return '10.0.2.2:$_localPort';
    return '127.0.0.1:$_localPort';
  }

  static String get apiBaseUrl =>
      isProduction ? 'https://$baseUrl/api/v1' : 'http://$baseUrl/api/v1';

  static String get wsBaseUrl =>
      isProduction ? 'wss://$baseUrl/ws' : 'ws://$baseUrl/ws';

  static const String googleMapsApiKey =
      'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
}
