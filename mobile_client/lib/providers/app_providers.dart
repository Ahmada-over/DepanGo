import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../core/config.dart';
import 'connectivity_provider.dart';
import '../core/api_client.dart';
import '../core/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final String apiBaseUrl = AppConfig.apiBaseUrl;
final String wsBaseUrl = AppConfig.wsBaseUrl;

final selectedLocationProvider =
    StateProvider<String>((ref) => 'Point E, Dakar, Sénégal');

class AuthNotifier extends StateNotifier<UserModel?> {
  final SharedPreferences prefs;
  final Ref ref;

  AuthNotifier(this.prefs, this.ref) : super(null) {
    _loadSession();
  }

  void _loadSession() {
    final userStr = prefs.getString('user_session');
    if (userStr != null) {
      try {
        final data = jsonDecode(userStr);
        state = UserModel.fromJson(data, token: data['token']);
      } catch (e) {
        debugPrint('Failed to load session: $e');
      }
    }
  }

  bool isLoading = false;
  String? errorMessage;

  Future<bool> firebaseLogin(String idToken, {String? name}) async {
    isLoading = true;
    errorMessage = null;
    state = state; // trigger rebuild if needed, though not strictly required
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/auth/firebase-login', data: {
        'id_token': idToken,
        if (name != null) 'name': name,
        'role': 'client',
      });
      if (res.statusCode == 200) {
        final data = res.data;
        final user = UserModel.fromJson(data['user'], token: data['access_token']);
        state = user;
        
        final sessionData = data['user'];
        sessionData['token'] = data['access_token'];
        await prefs.setString('user_session', jsonEncode(sessionData));
        
        isLoading = false;
        return true;
      }
    } catch (e) {
      debugPrint('[Auth] Firebase Login error: $e');
      errorMessage = e.toString();
    }
    isLoading = false;
    state = state; // trigger rebuild
    return false;
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user =
            UserModel.fromJson(data['user'], token: data['access_token']);
        state = user;

        final sessionData = data['user'];
        sessionData['token'] = data['access_token'];
        await prefs.setString('user_session', jsonEncode(sessionData));

        isLoading = false;
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Login Error: $e');
      if (e.response != null) {
        final err = e.response!.data;
        errorMessage = err is Map ? err['detail'] : 'Identifiants invalides';
      } else {
        errorMessage = 'Erreur de connexion';
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      errorMessage = 'Erreur de connexion';
    }
    isLoading = false;
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'client',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user =
            UserModel.fromJson(data['user'], token: data['access_token']);
        state = user;

        final sessionData = data['user'];
        sessionData['token'] = data['access_token'];
        await prefs.setString('user_session', jsonEncode(sessionData));

        isLoading = false;
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Register Error: $e');
      if (e.response != null) {
        final err = e.response!.data;
        errorMessage = err is Map ? err['detail'] : 'Échec de l\'inscription';
      } else {
        errorMessage = 'Erreur lors de l\'inscription';
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      errorMessage = 'Erreur lors de l\'inscription';
    }
    isLoading = false;
    return false;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (state == null) return;
    state = UserModel(
      id: state!.id,
      name: name,
      email: email,
      phone: phone,
      role: state!.role,
      token: state!.token,
    );
    try {
      final dio = ref.read(apiClientProvider);
      await dio.patch(
        '/technicians/me/profile?user_id=${state!.id}',
        data: {'name': name, 'email': email, 'phone': phone},
      );
    } catch (e) {
      debugPrint('Client profile update error: $e');
    }
  }

  String? get token => state?.token;

  
  void updateUser(Map<String, dynamic> data) async {
    final token = state?.token ?? '';
    final user = UserModel.fromJson(data, token: token);
    state = user;
    final sessionData = data;
    sessionData['token'] = token;
    await prefs.setString('user_session', jsonEncode(sessionData));
  }

  void logout() {
    state = null;
    prefs.remove('user_session');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs, ref);
});

class NotificationNotifier extends StateNotifier<List<AppNotificationModel>> {
  NotificationNotifier()
      : super([
          AppNotificationModel(
            id: 'notif_welcome',
            title: 'Bienvenue sur depanGo Dakar !',
            message:
                'Trouvez et réservez des techniciens certifiés en quelques clics.',
            time: DateTime.now(),
            type: 'system',
          ),
        ]);

  final AudioPlayer _audioPlayer = AudioPlayer();

  void addNotification(
      {required String title, required String message, String type = 'info'}) {
    // Jouer le son de notification
    try {
      _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Erreur lors de la lecture du son : $e');
    }

    AppToastType toastType = AppToastType.info;
    if (type == 'status' || type == 'success') {
      toastType = AppToastType.success;
    } else if (type == 'warning') {
      toastType = AppToastType.warning;
    } else if (type == 'error') {
      toastType = AppToastType.error;
    }

    AppToast.show(
      null,
      title: title,
      message: message,
      type: toastType,
    );

    // Déclencher la notification locale native du téléphone
    LocalNotificationService.instance.showNotification(
      title: title,
      body: message,
    );

    state = [
      AppNotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        time: DateTime.now(),
        type: type,
      ),
      ...state,
    ];
  }

  void markAllAsRead() {
    state = state.map((n) {
      n.isRead = true;
      return n;
    }).toList();
  }
}

final appNotificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotificationModel>>(
        (ref) {
  return NotificationNotifier();
});

final categoryListProvider =
    FutureProvider<List<ServiceCategoryModel>>((ref) async {
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/categories');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => ServiceCategoryModel.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('API Error: $e');
  }
  return [
    ServiceCategoryModel(
        id: 'cat_plumbing',
        name: 'Plomberie',
        description: 'Fuites, tuyauterie, WC',
        iconName: 'water'),
    ServiceCategoryModel(
        id: 'cat_electrical',
        name: 'Électricité',
        description: 'Panne de courant, câblage',
        iconName: 'bolt'),
    ServiceCategoryModel(
        id: 'cat_hvac',
        name: 'Climatisation',
        description: 'Recharge gaz, entretien clim',
        iconName: 'ac_unit'),
    ServiceCategoryModel(
        id: 'cat_appliances',
        name: 'Électroménager',
        description: 'Réparation frigo & laves',
        iconName: 'kitchen'),
  ];
});

final registeredTechniciansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/technicians');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return List<Map<String, dynamic>>.from(data);
    }
  } catch (e) {
    debugPrint('Registered Technicians Fetch Error: $e');
  }
  return [];
});

/// Provider filtré : renvoie uniquement les techniciens ayant la catégorie demandée.
final categoryFilteredTechniciansProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, categoryId) async {
  final all = await ref.watch(registeredTechniciansProvider.future);
  if (categoryId == 'cat_express') {
    return all;
  }
  return all.where((t) {
    final cats = (t['category_ids'] as List?)?.cast<String>() ?? [];
    return cats.contains(categoryId);
  }).toList();
});

final techLiveLocationProvider =
    StateProvider<Map<String, double>?>((ref) => null);

final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final currentUser = ref.watch(authProvider);
  final clientId = currentUser?.id ?? 'user_client_demo';

  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/bookings/user/$clientId?role=client');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => BookingModel.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('User Bookings Fetch Error: $e');
  }
  return [];
});

class BookingNotifier extends StateNotifier<BookingModel?> {
  final Ref _ref;
  BookingNotifier(this._ref) : super(null);

  WebSocketChannel? _channel;
  final List<ChatMessageModel> messages = [];

  Future<BookingModel?> createBooking({
    required String categoryId,
    required String description,
    required String addressText,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? preferredTechnicianId,
  }) async {
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post(
        '/bookings',
        data: {
          'category_id': categoryId,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'address_text': addressText,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (preferredTechnicianId != null)
            'preferred_technician_id': preferredTechnicianId,
        },
      );

      if (response.statusCode == 200) {
        final booking = BookingModel.fromJson(response.data);
        state = booking;
        _startStatusSync(booking.id);
        _ref.refresh(userBookingsProvider);

        _ref.read(appNotificationsProvider.notifier).addNotification(
              title: 'Demande d\'intervention créée !',
              message:
                  'Votre réservation a été transmise aux techniciens à proximité.',
              type: 'status',
            );

        return booking;
      }
    } catch (e) {
      debugPrint('Booking Creation Error: $e');
    }

    return null;
  }

  int _reconnectDelay = 1; // seconds, doubles on each retry
  bool _intentionalClose = false;

  void loadActiveBooking(BookingModel booking) {
    state = booking;
    _startStatusSync(booking.id);
  }

  /// Fetch user's bookings and auto-load the most relevant active one
  Future<void> fetchActiveBooking() async {
    try {
      final currentUser = _ref.read(authProvider);
      if (currentUser == null) return;
      final dio = _ref.read(apiClientProvider);
      final response =
          await dio.get('/bookings/user/${currentUser.id}?role=client');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
        final activeList = bookings
            .where((b) => !['completed', 'cancelled', 'no_technician_found']
                .contains(b.status))
            .toList();

        if (activeList.isEmpty) {
          if (state != null &&
              !['completed', 'cancelled', 'no_technician_found']
                  .contains(state!.status)) {
            state = null;
            _stopPolling();
          }
          return;
        }

        // If we already have an active booking selected and it's still active, keep it!
        if (state != null) {
          final existing = activeList.firstWhere(
            (b) => b.id == state!.id,
            orElse: () => activeList.first,
          );
          if (existing.id == state!.id) {
            state = existing;
            return;
          }
        }

        // Sort by priority: active interventions (on_site > in_progress > matched) first, then pending
        activeList.sort((a, b) {
          int priority(String s) {
            if (s == 'on_site') return 4;
            if (s == 'in_progress') return 3;
            if (s == 'matched') return 2;
            if (s == 'pending') return 1;
            return 0;
          }

          return priority(b.status).compareTo(priority(a.status));
        });

        final target = activeList.first;
        state = target;
        _startStatusSync(target.id);
      }
    } catch (e) {
      debugPrint('Fetch Active Booking Error: $e');
    }
  }

  Timer? _pollTimer;

  /// Start both WebSocket and polling for a booking
  void _startStatusSync(String bookingId) {
    _connectWebSocket(bookingId);
    _startPolling(bookingId);
  }

  /// Poll the booking status every 5 seconds as a reliable fallback
  void _startPolling(String bookingId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (state == null || state!.id != bookingId) {
        _stopPolling();
        return;
      }

      // Skip polling if we know server is offline
      final isOnline = _ref.read(serverConnectivityProvider);
      if (!isOnline) return;

      try {
        final dio = _ref.read(apiClientProvider);
        final response = await dio.get('/bookings/$bookingId');
        if (response.statusCode == 200 &&
            state != null &&
            state!.id == bookingId) {
          final fresh = BookingModel.fromJson(response.data);
          if (fresh.status != state!.status) {
            debugPrint(
                '[POLL] Status changed for ${bookingId.substring(0, 8)}: ${state!.status} → ${fresh.status}');
            state = fresh;
            _ref.refresh(userBookingsProvider);
            _ref.read(appNotificationsProvider.notifier).addNotification(
                  title: 'Changement de Statut !',
                  message: 'Statut actuel du dossier : ${fresh.status}',
                  type: 'status',
                );
          }
          // Stop polling if booking is terminal
          if (['completed', 'cancelled', 'no_technician_found', 'expired']
              .contains(fresh.status)) {
            _stopPolling();
          }
        }
      } catch (e) {
        debugPrint('[POLL] Error: $e');
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> retryBooking() async {
    if (state == null) return;
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post('/bookings/${state!.id}/retry');
      if (response.statusCode == 200) {
        state = BookingModel.fromJson(response.data);
        _startStatusSync(state!.id);
      }
    } catch (e) {
      debugPrint('[Retry] Error: $e');
    }
  }

  void _connectWebSocket(String bookingId) {
    _intentionalClose = true;
    _channel?.sink.close();
    _intentionalClose = false;

    try {
      final token = _ref.read(authProvider)?.token ?? '';
      final wsChannel = WebSocketChannel.connect(
          Uri.parse('$wsBaseUrl/bookings/$bookingId?token=$token'));
      _channel = wsChannel;
      _reconnectDelay = 1;

      _channel!.ready.catchError((e) {
        debugPrint('[WS] Ready catchError: $e');
      });

      _channel!.stream.listen(
        (event) {
          final data = jsonDecode(event);
          _handleWsEvent(data);
        },
        onDone: () {
          debugPrint('[WS] Connection closed for booking $bookingId');
        },
        onError: (e) {
          debugPrint('[WS] Error: $e');
        },
      );
    } catch (e) {
      debugPrint('[WS] Connect Error: $e — polling will handle sync');
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final eventBookingId = data['booking_id'] as String?;

    if (type == 'STATUS_UPDATE') {
      final newStatus = data['status'] as String? ?? 'matched';
      // Only mutate state if this event is specifically for the currently active booking
      if (state != null &&
          (eventBookingId == null || eventBookingId == state!.id)) {
        state = state!.copyWith(
          status: newStatus,
          technicianId: data['technician_id'] ?? state!.technicianId,
          scheduledEta: data['scheduled_eta'] ?? state!.scheduledEta,
        );

        if (['completed', 'cancelled', 'no_technician_found']
            .contains(newStatus)) {
          _stopPolling();
        }

        _ref.refresh(userBookingsProvider);
        _ref.read(appNotificationsProvider.notifier).addNotification(
              title: 'Changement de Statut !',
              message: 'Statut actuel du dossier : $newStatus',
              type: 'status',
            );
      } else {
        _ref.refresh(userBookingsProvider);
      }
    } else if (type == 'NO_TECHNICIAN') {
      if (state != null &&
          (eventBookingId == null || eventBookingId == state!.id)) {
        state = state!.copyWith(
          status: 'no_technician_found',
          technicianId: null,
          scheduledEta: null,
        );
        _stopPolling();
      }
      _ref.refresh(userBookingsProvider);
      _ref.read(appNotificationsProvider.notifier).addNotification(
            title: 'Aucun technicien disponible',
            message: data['message'] ??
                'Aucun technicien qualifié disponible pour le moment.',
            type: 'warning',
          );
    } else if (type == 'LOCATION_UPDATE') {
      if (state != null &&
          (eventBookingId == null || eventBookingId == state!.id)) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _ref.read(techLiveLocationProvider.notifier).state = {
            'latitude': lat,
            'longitude': lng,
          };
        }
        if (data['eta'] != null) {
          state = state!.copyWith(scheduledEta: data['eta']);
        }
      }
    } else if (type == 'NEW_MESSAGE') {
      final msg = ChatMessageModel.fromJson(data);
      if (state != null && (msg.bookingId == state!.id)) {
        messages.add(msg);
      }

      final currentUser = _ref.read(authProvider);
      final currentUserId = currentUser?.id ?? 'user_client_demo';

      if (msg.senderId != currentUserId) {
        _ref.read(appNotificationsProvider.notifier).addNotification(
              title: 'Message de ${msg.senderName}',
              message: msg.content,
              type: 'chat',
            );
      }
    }
  }

  void sendMessage(String content) {
    final currentUser = _ref.read(authProvider);
    final senderId = currentUser?.id ?? 'user_client_demo';
    final senderName = currentUser?.name ?? 'Mamadou Diop';

    if (_channel != null && state != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'NEW_MESSAGE',
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
      }));
    }
  }

  Future<void> submitReview(int rating, String comment) async {
    if (state == null) return;

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post(
        '/bookings/${state!.id}/review',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
    } catch (e) {
      debugPrint('Submit Review Error: $e');
    }
  }

  Future<void> cancelBooking(String reason) async {
    if (state == null) return;

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.patch(
        '/bookings/${state!.id}/status',
        data: {'status': 'cancelled', 'cancellation_reason': reason},
      );
      if (response.statusCode == 200) {
        _stopPolling();
        state = state!.copyWith(status: 'cancelled');
      }
    } catch (e) {
      debugPrint('Cancel Booking Error: $e');
    }
  }
}

final activeBookingProvider =
    StateNotifierProvider<BookingNotifier, BookingModel?>((ref) {
  return BookingNotifier(ref);
});
