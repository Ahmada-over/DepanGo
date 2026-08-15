import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/map_providers.dart';
import '../core/theme.dart';
import '../core/map_markers.dart';
import 'create_booking_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const MapScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setFallbackLocation();
      return;
    }

    var permission = await Geolocator.checkPermission();
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

      double lat = position.latitude;
      double lng = position.longitude;
      if (lat > 37.7 && lat < 37.8 && lng < -122.3 && lng > -122.5) {
        lat = 14.6928;
        lng = -17.4467;
      }

      setState(() {
        _currentPosition = LatLng(lat, lng);
        _isLoading = false;
      });
      ref.read(mapTechniciansProvider.notifier).initMap(
            widget.categoryId,
            lat,
            lng,
          );
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    setState(() {
      _currentPosition = const LatLng(14.6928, -17.4467);
      _isLoading = false;
    });
    ref.read(mapTechniciansProvider.notifier).initMap(
          widget.categoryId,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
  }

  void _showTechnicianDetails(MapTechnician tech) {
    final isCar = tech.transportMode == 'voiture';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: MapMarkerIcons.flutterMarker(
                      isCar ? MapMarkerType.technicianCar : MapMarkerType.technicianMoto,
                      size: 48,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tech.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            Text(
                              ' ${tech.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              isCar ? Icons.directions_car_filled_outlined : Icons.two_wheeler,
                              size: 15,
                              color: AppTheme.textMuted,
                            ),
                            Text(
                              ' ${isCar ? 'Voiture' : 'Moto'}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(
                          categoryId: widget.categoryId,
                          categoryName: widget.categoryName,
                          preferredTechnicianId: tech.id,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Demander ce technicien',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final technicians = ref.watch(mapTechniciansProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 13.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.techconnect.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: MapMarkerIcons.flutterMarker(MapMarkerType.clientDot, size: 48),
                        ),
                        ...technicians.map((tech) {
                          final isCar = tech.transportMode == 'voiture';
                          return Marker(
                            point: LatLng(tech.latitude, tech.longitude),
                            width: 52,
                            height: 52,
                            alignment: Alignment.bottomCenter,
                            child: MapMarkerIcons.flutterMarker(
                              isCar ? MapMarkerType.technicianCar : MapMarkerType.technicianMoto,
                              size: 52,
                              onTap: () => _showTechnicianDetails(tech),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      MapFloatingButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MapInfoChip(
                          icon: Icons.handyman_outlined,
                          title: widget.categoryName,
                          subtitle: '${technicians.length} technicien(s) en ligne',
                        ),
                      ),
                    ],
                  ),
                ),

                if (technicians.isEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 72,
                    left: 16,
                    right: 16,
                    child: MapInfoChip(
                      icon: Icons.search_rounded,
                      title: 'Recherche en cours…',
                      subtitle: 'Nous localisons les techniciens disponibles',
                    ),
                  ),

                Positioned(
                  right: 16,
                  bottom: 24,
                  child: MapFloatingButton(
                    icon: Icons.my_location_rounded,
                    onPressed: () => _mapController.move(_currentPosition!, 13.5),
                  ),
                ),
              ],
            ),
    );
  }
}
