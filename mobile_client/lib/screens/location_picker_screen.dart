import 'dart:async';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../core/map_style.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  LatLng _centerPosition = const LatLng(14.6928, -17.4467); // Dakar
  bool _isMapLoading = true;
  bool _isLoadingAddress = false;
  String _currentAddress = 'Recherche en cours...';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isMapLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isMapLoading = false);
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _centerPosition = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
      });
      
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_centerPosition, 16.0));
      }
      _updateAddressForLocation(_centerPosition);
    } catch (e) {
      setState(() => _isMapLoading = false);
      _updateAddressForLocation(_centerPosition);
    }
  }

  Future<void> _updateAddressForLocation(LatLng pos) async {
    setState(() {
      _isLoadingAddress = true;
      _currentAddress = 'Recherche en cours...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String name = '';
        if (p.street != null && p.street!.isNotEmpty && !p.street!.contains('+')) {
          name = p.street!;
        } else if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          name = p.subLocality!;
        } else if (p.locality != null && p.locality!.isNotEmpty) {
          name = p.locality!;
        }
        
        setState(() {
          _currentAddress = '$name, ${p.locality ?? ''}'.trim().replaceAll(RegExp(r'^,\s*'), '');
          if (_currentAddress.isEmpty) _currentAddress = 'Position sélectionnée';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _onConfirm() {
    ref.read(selectedLocationProvider.notifier).state = _currentAddress;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isMapLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centerPosition,
                    zoom: 16.0,
                  ),
                  style: kMinimalMapStyle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    _mapController = controller;
                  },
                  onCameraMove: (CameraPosition position) {
                    _centerPosition = position.target;
                  },
                  onCameraIdle: () {
                    _updateAddressForLocation(_centerPosition);
                  },
                ),
          
          // Center Marker (Uber style)
          if (!_isMapLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0), // Adjust for pin tip
                child: Icon(
                  LucideIcons.map_pin,
                  size: 40,
                  color: AppTheme.primaryEmerald,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
              ),
            ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                  ]
                ),
                child: const Icon(LucideIcons.arrow_left, color: AppTheme.textDark),
              ),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))
                ]
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Définir la position',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.map_pin, color: AppTheme.primaryEmerald, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isLoadingAddress 
                                ? const SizedBox(
                                    height: 16, 
                                    width: 16, 
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryEmerald)
                                  )
                                : Text(
                                    _currentAddress,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmer cette position',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
