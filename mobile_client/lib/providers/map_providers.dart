import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../providers/app_providers.dart';

// Modèle pour le technicien sur la carte
class MapTechnician {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final List<String> categoryIds;
  final String transportMode;

  MapTechnician({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.categoryIds,
    required this.transportMode,
  });

  factory MapTechnician.fromJson(Map<String, dynamic> json) {
    return MapTechnician(
      id: json['id'] ?? json['technician_id'] ?? '',
      name: json['name'] ?? 'Technicien',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      rating: (json['average_rating'] ?? 5.0).toDouble(),
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      transportMode: json['transport_mode'] ?? 'moto',
    );
  }

  MapTechnician copyWith({double? latitude, double? longitude}) {
    return MapTechnician(
      id: id,
      name: name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating,
      categoryIds: categoryIds,
      transportMode: transportMode,
    );
  }
}

// StateNotifier pour gérer la liste des techniciens sur la carte
class MapTechniciansNotifier extends StateNotifier<List<MapTechnician>> {
  WebSocketChannel? _channel;
  String? _currentCategoryId;
  final Ref ref;

  MapTechniciansNotifier(this.ref) : super([]);

  Future<void> initMap(String categoryId, double lat, double lng) async {
    _currentCategoryId = categoryId;

    // 1. Fetch initial nearby technicians
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        '/technicians/nearby',
        queryParameters: {
          'category_id': categoryId,
          'lat': lat,
          'lng': lng,
          'radius_km': 50,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        state = data.map((json) => MapTechnician.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur fetch nearby: $e');
    }

    // 2. Connect to Area WebSocket
    _connectWebSocket(categoryId);
  }

  void _connectWebSocket(String categoryId) {
    _channel?.sink.close();

    final wsUrl = Uri.parse('${AppConfig.wsBaseUrl}/area/$categoryId');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel?.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'LOCATION_UPDATE') {
        final techId = data['technician_id'];
        final lat = (data['latitude'] ?? 0).toDouble();
        final lng = (data['longitude'] ?? 0).toDouble();
        final name = data['name'] ?? 'Technicien';
        final rating = (data['average_rating'] ?? 5.0).toDouble();
        final transportMode = data['transport_mode'] ?? 'moto';

        // Update existing or add new (without full details, but enough for marker)
        final existingIndex = state.indexWhere((t) => t.id == techId);
        if (existingIndex >= 0) {
          final updatedList = List<MapTechnician>.from(state);
          updatedList[existingIndex] = updatedList[existingIndex]
              .copyWith(latitude: lat, longitude: lng);
          state = updatedList;
        } else {
          // Si nouveau technicien, on l'ajoute avec des infos basiques
          state = [
            ...state,
            MapTechnician(
              id: techId,
              name: name,
              latitude: lat,
              longitude: lng,
              rating: rating,
              categoryIds: [categoryId],
              transportMode: transportMode,
            )
          ];
        }
      }
    }, onError: (error) {
      print('Area WS Error: $error');
    }, onDone: () {
      print('Area WS Closed');
    });
  }

  void closeMap() {
    _channel?.sink.close();
    _channel = null;
    state = [];
  }
}

final mapTechniciansProvider = StateNotifierProvider.autoDispose<
    MapTechniciansNotifier, List<MapTechnician>>((ref) {
  final notifier = MapTechniciansNotifier(ref);
  ref.onDispose(() {
    notifier.closeMap();
  });
  return notifier;
});
