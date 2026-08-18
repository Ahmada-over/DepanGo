import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../core/theme.dart';
import '../core/app_toast.dart';
import '../core/map_markers.dart';
import '../core/map_style.dart';
import '../core/config.dart';
import '../core/category_helper.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';

class TrackingChatScreen extends ConsumerStatefulWidget {
  const TrackingChatScreen({super.key});

  @override
  ConsumerState<TrackingChatScreen> createState() => _TrackingChatScreenState();
}

class _TrackingChatScreenState extends ConsumerState<TrackingChatScreen> {
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
    _loadMapIcons();
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap({
    required IconData icon,
    required Color primaryColor,
    required Color iconColor,
    double size = 110.0,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final width = size;
    final height = size * 1.25;

    // 1. Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, shadowPaint);

    // 2. Pin pointer triangle
    final path = Path();
    path.moveTo(width * 0.34, width * 0.72);
    path.lineTo(width / 2, height - 2);
    path.lineTo(width * 0.66, width * 0.72);
    path.close();

    final pinPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // 3. Outer border circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final circlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, circlePaint);
    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, borderPaint);

    // 4. Center icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: width * 0.44,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        width / 2 - textPainter.width / 2,
        width * 0.45 - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadMapIcons() async {
    if (!mounted) return;
    try {
      final moto = await _createCustomMarkerBitmap(
        icon: Icons.two_wheeler_rounded,
        primaryColor: const Color(0xFF0F766E), // Emerald
        iconColor: Colors.white,
      );
      final car = await _createCustomMarkerBitmap(
        icon: Icons.directions_car_rounded,
        primaryColor: const Color(0xFF1E40AF), // Deep Blue
        iconColor: Colors.white,
      );
      final dest = await _createCustomMarkerBitmap(
        icon: Icons.person_pin_circle_rounded,
        primaryColor: const Color(0xFFDC2626), // Red
        iconColor: Colors.white,
      );
      if (mounted) {
        setState(() {
          _techMotoIcon = moto;
          _techCarIcon = car;
          _destinationIcon = dest;
        });
      }
    } catch (e) {
      debugPrint('[MapIcons] Error generating custom markers: $e');
      if (mounted) {
        setState(() {
          _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          _techMotoIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          _techCarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: clean.isNotEmpty ? clean : '+221770000000');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
      if (mounted) {
        AppToast.show(
          context,
          title: 'Numéro de téléphone',
          message: 'Contact : $phoneNumber',
          type: AppToastType.info,
        );
      }
    }
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

    if (_fullRouteCoordinates.isEmpty || isNewDestination) {
      _fetchRoute(techLat, techLng, destLat, destLng);
      return;
    }

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

    if (minDistance > 100.0) {
      final now = DateTime.now();
      if (_lastRouteFetchTime == null || now.difference(_lastRouteFetchTime!).inSeconds >= 10) {
        _fetchRoute(techLat, techLng, destLat, destLng);
      }
      return;
    }

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

    return (minDistance < 80.0) ? closestPoint : point;
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
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _resolveBookingAddress(BookingModel booking) async {
    if (_lastGeocodedBookingId == booking.id && _resolvedAddress != null) return;
    _lastGeocodedBookingId = booking.id;

    if (booking.addressText.isNotEmpty &&
        !booking.addressText.toLowerCase().contains('position sélectionnée')) {
      if (mounted) setState(() => _resolvedAddress = booking.addressText);
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        booking.latitude,
        booking.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.street != null && p.street!.isNotEmpty && p.street != p.subLocality) parts.add(p.street!);
        if (p.locality != null && p.locality!.isNotEmpty && !parts.contains(p.locality)) parts.add(p.locality!);

        final dynamicAddress = parts.isNotEmpty
            ? parts.join(', ')
            : '${booking.latitude.toStringAsFixed(4)}, ${booking.longitude.toStringAsFixed(4)} (Dakar)';

        setState(() {
          _resolvedAddress = dynamicAddress;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvedAddress = '${booking.latitude.toStringAsFixed(4)}, ${booking.longitude.toStringAsFixed(4)} (Dakar)';
        });
      }
    }
  }

  int _getStepIndex(String status) {
    if (status == 'matched') return 1;
    if (status == 'in_progress') return 2;
    if (status == 'on_site' || status == 'arrived') return 3;
    if (status == 'completed') return 4;
    return 0;
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

  IconData _getCategoryIcon(String catId) {
    return CategoryHelper.getCategoryIcon(catId);
  }

  String _getCategoryName(String catId) {
    return CategoryHelper.getCategoryName(catId);
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

    String techName = 'Technicien Pro';
    String techInitials = 'TE';
    String techPhone = '+221 77 000 00 00';
    double techRating = 4.9;
    double? techLat;
    double? techLng;
    String techTransport = 'moto';

    registeredTechsAsync.whenData((techList) {
      final Map<String, dynamic> defaultTech = {
        'name': 'Technicien Pro',
        'average_rating': 4.9,
        'phone': '+221 77 000 00 00',
        'transport_mode': 'moto',
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
      
      techName = (found['name'] ?? found['user_name'] ?? 'Technicien Pro').toString();
      techPhone = (found['phone'] ?? found['user_phone'] ?? '+221 77 000 00 00').toString();
      techRating = (found['average_rating'] as num?)?.toDouble() ?? 4.9;
      techTransport = (found['transport_mode'] ?? 'moto').toString();
      
      final parts = techName.split(' ');
      if (parts.length >= 2) {
        techInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (techName.isNotEmpty) {
        techInitials = techName.substring(0, techName.length.clamp(0, 2)).toUpperCase();
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
                padding: const EdgeInsets.only(bottom: 260),
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
                      anchor: const Offset(0.5, 0.95),
                      infoWindow: const InfoWindow(title: 'Votre Lieu d\'intervention'),
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
                      anchor: const Offset(0.5, 0.95),
                      infoWindow: InfoWindow(
                        title: '$techName (${techTransport == 'voiture' ? 'Voiture' : 'Moto'})',
                        snippet: '${techRating.toStringAsFixed(1)} ★ • $techPhone',
                      ),
                    ),
                },
              ),
            ),

          // 2. Top Header Navigation Bar
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
                        ? (techTransport == 'voiture' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded)
                        : Icons.info_outline_rounded,
                    title: _getStatusTitle(status),
                    subtitle: _getStatusDescription(status, dynamicEtaText, dynamicDistanceText),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Modal Sheet (Single Fluid View)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.44,
            minChildSize: 0.20,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Stepper Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    const SizedBox(height: 12),

                    // Technician Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: techTransport == 'voiture' ? const Color(0xFF1E40AF) : AppTheme.primaryEmerald,
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
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                techTransport == 'voiture' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                                                size: 13,
                                                color: techTransport == 'voiture' ? Colors.blue[800] : const Color(0xFF0F766E),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                techTransport == 'voiture' ? 'Voiture' : 'Moto Express',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: techTransport == 'voiture' ? Colors.blue[800] : const Color(0xFF0F766E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star, size: 13, color: Colors.amber),
                                        Text(' ${techRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                          const SizedBox(height: 14),

                          // Direct Call Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(techPhone),
                              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                              label: Text(
                                'Appeler le Technicien ($techPhone)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
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

                    // Action Buttons (Clôturer / Annuler)
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
                    const SizedBox(height: 28),
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
            color: Colors.black.withValues(alpha: 0.04),
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

          // Problem Description & Photo
          const Text(
            'Description de la panne & Photo',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking.photoUrl != null && booking.photoUrl!.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      final fullUrl = booking.photoUrl!.startsWith('http')
                          ? booking.photoUrl!
                          : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}${booking.photoUrl}';
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(fullUrl, fit: BoxFit.contain),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        booking.photoUrl!.startsWith('http')
                            ? booking.photoUrl!
                            : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}${booking.photoUrl}',
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
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
              ],
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
                          color: Colors.orange.withValues(alpha: 0.12),
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
                                    .withValues(alpha: 0.3)),
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
