import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../core/map_markers.dart';
import '../core/map_style.dart';
import '../core/config.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class TrackingChatScreen extends ConsumerStatefulWidget {
  const TrackingChatScreen({super.key});

  @override
  ConsumerState<TrackingChatScreen> createState() => _TrackingChatScreenState();
}

class _TrackingChatScreenState extends ConsumerState<TrackingChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _msgController = TextEditingController();
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  String? _resolvedAddress;
  String? _lastGeocodedBookingId;

  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _techMotoIcon;
  BitmapDescriptor? _techCarIcon;
  List<LatLng> _fullRouteCoordinates = [];
  List<LatLng> _activePolylineCoordinates = [];
  LatLng? _lastCalculatedDestination;
  bool _isFetchingRoute = false;
  DateTime? _lastRouteFetchTime;
  bool _reviewShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMapIcons();
  }

  Future<void> _loadMapIcons() async {
    if (!mounted) return;
    setState(() {
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _techMotoIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _techCarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });
  }

  Future<void> _fetchRoute(double startLat, double startLng, double endLat, double endLng) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    _lastRouteFetchTime = DateTime.now();
    _lastCalculatedDestination = LatLng(endLat, endLng);

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: AppConfig.googleMapsApiKey);
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(startLat, startLng),
          destination: PointLatLng(endLat, endLng),
          mode: TravelMode.driving,
        ),
      );
      if (result.points.isNotEmpty) {
        final pts = result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
        if (mounted) {
          setState(() {
            _fullRouteCoordinates = pts;
            _activePolylineCoordinates = pts;
          });
        }
      } else {
        if (_fullRouteCoordinates.isEmpty && mounted) {
          final directLine = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
          setState(() {
            _fullRouteCoordinates = directLine;
            _activePolylineCoordinates = directLine;
          });
        }
      }
    } catch (e) {
      debugPrint('[Navigation] Route fetch error: $e');
      if (_fullRouteCoordinates.isEmpty && mounted) {
        final directLine = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
        setState(() {
          _fullRouteCoordinates = directLine;
          _activePolylineCoordinates = directLine;
        });
      }
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _updateOrRecalculateRoute(double techLat, double techLng, double destLat, double destLng) {
    final dest = LatLng(destLat, destLng);
    final isNewDestination = _lastCalculatedDestination == null ||
        (_lastCalculatedDestination!.latitude != dest.latitude ||
         _lastCalculatedDestination!.longitude != dest.longitude);

    // Initial fetch or new destination
    if (_fullRouteCoordinates.isEmpty || isNewDestination) {
      _fetchRoute(techLat, techLng, destLat, destLng);
      return;
    }

    // Check distance between technician and the planned route
    double minDistance = double.infinity;
    int closestIndex = 0;
    for (int i = 0; i < _fullRouteCoordinates.length; i++) {
      final pt = _fullRouteCoordinates[i];
      final dist = Geolocator.distanceBetween(techLat, techLng, pt.latitude, pt.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // If technician deviated (>80 meters from route), recalculate new path
    if (minDistance > 80.0) {
      final now = DateTime.now();
      if (_lastRouteFetchTime == null || now.difference(_lastRouteFetchTime!).inSeconds >= 5) {
        debugPrint('[Navigation] Deviation detected (${minDistance.toStringAsFixed(1)}m from route). Recalculating path...');
        _fetchRoute(techLat, techLng, destLat, destLng);
      }
      return;
    }

    // Technician is on route: snap position directly to road polyline and slice from closest point forward
    final snapped = _snapToPolyline(LatLng(techLat, techLng), _fullRouteCoordinates);
    final remaining = _fullRouteCoordinates.sublist(closestIndex);
    final updatedList = [snapped, ...remaining];
    if (_activePolylineCoordinates.length != updatedList.length ||
        (_activePolylineCoordinates.isNotEmpty && _activePolylineCoordinates.first != snapped)) {
      if (mounted) {
        setState(() {
          _activePolylineCoordinates = updatedList;
        });
      }
    }
  }

  LatLng _snapToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return point;
    if (polyline.length == 1) return polyline.first;

    double minDistance = double.infinity;
    LatLng closestPoint = polyline.first;

    for (int i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];

      final projected = _projectPointOnSegment(point, a, b);
      final dist = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        projected.latitude,
        projected.longitude,
      );

      if (dist < minDistance) {
        minDistance = dist;
        closestPoint = projected;
      }
    }

    // If within 80m of the road, snap directly onto the road center line
    if (minDistance <= 80.0) {
      return closestPoint;
    }
    return point;
  }

  LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final double dx = b.longitude - a.longitude;
    final double dy = b.latitude - a.latitude;

    if (dx == 0 && dy == 0) return a;

    final double t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);

    final double clampedT = t.clamp(0.0, 1.0);
    return LatLng(
      a.latitude + clampedT * dy,
      a.longitude + clampedT * dx,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _resolveBookingAddress(BookingModel booking) async {
    if (_lastGeocodedBookingId == booking.id && _resolvedAddress != null) return;
    _lastGeocodedBookingId = booking.id;

    if (booking.addressText.isNotEmpty &&
        !['Dakar', 'Point E, Dakar, Sénégal', 'Dakar, Sénégal', 'Position sélectionnée', 'Position sélectionnée, Dakar']
            .contains(booking.addressText.trim())) {
      if (mounted) {
        setState(() => _resolvedAddress = booking.addressText);
      }
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        booking.latitude,
        booking.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
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

        final resolved =
            parts.isNotEmpty ? parts.join(', ') : booking.addressText;
        if (mounted && resolved.isNotEmpty) {
          setState(() => _resolvedAddress = resolved);
        }
      }
    } catch (e) {
      debugPrint('[Tracking] Reverse geocoding error: $e');
    }
  }

  int _getStepIndex(String status) {
    if (status == 'matched') return 1;
    if (status == 'in_progress') return 2;
    if (status == 'on_site' || status == 'arrived') return 3;
    if (status == 'completed') return 4;
    return 1;
  }

  String _getStatusTitle(String status) {
    if (status == 'matched') return 'Technicien Assigné';
    if (status == 'in_progress') return 'Technicien En Route';
    if (status == 'on_site' || status == 'arrived') return 'Technicien Sur Place';
    if (status == 'completed') return 'Intervention Clôturée';
    return 'Demande Reçue';
  }

  String _getStatusDescription(String status, String? eta, [String? distance]) {
    if (status == 'matched') {
      return 'Technicien assigné • Préparation en cours';
    }
    if (status == 'in_progress') {
      final distInfo = distance != null && distance.isNotEmpty ? ' ($distance)' : '';
      return 'En route • ETA ${eta ?? '15 min'}$distInfo';
    }
    if (status == 'on_site' || status == 'arrived') {
      return 'Sur place • Diagnostic en cours';
    }
    if (status == 'completed') {
      return 'Intervention terminée';
    }
    return 'Recherche de technicien…';
  }

  Color _getStatusColor(String status) {
    if (status == 'matched') return Colors.blue;
    if (status == 'in_progress') return Colors.orange;
    if (status == 'on_site' || status == 'arrived') return AppTheme.primaryEmerald;
    if (status == 'completed') return Colors.green;
    return Colors.grey;
  }

  IconData _getCategoryIcon(String catId) {
    if (catId.contains('plumb')) return Icons.plumbing_rounded;
    if (catId.contains('hvac') || catId.contains('clim')) return Icons.ac_unit_rounded;
    if (catId.contains('electr')) return Icons.electric_bolt_rounded;
    if (catId.contains('appliance')) return Icons.kitchen_rounded;
    return Icons.build_rounded;
  }

  String _getCategoryName(String catId) {
    if (catId == 'cat_plumbing' || catId.contains('plumb')) return 'Plomberie & Sanitaire';
    if (catId == 'cat_hvac' || catId.contains('clim')) return 'Froid & Climatisation';
    if (catId == 'cat_electrical' || catId.contains('electr')) return 'Électricité Générale';
    if (catId == 'cat_appliances' || catId.contains('appliance')) return 'Électroménager';
    return 'Dépannage Express';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BookingModel?>(activeBookingProvider, (previous, next) {
      if (previous != null && next != null) {
        if (previous.status != 'completed' && next.status == 'completed' && !_reviewShown) {
          _reviewShown = true;
          final notifier = ref.read(activeBookingProvider.notifier);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showReviewDialog(context, notifier);
            }
          });
        }
      }
    });

    final activeBooking = ref.watch(activeBookingProvider);
    final registeredTechsAsync = ref.watch(registeredTechniciansProvider);
    final liveTechLocation = ref.watch(techLiveLocationProvider);
    final notifier = ref.read(activeBookingProvider.notifier);

    final status = activeBooking?.status ?? 'matched';
    final stepIdx = _getStepIndex(status);

    String techName = 'Technicien';
    String techInitials = 'TE';
    double techRating = 4.9;
    double? techLat;
    double? techLng;
    String techTransport = 'moto';

    registeredTechsAsync.whenData((techList) {
      final Map<String, dynamic> defaultTech = {
        'name': 'Technicien',
        'average_rating': 4.9
      };
      Map<String, dynamic> found = defaultTech;
      if (techList.isNotEmpty) {
        found = techList.firstWhere(
          (t) =>
              t['id'] == activeBooking?.technicianId ||
              t['user_id'] == activeBooking?.technicianId,
          orElse: () => defaultTech,
        );
      }
      techLat = found['latitude'] as double?;
      techLng = found['longitude'] as double?;
      
      techName =
          (found['name'] ?? found['user_name'] ?? 'Technicien').toString();
      techRating = (found['average_rating'] as num?)?.toDouble() ?? 4.9;
      techTransport = (found['transport_mode'] ?? 'moto').toString();
      final parts = techName.split(' ');
      if (parts.length >= 2) {
        techInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (techName.isNotEmpty) {
        techInitials =
            techName.substring(0, techName.length.clamp(0, 2)).toUpperCase();
      }
    });

    // Override with live location from WebSocket / GPS stream
    if (liveTechLocation != null) {
      techLat = liveTechLocation['latitude'];
      techLng = liveTechLocation['longitude'];
    }

    if (activeBooking != null && techLat != null && techLng != null) {
      _updateOrRecalculateRoute(
        techLat!,
        techLng!,
        activeBooking.latitude,
        activeBooking.longitude,
      );
    }

    if (activeBooking != null) {
      _resolveBookingAddress(activeBooking);
    }

    // Compute exact real-time distance and ETA along the route
    double remainingDistanceMeters = 0.0;
    if (_activePolylineCoordinates.length >= 2) {
      for (int i = 0; i < _activePolylineCoordinates.length - 1; i++) {
        remainingDistanceMeters += Geolocator.distanceBetween(
          _activePolylineCoordinates[i].latitude,
          _activePolylineCoordinates[i].longitude,
          _activePolylineCoordinates[i + 1].latitude,
          _activePolylineCoordinates[i + 1].longitude,
        );
      }
    } else if (techLat != null && techLng != null && activeBooking != null) {
      remainingDistanceMeters = Geolocator.distanceBetween(
        techLat!,
        techLng!,
        activeBooking.latitude,
        activeBooking.longitude,
      );
    }

    String dynamicDistanceText = '';
    if (remainingDistanceMeters >= 1000) {
      dynamicDistanceText = '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
    } else if (remainingDistanceMeters > 0) {
      dynamicDistanceText = '${remainingDistanceMeters.round()} m';
    }

    String dynamicEtaText;
    if (status == 'on_site' || status == 'arrived' || (status == 'in_progress' && remainingDistanceMeters < 50)) {
      dynamicEtaText = 'Sur place';
    } else if (status == 'completed') {
      dynamicEtaText = 'Terminé';
    } else if (remainingDistanceMeters > 0) {
      // Speed in Dakar urban traffic: ~24 km/h = ~400 meters/min
      final int minutes = (remainingDistanceMeters / 400).ceil();
      if (minutes <= 1) {
        dynamicEtaText = '< 1 min';
      } else {
        dynamicEtaText = '$minutes min';
      }
    } else {
      dynamicEtaText = activeBooking?.scheduledEta ?? '15 min';
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Full Screen Background
          if (activeBooking != null)
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    activeBooking.latitude,
                    activeBooking.longitude,
                  ),
                  zoom: 14.0,
                ),
                style: kMinimalMapStyle,
                padding: const EdgeInsets.only(bottom: 300),
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                polylines: {
                  if (techLat != null && techLng != null && !['completed', 'cancelled', 'no_technician_found'].contains(status))
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.85),
                      width: 5,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      points: _activePolylineCoordinates.isNotEmpty 
                        ? _activePolylineCoordinates 
                        : [
                            LatLng(techLat!, techLng!),
                            LatLng(activeBooking.latitude, activeBooking.longitude),
                          ],
                    ),
                },
                markers: {
                  if (_destinationIcon != null)
                    Marker(
                      markerId: const MarkerId('client'),
                      position: LatLng(activeBooking.latitude, activeBooking.longitude),
                      icon: _destinationIcon!,
                      anchor: const Offset(0.5, 0.92),
                    ),
                  if (techLat != null && techLng != null && !['completed', 'cancelled', 'no_technician_found'].contains(status))
                    Marker(
                      markerId: const MarkerId('tech'),
                      position: _activePolylineCoordinates.isNotEmpty
                          ? _snapToPolyline(LatLng(techLat!, techLng!), _activePolylineCoordinates)
                          : LatLng(techLat!, techLng!),
                      icon: techTransport == 'voiture'
                          ? (_techCarIcon ?? BitmapDescriptor.defaultMarker)
                          : (_techMotoIcon ?? BitmapDescriptor.defaultMarker),
                      anchor: const Offset(0.5, 0.92),
                      infoWindow: InfoWindow(
                        title: techName,
                        snippet: '${techRating.toStringAsFixed(1)} ★',
                      ),
                    ),
                },
              ),
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
                    icon: status == 'in_progress'
                        ? Icons.navigation_rounded
                        : Icons.info_outline_rounded,
                    title: _getStatusTitle(status),
                    subtitle: _getStatusDescription(status, dynamicEtaText, dynamicDistanceText),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Modal Sheet (Draggable)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.50,
            minChildSize: 0.18,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // TabBar inside Modal
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryEmerald,
                      unselectedLabelColor: AppTheme.textMuted,
                      indicatorColor: AppTheme.primaryEmerald,
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outline), text: 'Détails'),
                        Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
                      ],
                    ),
                    
                    // TabBarView Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Dossier Details
                          SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Stepper Bar
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStepItem(1, 'Assignée', stepIdx >= 1, Colors.blue),
                                      _buildStepDivider(stepIdx >= 2),
                                      _buildStepItem(2, 'En Route', stepIdx >= 2, Colors.orange),
                                      _buildStepDivider(stepIdx >= 3),
                                      _buildStepItem(3, 'Sur Place', stepIdx >= 3, AppTheme.primaryEmerald),
                                      _buildStepDivider(stepIdx >= 4),
                                      _buildStepItem(4, 'Clôturée', stepIdx >= 4, Colors.green),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Technician Info Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppTheme.primaryEmerald,
                                        child: Text(techInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(techName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, size: 16, color: AppTheme.primaryEmerald),
                                              ],
                                            ),
                                            const Text('Technicien Spécialiste Pro', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(
                                                      _getStatusTitle(status), maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                                Text(' ${techRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          children: [
                                            const Text('ETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                            Text(dynamicEtaText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                            if (dynamicDistanceText.isNotEmpty && status == 'in_progress')
                                              Text(dynamicDistanceText, style: const TextStyle(fontSize: 9, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Request Details Card (Panne, Lieu, Heure, Catégorie)
                                if (activeBooking != null) ...[
                                  _buildRequestDetailsCard(activeBooking, techLat, techLng),
                                  const SizedBox(height: 14),
                                ],

                                // Action Buttons
                                if (!['completed', 'cancelled', 'no_technician_found'].contains(status))
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: () => _showReviewDialog(context, notifier),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryEmerald,
                                              shape: const StadiumBorder(),
                                            ),
                                            child: const Text('Clôturer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: () => _showCancelDialog(context, notifier),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: const StadiumBorder(),
                                            ),
                                            child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          
                          // Tab 2: Chat
                          Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: notifier.messages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Center(
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                          child: Text('Canal sécurisé ouvert avec $techName (Pro)', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                        ),
                                      );
                                    }
                                    final msg = notifier.messages[index - 1];
                                    final currentUser = ref.watch(authProvider);
                                    final isMe = msg.senderId == (currentUser?.id ?? 'user_client_demo');

                                    return Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? AppTheme.primaryEmerald : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            Text(msg.senderName, style: TextStyle(color: isMe ? Colors.white70 : AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(msg.content, style: TextStyle(color: isMe ? Colors.white : AppTheme.textDark, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Chat Input
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _msgController,
                                        decoration: InputDecoration(
                                          hintText: 'Message au technicien...',
                                          hintStyle: const TextStyle(fontSize: 12),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                        ),
                                        onSubmitted: (txt) {
                                          if (txt.trim().isNotEmpty) {
                                            notifier.sendMessage(txt.trim());
                                            _msgController.clear();
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.send, color: AppTheme.primaryEmerald),
                                      onPressed: () {
                                        final txt = _msgController.text.trim();
                                        if (txt.isNotEmpty) {
                                          notifier.sendMessage(txt);
                                          _msgController.clear();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? color : const Color(0xFFE2E8F0),
          child: Text(
            '$step',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? color : AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      color: isActive ? AppTheme.primaryEmerald : const Color(0xFFE2E8F0),
    );
  }

  void _showReviewDialog(BuildContext context, BookingNotifier notifier) {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Noter la prestation',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedStars = idx + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Laisser un avis (optionnel)...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.submitReview(selectedStars, commentController.text);
                AppToast.show(
                  context,
                  title: 'Prestation Clôturée !',
                  message: 'Merci pour votre évaluation $selectedStars ★.',
                  type: AppToastType.success,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, BookingNotifier notifier) {
    String? selectedReason;
    final reasonController = TextEditingController();
    final reasons = [
      'Je n\'ai plus besoin du service',
      'Le technicien met trop de temps',
      'Le technicien a demandé l\'annulation',
      'Autre'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Annuler la demande',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Veuillez préciser le motif de l\'annulation.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
                hint: const Text('Sélectionner un motif'),
                value: selectedReason,
                items: reasons
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  setDialogState(() => selectedReason = val);
                },
              ),
              if (selectedReason == 'Autre') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Précisez le motif...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                if (selectedReason == null) {
                  AppToast.show(context,
                      title: 'Erreur',
                      message: 'Veuillez sélectionner un motif.',
                      type: AppToastType.error);
                  return;
                }
                final finalReason = selectedReason == 'Autre'
                    ? reasonController.text
                    : selectedReason!;
                // Simulate sending cancellation with reason to backend. The notifier would need a cancelMethod.
                notifier.cancelBooking(finalReason);
                AppToast.show(
                  context,
                  title: 'Intervention annulée',
                  message: 'Votre demande a été annulée.',
                  type: AppToastType.error,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetailsCard(
      BookingModel booking, double? techLat, double? techLng) {
    final catName = _getCategoryName(booking.categoryId);
    final catIcon = _getCategoryIcon(booking.categoryId);
    final dateStr =
        '${booking.createdAt.day.toString().padLeft(2, '0')}/${booking.createdAt.month.toString().padLeft(2, '0')}/${booking.createdAt.year} à ${booking.createdAt.hour.toString().padLeft(2, '0')}:${booking.createdAt.minute.toString().padLeft(2, '0')}';
    final shortId =
        booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id;

    // Calculate dynamic live distance from technician to client
    String? distanceText;
    if (techLat != null && techLng != null) {
      final meters = Geolocator.distanceBetween(
        techLat,
        techLng,
        booking.latitude,
        booking.longitude,
      );
      if (meters < 100) {
        distanceText = 'Sur place';
      } else if (meters < 1000) {
        distanceText = '${meters.round()} m';
      } else {
        distanceText = '${(meters / 1000).toStringAsFixed(1)} km';
      }
    }

    final displayAddress = _resolvedAddress ??
        (booking.addressText.isNotEmpty
            ? booking.addressText
            : 'Dakar, Sénégal');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category badge + Dossier Reference ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 16, color: AppTheme.primaryEmerald),
                    const SizedBox(width: 6),
                    Text(
                      catName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '#$shortId',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Problem Description
          const Text(
            'Description de la panne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Text(
              booking.description.isNotEmpty
                  ? booking.description
                  : 'Aucune description précisée.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Location Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lieu d\'intervention',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    if (distanceText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 12, color: Colors.deepOrange),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Recenter on map button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(booking.latitude, booking.longitude),
                              16.5,
                            ),
                          );
                          if (_sheetController.isAttached) {
                            _sheetController.animateTo(
                              0.22,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primaryEmerald
                                    .withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.center_focus_strong_rounded,
                                  size: 14, color: AppTheme.primaryEmerald),
                              SizedBox(width: 6),
                              Text(
                                'Centrer sur la carte',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy address button
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: displayAddress));
                        AppToast.show(
                          context,
                          title: 'Adresse copiée',
                          message: displayAddress,
                          type: AppToastType.info,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 14, color: AppTheme.textMuted),
                            SizedBox(width: 4),
                            Text(
                              'Copier',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),

          // Payment mode & Date info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 15,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Direct technicien (Devis)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Optional Photo Preview
          if (booking.photoUrl != null && booking.photoUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Photo jointe',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                booking.photoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
