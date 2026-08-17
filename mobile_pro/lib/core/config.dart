import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConfig {
  // Point to online production backend on Cloud Run
  static const bool useProductionBackend = true;

  static String get baseUrl {
    if (useProductionBackend || kReleaseMode) {
      return 'backend-depango-346078879462.europe-west1.run.app';
    } else {
      if (kIsWeb) return '127.0.0.1:8001';
      if (Platform.isAndroid) return '10.0.2.2:8001';
      return '127.0.0.1:8001';
    }
  }

  static String get apiBaseUrl =>
      (useProductionBackend || kReleaseMode)
          ? 'https://$baseUrl/api/v1'
          : 'http://$baseUrl/api/v1';

  static String get wsBaseUrl =>
      (useProductionBackend || kReleaseMode)
          ? 'wss://$baseUrl/ws'
          : 'ws://$baseUrl/ws';

  static String get googleMapsApiKey =>
      'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
}
