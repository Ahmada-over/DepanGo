import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../core/config.dart';
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

  AuthNotifier(this.prefs) : super(null) {
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
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user =
            UserModel.fromJson(data['user'], token: data['access_token']);
        state = user;
        
        final sessionData = data['user'];
        sessionData['token'] = data['access_token'];
        await prefs.setString('user_session', jsonEncode(sessionData));
        
        isLoading = false;
        return true;
      } else {
        final err = jsonDecode(response.body);
        errorMessage = err['detail'] ?? 'Identifiants invalides';
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
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'client',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user =
            UserModel.fromJson(data['user'], token: data['access_token']);
        state = user;
        
        final sessionData = data['user'];
        sessionData['token'] = data['access_token'];
        await prefs.setString('user_session', jsonEncode(sessionData));
        
        isLoading = false;
        return true;
      } else {
        final err = jsonDecode(response.body);
        errorMessage = err['detail'] ?? 'Échec de l\'inscription';
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
      await http.patch(
        Uri.parse('$apiBaseUrl/technicians/me/profile?user_id=${state!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
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
  return AuthNotifier(prefs);
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
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
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
  final currentUser = ref.watch(authProvider);
  try {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/technicians'),
      headers: {
        if (currentUser?.token != null)
          'Authorization': 'Bearer ${currentUser!.token}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
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

final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final currentUser = ref.watch(authProvider);
  final clientId = currentUser?.id ?? 'user_client_demo';

  try {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/bookings/user/$clientId?role=client'),
      headers: {
        if (currentUser?.token != null)
          'Authorization': 'Bearer ${currentUser!.token}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
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
    String? preferredTechnicianId,
  }) async {
    final currentUser = _ref.read(authProvider);
    final clientId = currentUser?.id ?? 'user_client_demo';

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          if (currentUser?.token != null)
            'Authorization': 'Bearer ${currentUser!.token}',
        },
        body: jsonEncode({
          'category_id': categoryId,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'address_text': addressText,
          if (preferredTechnicianId != null) 'preferred_technician_id': preferredTechnicianId,
        }),
      );

      if (response.statusCode == 200) {
        final booking = BookingModel.fromJson(jsonDecode(response.body));
        state = booking;
        _connectWebSocket(booking.id);
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

  void _connectWebSocket(String bookingId) {
    _intentionalClose = true;
    _channel?.sink.close();
    _intentionalClose = false;
    try {
      final token = _ref.read(authProvider)?.token ?? '';
      final wsChannel = WebSocketChannel.connect(
          Uri.parse('$wsBaseUrl/bookings/$bookingId?token=$token'));
      _channel = wsChannel;
      _reconnectDelay = 1; // Reset on successful connect
      _channel!.stream.listen(
        (event) {
          final data = jsonDecode(event);
          _handleWsEvent(data);
        },
        onDone: () {
          if (!_intentionalClose && _channel == wsChannel) {
            debugPrint(
                '[WS] Connection closed. Reconnecting in ${_reconnectDelay}s...');
            Future.delayed(Duration(seconds: _reconnectDelay), () {
              _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
              _connectWebSocket(bookingId);
            });
          }
        },
        onError: (e) {
          if (!_intentionalClose && _channel == wsChannel) {
            debugPrint('[WS] Error: $e. Reconnecting in ${_reconnectDelay}s...');
            Future.delayed(Duration(seconds: _reconnectDelay), () {
              _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
              _connectWebSocket(bookingId);
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[WS] Connect Error: $e. Retrying in ${_reconnectDelay}s...');
      Future.delayed(Duration(seconds: _reconnectDelay), () {
        _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
        _connectWebSocket(bookingId);
      });
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';

    if (type == 'STATUS_UPDATE') {
      if (state != null) {
        state = BookingModel(
          id: state!.id,
          clientId: state!.clientId,
          categoryId: state!.categoryId,
          description: state!.description,
          photoUrl: state!.photoUrl,
          status: data['status'] ?? state!.status,
          latitude: state!.latitude,
          longitude: state!.longitude,
          addressText: state!.addressText,
          technicianId: data['technician_id'] ?? state!.technicianId,
          scheduledEta: data['scheduled_eta'] ?? state!.scheduledEta,
          createdAt: state!.createdAt,
        );
      }
      _ref.refresh(userBookingsProvider);
      _ref.read(appNotificationsProvider.notifier).addNotification(
            title: 'Changement de Statut !',
            message: 'Statut actuel du dossier : ${data["status"]}',
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
      if (state != null) {
        state = BookingModel(
          id: state!.id,
          clientId: state!.clientId,
          categoryId: state!.categoryId,
          description: state!.description,
          photoUrl: state!.photoUrl,
          status: state!.status,
          latitude: (data['latitude'] as num?)?.toDouble() ?? state!.latitude,
          longitude:
              (data['longitude'] as num?)?.toDouble() ?? state!.longitude,
          addressText: state!.addressText,
          technicianId: state!.technicianId,
          scheduledEta: data['eta'] ?? state!.scheduledEta ?? '12 mins',
          createdAt: state!.createdAt,
        );
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
    final token = _ref.read(authProvider)?.token;

    try {
      await http.post(
        Uri.parse('$apiBaseUrl/bookings/${state!.id}/review'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );
    } catch (e) {
      debugPrint('Submit Review Error: $e');
    }
  }

  Future<void> cancelBooking(String reason) async {
    if (state == null) return;
    final token = _ref.read(authProvider)?.token;

    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/bookings/${state!.id}/status'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body:
            jsonEncode({'status': 'cancelled', 'cancellation_reason': reason}),
      );
      if (response.statusCode == 200) {
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
