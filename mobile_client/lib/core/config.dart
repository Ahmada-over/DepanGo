import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return '127.0.0.1:8001';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 est l'IP spéciale pour accéder à localhost (mac) depuis l'émulateur Android
      return '10.0.2.2:8001';
    } else {
      // Pour iOS Simulator
      return '127.0.0.1:8001';
    }
  }

  static String get apiBaseUrl => 'http://$baseUrl/api/v1';
  static String get wsBaseUrl => 'ws://$baseUrl/ws';
  static String get googleMapsApiKey => 'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
}
