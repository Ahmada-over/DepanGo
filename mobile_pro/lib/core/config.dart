import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // =========================================================================
  //  BASCULE ENVIRONNEMENT (PROD vs LOCAL)
  //
  // true  -> Mode PRODUCTION (Cloud Run: backend-depango-...run.app)
  // false -> Mode LOCAL      (http://localhost:8001 ou 10.0.2.2:8001 sur Android)
  // =========================================================================
  static const bool isProduction = false;

  // Configuration des hôtes
  static const String _cloudHost = 'backend-depango-346078879462.europe-west1.run.app';
  static const String _localPort = '8001';

  static String get baseUrl {
    if (isProduction) {
      return _cloudHost;
    }
    // Hôte local selon le device
    if (kIsWeb) return '127.0.0.1:$_localPort';
    if (Platform.isAndroid) return '10.0.2.2:$_localPort'; // Émulateur Android
    return '127.0.0.1:$_localPort'; // Simulateur iOS / macOS
  }

  static String get apiBaseUrl =>
      isProduction ? 'https://$baseUrl/api/v1' : 'http://$baseUrl/api/v1';

  static String get wsBaseUrl =>
      isProduction ? 'wss://$baseUrl/ws' : 'ws://$baseUrl/ws';

  static const String googleMapsApiKey =
      'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
}
