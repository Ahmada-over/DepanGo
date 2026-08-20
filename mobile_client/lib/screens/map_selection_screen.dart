import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../providers/app_providers.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/config.dart';
import '../core/map_markers.dart';
import '../core/map_style.dart';
import 'create_booking_screen.dart';

class MapSelectionScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final double? basePrice;

  const MapSelectionScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.basePrice,
  });

  @override
  ConsumerState<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends ConsumerState<MapSelectionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  LatLng? _currentPosition;
  bool _isLoading = true;
  final bool _isDragging = false;
  bool _markersReady = false;
  TechnicianLocation? _selectedTech;
  String _addressText = 'Chargement…';

  WebSocketChannel? _channel;
  final Map<String, TechnicianLocation> _techLocations = {};

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _getUserLocation();
    _connectWebSocket();
  }

  Future<void> _loadMarkerIcons() async {
    if (!mounted) return;
    setState(() {
      _techMotoIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _techCarIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _markersReady = true;
    });
  }

  BitmapDescriptor? _techMotoIcon;
  BitmapDescriptor? _techCarIcon;

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setFallbackLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setFallbackLocation();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setFallbackLocation();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _isLoading = false;
      });
      _getAddressFromLatLng(latLng);
      _fetchNearbyTechnicians(latLng);
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    const fallback = LatLng(14.6937, -17.4441);
    setState(() {
      _currentPosition = fallback;
      _isLoading = false;
    });
    _getAddressFromLatLng(fallback);
    _fetchNearbyTechnicians(fallback);
  }

  Future<void> _fetchNearbyTechnicians(LatLng position) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        '/technicians/nearby',
        queryParameters: {
          'category_id': widget.categoryId,
          'lat': position.latitude,
          'lng': position.longitude,
          'radius_km': 25.0,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final newLocations = <String, TechnicianLocation>{};
        for (var item in data) {
          final techId = item['id'];
          newLocations[techId] = TechnicianLocation(
            id: techId,
            latitude: item['latitude'],
            longitude: item['longitude'],
            name: item['name'],
            averageRating: (item['average_rating'] as num?)?.toDouble() ?? 5.0,
            transportMode: item['transport_mode'] ?? 'moto',
            categoryIds: (item['category_ids'] as List?)?.cast<String>() ?? [],
          );
        }
        if (!mounted) return;
        setState(() {
          _techLocations
            ..clear()
            ..addAll(newLocations);
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial technicians: $e');
    }
  }

  void _connectWebSocket() {
    final wsUrl = '${AppConfig.wsBaseUrl}/area/${widget.categoryId}';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['type'] == 'LOCATION_UPDATE') {
          final techId = data['technician_id'];
          if (!mounted) return;
          setState(() {
            _techLocations[techId] = TechnicianLocation(
              id: techId,
              latitude: data['latitude'],
              longitude: data['longitude'],
              name: data['name'],
              averageRating:
                  (data['average_rating'] as num?)?.toDouble() ?? 5.0,
              transportMode: data['transport_mode'] ?? 'moto',
              categoryIds: _techLocations[techId]?.categoryIds ??
                  [data['category_id'] as String],
            );
          });
        }
      });
    } catch (e) {
      debugPrint('WS Area connection error: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final List<String> parts = [];

        final street = place.street?.trim();
        final subLocality = place.subLocality?.trim();
        final locality = place.locality?.trim();
        final name = place.name?.trim();

        if (street != null &&
            street.isNotEmpty &&
            !street.contains('+') &&
            !street.toLowerCase().contains('unnamed')) {
          parts.add(street);
        } else if (name != null &&
            name.isNotEmpty &&
            !name.contains('+') &&
            !name.toLowerCase().contains('unnamed')) {
          parts.add(name);
        }

        if (subLocality != null &&
            subLocality.isNotEmpty &&
            !parts.contains(subLocality)) {
          parts.add(subLocality);
        }

        if (locality != null &&
            locality.isNotEmpty &&
            !parts.contains(locality)) {
          parts.add(locality);
        }

        final address = parts.isNotEmpty
            ? parts.join(', ')
            : 'Dakar (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})';

        if (mounted) {
          setState(() {
            _addressText = address;
          });
          ref.read(selectedLocationProvider.notifier).state = _addressText;
        }
        return;
      }
    } catch (e) {
      debugPrint('[MapSelection] Geocoding error: $e');
    }

    final fallback =
        'Dakar (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})';
    if (mounted) {
      setState(() {
        _addressText = fallback;
      });
      ref.read(selectedLocationProvider.notifier).state = _addressText;
    }
  }

  Future<void> _recenterOnUser() async {
    if (_currentPosition == null || _mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 15),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    if (!_markersReady) return {};

    final markers = <Marker>{};
    for (final tech in _techLocations.values) {
      final isCar = tech.transportMode == 'voiture';
      markers.add(
        Marker(
          markerId: MarkerId(tech.id),
          position: LatLng(tech.latitude, tech.longitude),
          icon: isCar ? _techCarIcon! : _techMotoIcon!,
          anchor: const Offset(0.5, 0.85),
          onTap: () {
            if (!mounted) return;
            setState(() {
              _selectedTech = tech;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(tech.latitude, tech.longitude)),
            );
          },
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentPosition == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15,
              ),
              style: kMinimalMapStyle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              markers: _buildMarkers(),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),

          // Barre supérieure
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                MapFloatingButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    if (_selectedTech != null) {
                      setState(() => _selectedTech = null);
                      _recenterOnUser();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MapInfoChip(
                    icon: Icons.place_outlined,
                    title: _isDragging ? 'Déplacez la carte…' : _addressText,
                    subtitle:
                        '${_techLocations.length} technicien(s) à proximité',
                  ),
                ),
                const SizedBox(width: 10),
                MapFloatingButton(
                  icon: Icons.my_location_rounded,
                  onPressed: _recenterOnUser,
                ),
              ],
            ),
          ),

          // Panneau bas épuré
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (_selectedTech == null) ...[
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recherche de techniciens',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person,
                              color: AppTheme.primaryEmerald),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTech!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_selectedTech!.averageRating.toStringAsFixed(1)}  •  ${_selectedTech!.transportMode.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedTech!.categoryIds
                                    .map((c) => _formatCategory(c))
                                    .join(' • '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryEmerald,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(selectedLocationProvider.notifier).state =
                            _addressText;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateBookingScreen(
                              categoryId: widget.categoryId,
                              categoryName: widget.categoryName,
                              basePrice: widget.basePrice,
                              latitude: _currentPosition?.latitude,
                              longitude: _currentPosition?.longitude,
                              preferredTechnicianId: _selectedTech?.id,
                              preferredTechnicianName: _selectedTech?.name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedTech == null
                            ? 'Trouver le plus proche'
                            : 'Demander ce technicien',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String catId) {
    switch (catId) {
      case 'cat_hvac':
        return 'Climatisation';
      case 'cat_plumbing':
        return 'Plomberie';
      case 'cat_electrical':
        return 'Électricité';
      case 'cat_appliances':
        return 'Électroménager';
      case 'cat_cleaning':
        return 'Nettoyage';
      case 'cat_express':
        return 'Express';
      default:
        return catId.replaceAll('cat_', '').capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class TechnicianLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String name;
  final double averageRating;
  final String transportMode;
  final List<String> categoryIds;

  TechnicianLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.averageRating,
    required this.transportMode,
    required this.categoryIds,
  });
}
