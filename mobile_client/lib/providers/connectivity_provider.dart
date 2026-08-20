import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';

final serverConnectivityProvider =
    StateNotifierProvider<ServerConnectivityNotifier, bool>((ref) {
  return ServerConnectivityNotifier();
});

class ServerConnectivityNotifier extends StateNotifier<bool> {
  ServerConnectivityNotifier() : super(true);
  Timer? _pingTimer;

  void setOffline() {
    if (state == true) {
      state = false;
      _startPingLoop();
    }
  }

  void setOnline() {
    if (state == false) {
      state = true;
      _pingTimer?.cancel();
    }
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final dio =
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)));
        final response = await dio.get('${AppConfig.apiBaseUrl}/');
        if (response.statusCode != null) {
          setOnline();
        }
      } catch (e) {
        // Still offline
      }
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}
