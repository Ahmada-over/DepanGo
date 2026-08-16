import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'backend-depango-346078879462.europe-west1.run.app';
    } else if (Platform.isAndroid) {
      return 'backend-depango-346078879462.europe-west1.run.app';
    } else {
      return 'backend-depango-346078879462.europe-west1.run.app';
    }
  }

  static String get apiBaseUrl => 'https://$baseUrl/api/v1';
  static String get wsBaseUrl => 'wss://$baseUrl/ws';
  static String get googleMapsApiKey => 'AIzaSyDwSZnP4DdFes6u2qkN9xumUjv0kW1Hr5c';
}
