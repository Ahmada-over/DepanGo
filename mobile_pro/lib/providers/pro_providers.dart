import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

import '../core/api_client.dart';
import '../core/app_toast.dart';
import '../core/config.dart';
import '../models/models.dart';
import 'connectivity_provider.dart';

// --- 1. Auth Provider ---
final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;
  String? token;

  AuthNotifier(this._ref) : super(null) {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenStr = prefs.getString('tech_token');
    final userStr = prefs.getString('tech_user');
    if (tokenStr != null && userStr != null) {
      token = tokenStr;
      state = UserModel.fromJson(jsonDecode(userStr));
      _ref.read(technicianProfileProvider.notifier).fetchProfile();
      _ref.read(proWebSocketProvider).connect();
    }
  }

  Future<bool> login(String phone, String password) async {
    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post('/auth/login', data: {
        'email': phone,
        'phone': phone,
        'password': password,
      });
      if (res.statusCode == 200) {
        token = res.data['access_token'];
        state = UserModel.fromJson(res.data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tech_token', token!);
        await prefs.setString('tech_user', jsonEncode(state!.toJson()));

        _ref.read(technicianProfileProvider.notifier).fetchProfile();
        _ref.read(proWebSocketProvider).connect();
        return true;
      }
    } catch (e) {
      debugPrint('[Auth] Login error: $e');
    }
    return false;
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required List<String> categories,
    required String transportMode,
  }) async {
    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        'password': password,
        'role': 'technician',
        'category_ids': categories,
        'transport_mode': transportMode,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return await login(phone, password);
      }
    } catch (e) {
      debugPrint('[Auth] Register error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    token = null;
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tech_token');
    await prefs.remove('tech_user');
    _ref.read(proWebSocketProvider).disconnect();
  }
}

// --- 2. Technician Profile Provider ---
final technicianProfileProvider =
    StateNotifierProvider<TechnicianProfileNotifier, TechnicianProfileModel?>(
        (ref) {
  return TechnicianProfileNotifier(ref);
});

class TechnicianProfileNotifier extends StateNotifier<TechnicianProfileModel?> {
  final Ref _ref;
  TechnicianProfileNotifier(this._ref) : super(null);

  Future<void> fetchProfile() async {
    try {
      final user = _ref.read(authProvider);
      if (user == null) return;
      final dio = _ref.read(apiClientProvider);
      final res = await dio.get('/technicians/me?user_id=${user.id}');
      if (res.statusCode == 200) {
        state = TechnicianProfileModel.fromJson(res.data);
      }
    } catch (e) {
      debugPrint('[Profile] Fetch error: $e');
    }
  }

  Future<void> updateCategories(List<String> categories) async {
    try {
      final user = _ref.read(authProvider);
      if (user == null) return;
      final dio = _ref.read(apiClientProvider);
      await dio.put('/technicians/me/categories',
          data: {'category_ids': categories});
      await fetchProfile();
    } catch (e) {
      debugPrint('[Profile] Update categories error: $e');
    }
  }
}

// --- 3. Availability Toggle Provider ---
final isOnlineProvider =
    StateNotifierProvider<OnlineStatusNotifier, bool>((ref) {
  return OnlineStatusNotifier(ref);
});

class OnlineStatusNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _gpsTimer;

  OnlineStatusNotifier(this._ref) : super(true) {
    _startGpsBroadcast();
  }

  void toggleOnline() {
    state = !state;
    if (state) {
      _startGpsBroadcast();
    } else {
      _gpsTimer?.cancel();
    }
  }

  void _startGpsBroadcast() {
    _gpsTimer?.cancel();
    _fetchAndBroadcastPosition();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!state) return;
      final isOnline = _ref.read(serverConnectivityProvider);
      if (!isOnline) return;
      
      _fetchAndBroadcastPosition();
    });
  }

  Future<void> _fetchAndBroadcastPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      final Position position = pos ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );

      _ref.read(liveLocationProvider.notifier).state = position;

      final user = _ref.read(authProvider);
      if (user != null) {
        final dio = _ref.read(apiClientProvider);
        await dio.post('/technicians/me/location?user_id=${user.id}', data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      debugPrint('[GPS Broadcast] Error: $e');
    }
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }
}

// --- 4. Live GPS Location Provider ---
final liveLocationProvider = StateProvider<Position?>((ref) => null);

// --- 5. Incoming Match Offer Provider ---
final incomingOfferProvider =
    StateNotifierProvider<IncomingOfferNotifier, MatchOfferModel?>((ref) {
  return IncomingOfferNotifier(ref);
});

class IncomingOfferNotifier extends StateNotifier<MatchOfferModel?> {
  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _countdownTimer;
  int remainingSeconds = 90;

  IncomingOfferNotifier(this._ref) : super(null);

  void receiveOffer(MatchOfferModel offer) {
    state = offer;
    remainingSeconds = offer.timeoutSeconds;
    _playSound();

    AppToast.show(
      null,
      title: '🚨 Demande d\'Intervention Reçue !',
      message:
          '${offer.categoryName} • ${offer.addressText} (~${offer.distanceKm.toStringAsFixed(1)} km)',
      type: AppToastType.warning,
      duration: const Duration(seconds: 6),
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
      } else {
        dismissOffer();
      }
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('[Audio] Play error: $e');
    }
  }

  Future<bool> acceptOffer() async {
    if (state == null) return false;
    final bookingId = state!.bookingId;
    dismissOffer();

    try {
      final user = _ref.read(authProvider);
      final dio = _ref.read(apiClientProvider);
      final res = await dio.patch('/bookings/$bookingId/status', data: {
        'status': 'matched',
        'technician_id': user?.id,
      });
      if (res.statusCode == 200) {
        _ref.read(activeMissionProvider.notifier).fetchActiveMission();
        AppToast.show(
          null,
          title: 'Mission Acceptée !',
          message: 'Navigation et suivi client activés.',
          type: AppToastType.success,
        );
        return true;
      }
    } catch (e) {
      debugPrint('[Offer] Accept error: $e');
    }
    return false;
  }

  Future<bool> declineOffer() async {
    if (state == null) return false;
    final bookingId = state!.bookingId;
    dismissOffer();

    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post('/bookings/$bookingId/decline');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[Offer] Decline error: $e');
    }
    return false;
  }

  void dismissOffer() {
    _countdownTimer?.cancel();
    state = null;
  }
}

// --- 6. Active Mission Provider ---
final activeMissionProvider =
    StateNotifierProvider<ActiveMissionNotifier, BookingModel?>((ref) {
  return ActiveMissionNotifier(ref);
});

class ActiveMissionNotifier extends StateNotifier<BookingModel?> {
  final Ref _ref;
  Timer? _pollTimer;

  ActiveMissionNotifier(this._ref) : super(null) {
    fetchActiveMission();
    _startPollLoop();
  }

  void _startPollLoop() {
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final isOnline = _ref.read(serverConnectivityProvider);
      if (isOnline) {
        fetchActiveMission();
      }
    });
  }

  Future<void> fetchActiveMission() async {
    final user = _ref.read(authProvider);
    if (user == null) return;

    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.get('/bookings/user/${user.id}?role=technician');
      if (res.statusCode == 200) {
        final List<dynamic> list = res.data;
        final active = list.firstWhere(
          (b) => ['matched', 'in_progress', 'on_site'].contains(b['status']),
          orElse: () => null,
        );
        if (active != null) {
          state = BookingModel.fromJson(active);
        } else if (state != null && state!.status != 'completed') {
          state = null;
        }
      }
    } catch (e) {
      debugPrint('[ActiveMission] Fetch error: $e');
    }
  }

  Future<bool> updateStatus(String newStatus, [String? cancelReason]) async {
    if (state == null) return false;
    final bookingId = state!.id;

    try {
      final user = _ref.read(authProvider);
      final dio = _ref.read(apiClientProvider);
      final res = await dio.patch('/bookings/$bookingId/status', data: {
        'status': newStatus,
        'technician_id': user?.id,
        'cancellation_reason': cancelReason,
      });
      if (res.statusCode == 200) {
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          state = null;
        } else {
          state = state!.copyWith(status: newStatus);
        }
        return true;
      }
    } catch (e) {
      debugPrint('[ActiveMission] Update status error: $e');
    }
    return false;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

// --- 7. Interventions History Provider ---
final interventionsHistoryProvider =
    FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  try {
    final dio = ref.read(apiClientProvider);
    final res = await dio.get('/bookings/user/${user.id}?role=technician');
    if (res.statusCode == 200) {
      final List<dynamic> list = res.data;
      return list.map((e) => BookingModel.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('[History] Fetch error: $e');
  }
  return [];
});

// --- 8. Pro WebSocket Provider ---
final proWebSocketProvider = Provider<ProWebSocketService>((ref) {
  return ProWebSocketService(ref);
});

class ProWebSocketService {
  final Ref _ref;
  WebSocketChannel? _channel;

  ProWebSocketService(this._ref);

  void connect() {
    final user = _ref.read(authProvider);
    final token = _ref.read(authProvider.notifier).token;
    if (user == null) return;

    final isOnline = _ref.read(serverConnectivityProvider);
    if (!isOnline) {
      Future.delayed(const Duration(seconds: 5), connect);
      return;
    }

    try {
      final tokenQuery =
          (token != null && token.isNotEmpty) ? '?token=$token' : '';
      final url = '${AppConfig.wsBaseUrl}/users/${user.id}$tokenQuery';
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.ready.catchError((e) {
        debugPrint('[WS] Ready catchError: $e');
      });

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final type = data['type'];
            if (type == 'MATCH_OFFER') {
              final offer = MatchOfferModel.fromJson(data);
              _ref.read(incomingOfferProvider.notifier).receiveOffer(offer);
            } else if (type == 'STATUS_CHANGE') {
              _ref.read(activeMissionProvider.notifier).fetchActiveMission();
              AppToast.show(
                null,
                title: 'Mise à jour d\'intervention',
                message: 'Le statut de la mission a changé.',
                type: AppToastType.info,
              );
            }
          } catch (e) {
            debugPrint('[WS] Message parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('[WS] Error: $err');
          Future.delayed(const Duration(seconds: 5), connect);
        },
        onDone: () {
          debugPrint('[WS] Connection closed');
          Future.delayed(const Duration(seconds: 5), connect);
        },
      );
    } catch (e) {
      debugPrint('[WS] Connect exception: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
