import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/config.dart';

final serverConnectivityProvider =
    StateNotifierProvider<ServerConnectivityNotifier, bool>((ref) {
  return ServerConnectivityNotifier();
});

class ServerConnectivityNotifier extends StateNotifier<bool> {
  ServerConnectivityNotifier() : super(true) {
    _initConnectivityListener();
  }

  Timer? _pingTimer;
  StreamSubscription? _connectivitySubscription;
  bool _hasNetwork = true;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none)) {
        _hasNetwork = false;
        setOffline();
      } else {
        _hasNetwork = true;
        // Even if we have network, we still need to check if the server is reachable
        _startPingLoop();
      }
    });
  }

  void setOffline() {
    if (state == true) {
      state = false;
      _startPingLoop();
    }
  }

  void setOnline() {
    if (state == false && _hasNetwork) {
      state = true;
      _pingTimer?.cancel();
    }
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    if (!_hasNetwork) {
       state = false;
       return; // Don't ping if device has no wifi/data at all
    }
    
    // Immediate ping
    _pingServer();
    
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pingServer();
    });
  }
  
  Future<void> _pingServer() async {
      if (!_hasNetwork) return;
      try {
        final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)));
        final response = await dio.get('${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}/');
        if (response.statusCode != null) {
          setOnline();
        }
      } catch (e) {
        // Still offline
      }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
