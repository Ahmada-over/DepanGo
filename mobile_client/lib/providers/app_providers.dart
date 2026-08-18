import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../core/config.dart';
import '../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final user = UserModel.fromJson(data['user'], token: data['access_token']);
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
        final user = UserModel.fromJson(data['user'], token: data['access_token']);
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

final techLiveLocationProvider = StateProvider<Map<String, double>?>((ref) => null);

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
          if (preferredTechnicianId != null) 'preferred_technician_id': preferredTechnicianId,
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
  bool _pollingActive = false;

  void loadActiveBooking(BookingModel booking) {
    state = booking;
    _startStatusSync(booking.id);
  }

  /// Fetch user's bookings and auto-load the first active one
  Future<void> fetchActiveBooking() async {
    if (state != null && !['completed', 'cancelled', 'no_technician_found'].contains(state!.status)) {
      return; // Already have an active booking
    }
    try {
      final currentUser = _ref.read(authProvider);
      if (currentUser == null) return;
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get('/bookings/user/${currentUser.id}?role=client');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
        final active = bookings.where((b) =>
          !['completed', 'cancelled', 'no_technician_found'].contains(b.status)
        ).toList();
        if (active.isNotEmpty) {
          state = active.first;
          _startStatusSync(active.first.id);
        }
      }
    } catch (e) {
      debugPrint('Fetch Active Booking Error: $e');
    }
  }

  /// Start both WebSocket and polling for a booking
  void _startStatusSync(String bookingId) {
    _connectWebSocket(bookingId);
    _startPolling(bookingId);
  }

  /// Poll the booking status every 5 seconds as a reliable fallback
  void _startPolling(String bookingId) {
    _pollingActive = true;
    _pollLoop(bookingId);
  }

  void _stopPolling() {
    _pollingActive = false;
  }

  Future<void> _pollLoop(String bookingId) async {
    while (_pollingActive && state != null) {
      await Future.delayed(const Duration(seconds: 5));
      if (!_pollingActive || state == null) break;
      try {
        final dio = _ref.read(apiClientProvider);
        final response = await dio.get('/bookings/$bookingId');
        if (response.statusCode == 200 && state != null) {
          final fresh = BookingModel.fromJson(response.data);
          if (fresh.status != state!.status) {
            debugPrint('[POLL] Status changed: ${state!.status} → ${fresh.status}');
            state = fresh;
            _ref.refresh(userBookingsProvider);
            _ref.read(appNotificationsProvider.notifier).addNotification(
              title: 'Changement de Statut !',
              message: 'Statut actuel du dossier : ${fresh.status}',
              type: 'status',
            );
          }
          // Stop polling if booking is terminal
          if (['completed', 'cancelled', 'no_technician_found'].contains(fresh.status)) {
            _pollingActive = false;
          }
        }
      } catch (e) {
        debugPrint('[POLL] Error: $e');
      }
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
      _channel!.stream.listen(
        (event) {
          final data = jsonDecode(event);
          _handleWsEvent(data);
        },
        onDone: () {
          debugPrint('[WS] Connection closed for booking $bookingId');
          // Don't aggressively reconnect — polling handles status sync
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

    if (type == 'STATUS_UPDATE') {
      final newStatus = data['status'] as String? ?? 'matched';
      if (state != null) {
        state = BookingModel(
          id: state!.id,
          clientId: state!.clientId,
          categoryId: state!.categoryId,
          description: state!.description,
          photoUrl: state!.photoUrl,
          status: newStatus,
          latitude: state!.latitude,
          longitude: state!.longitude,
          addressText: state!.addressText,
          technicianId: data['technician_id'] ?? state!.technicianId,
          scheduledEta: data['scheduled_eta'] ?? state!.scheduledEta,
          createdAt: state!.createdAt,
        );
      } else if (data['booking_id'] != null) {
        fetchActiveBooking();
      }
      
      if (['completed', 'cancelled', 'no_technician_found'].contains(newStatus)) {
        _stopPolling();
      }

      _ref.refresh(userBookingsProvider);
      _ref.read(appNotificationsProvider.notifier).addNotification(
            title: 'Changement de Statut !',
            message: 'Statut actuel du dossier : $newStatus',
            type: 'status',
          );
    } else if (type == 'NO_TECHNICIAN') {
      // No qualified technician found — update state so matching screen can react
      if (state != null) {
        state = BookingModel(
          id: state!.id,
          clientId: state!.clientId,
          categoryId: state!.categoryId,
          description: state!.description,
          photoUrl: state!.photoUrl,
          status: 'no_technician_found',
          latitude: state!.latitude,
          longitude: state!.longitude,
          addressText: state!.addressText,
          technicianId: null,
          scheduledEta: null,
          createdAt: state!.createdAt,
        );
      }
      _ref.read(appNotificationsProvider.notifier).addNotification(
            title: 'Aucun technicien disponible',
            message: data['message'] ??
                'Aucun technicien qualifié disponible pour le moment.',
            type: 'warning',
          );
    } else if (type == 'LOCATION_UPDATE') {
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _ref.read(techLiveLocationProvider.notifier).state = {
          'latitude': lat,
          'longitude': lng,
        };
      }
      if (state != null && data['eta'] != null) {
        state = state!.copyWith(scheduledEta: data['eta']);
      }
    } else if (type == 'NEW_MESSAGE') {
      final msg = ChatMessageModel.fromJson(data);
      messages.add(msg);

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
