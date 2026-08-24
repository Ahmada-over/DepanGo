import 'dart:ui' as ui;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../core/map_style.dart';
import '../core/app_toast.dart';
import '../core/category_helper.dart';
import '../providers/pro_providers.dart';

class ActiveMissionScreen extends ConsumerStatefulWidget {
  const ActiveMissionScreen({super.key});

  @override
  ConsumerState<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends ConsumerState<ActiveMissionScreen> {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  BitmapDescriptor? _techMotoIcon;
  BitmapDescriptor? _techCarIcon;
  BitmapDescriptor? _clientDestinationIcon;

  List<LatLng> _fullRouteCoordinates = [];
  List<LatLng> _activePolylineCoordinates = [];
  LatLng? _lastCalculatedDestination;
  bool _isFetchingRoute = false;
  DateTime? _lastRouteFetchTime;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
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

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, shadowPaint);

    // Pointer bottom triangle
    final path = Path();
    path.moveTo(width * 0.34, width * 0.72);
    path.lineTo(width / 2, height - 2);
    path.lineTo(width * 0.66, width * 0.72);
    path.close();

    final pinPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // Outer Circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final circlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, circlePaint);
    canvas.drawCircle(Offset(width / 2, width * 0.45), width * 0.38, borderPaint);

    // Center icon
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
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final moto = await _createCustomMarkerBitmap(
        icon: LucideIcons.bike,
        primaryColor: const Color(0xFF0F766E), // Emerald
        iconColor: Colors.white,
      );
      final car = await _createCustomMarkerBitmap(
        icon: LucideIcons.car,
        primaryColor: const Color(0xFF1E40AF), // Blue
        iconColor: Colors.white,
      );
      final client = await _createCustomMarkerBitmap(
        icon: LucideIcons.map_pin,
        primaryColor: const Color(0xFFDC2626), // Red
        iconColor: Colors.white,
      );
      if (mounted) {
        setState(() {
          _techMotoIcon = moto;
          _techCarIcon = car;
          _clientDestinationIcon = client;
        });
      }
    } catch (e) {
      debugPrint('[Markers] Error: $e');
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
      debugPrint('[Route] Fetch error: $e');
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
      if (mounted) {
        AppToast.show(context, title: 'Téléphone client', message: 'Numéro : $phoneNumber', type: AppToastType.info);
      }
    }
  }

  Future<void> _handleStatusUpdate(String newStatus, [String? cancelReason]) async {
    setState(() => _actionLoading = true);
    final success = await ref.read(activeMissionProvider.notifier).updateStatus(newStatus, cancelReason);
    setState(() => _actionLoading = false);

    if (success && mounted) {
      if (newStatus == 'completed') {
        AppToast.show(context, title: 'Mission Clôturée !', message: 'Félicitations, l\'intervention est terminée.', type: AppToastType.success);
        Navigator.pop(context);
      } else if (newStatus == 'cancelled') {
        AppToast.show(context, title: 'Intervention Annulée', message: 'Le dossier a été annulé.', type: AppToastType.warning);
        Navigator.pop(context);
      } else {
        String friendlyMessage = 'Statut mis à jour.';
        if (newStatus == 'in_progress') friendlyMessage = 'Vous êtes maintenant en route vers le client.';
        if (newStatus == 'on_site') friendlyMessage = 'Vous avez indiqué être sur place.';
        AppToast.show(context, title: 'Statut Mis à Jour', message: friendlyMessage, type: AppToastType.info);
      }
    }
  }

  int _getStepIndex(String status) {
    if (status == 'matched') return 1;
    if (status == 'in_progress') return 2;
    if (status == 'on_site' || status == 'arrived') return 3;
    if (status == 'completed') return 4;
    return 1;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeMission = ref.watch(activeMissionProvider);
    final profile = ref.watch(technicianProfileProvider);
    final livePos = ref.watch(liveLocationProvider);

    if (activeMission == null) {
      return Scaffold(
        backgroundColor: ProTheme.darkBg,
        appBar: AppBar(title: const Text('Mission en cours')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.circle_check, size: 64, color: ProTheme.primaryLight),
              const SizedBox(height: 16),
              const Text('Aucune mission active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Vous êtes prêt à recevoir de nouveaux dépannages.', style: TextStyle(color: ProTheme.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour à la Carte'),
              ),
            ],
          ),
        ),
      );
    }

    final double techLat = livePos?.latitude ?? profile?.latitude ?? 14.6937;
    final double techLng = livePos?.longitude ?? profile?.longitude ?? -17.4441;
    final LatLng currentTechPosition = LatLng(techLat, techLng);

    final bool isCar = profile?.transportMode == 'voiture';
    final BitmapDescriptor techMarkerIcon = isCar
        ? (_techCarIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_techMotoIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    // Update GPS Route
    _updateOrRecalculateRoute(techLat, techLng, activeMission.latitude, activeMission.longitude);

    // Compute remaining distance & ETA
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
    } else {
      remainingDistanceMeters = Geolocator.distanceBetween(
        techLat,
        techLng,
        activeMission.latitude,
        activeMission.longitude,
      );
    }

    String dynamicDistanceText = '';
    if (remainingDistanceMeters >= 1000) {
      dynamicDistanceText = '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
    } else if (remainingDistanceMeters > 0) {
      dynamicDistanceText = '${remainingDistanceMeters.round()} m';
    }

    String dynamicEtaText = '';
    if (activeMission.status == 'on_site' || remainingDistanceMeters < 50) {
      dynamicEtaText = 'Sur place';
    } else if (remainingDistanceMeters > 0) {
      final int minutes = (remainingDistanceMeters / 400).ceil();
      dynamicEtaText = minutes <= 1 ? '< 1 min' : '$minutes min';
    } else {
      dynamicEtaText = '15 min';
    }

    final stepIdx = _getStepIndex(activeMission.status);
    final shortId = activeMission.id.length > 8 ? activeMission.id.substring(0, 8) : activeMission.id;

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      body: Stack(
        children: [
          // 1. Google Map Full-Screen In-App Navigation View
          GoogleMap(
            onMapCreated: (ctrl) => _mapController = ctrl,
            initialCameraPosition: CameraPosition(
              target: currentTechPosition,
              zoom: 14.5,
            ),
            style: kProMapStyle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 260),
            polylines: {
              Polyline(
                polylineId: const PolylineId('tech_to_client_route'),
                color: ProTheme.primaryLight.withValues(alpha: 0.9),
                width: 6,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
                points: _activePolylineCoordinates.isNotEmpty
                    ? _activePolylineCoordinates
                    : [
                        currentTechPosition,
                        LatLng(activeMission.latitude, activeMission.longitude),
                      ],
              ),
            },
            markers: {
              // Technician Vehicle Marker (moving in real time)
              Marker(
                markerId: const MarkerId('tech_vehicle'),
                position: _activePolylineCoordinates.isNotEmpty
                    ? _snapToPolyline(currentTechPosition, _activePolylineCoordinates)
                    : currentTechPosition,
                icon: techMarkerIcon,
                anchor: const Offset(0.5, 0.95),
                infoWindow: InfoWindow(
                  title: 'Votre position (${isCar ? 'Voiture' : 'Moto Express'})',
                  snippet: 'En route vers ${activeMission.clientName}',
                ),
              ),

              // Client Destination Marker
              Marker(
                markerId: const MarkerId('client_dest'),
                position: LatLng(activeMission.latitude, activeMission.longitude),
                icon: _clientDestinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                anchor: const Offset(0.5, 0.95),
                infoWindow: InfoWindow(
                  title: 'Client : ${activeMission.clientName}',
                  snippet: activeMission.addressText,
                ),
              ),
            },
          ),

          // 2. Top Navigation Bar with Dynamic ETA & Distance Chip
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: ProTheme.darkBorder),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                    ),
                    child: const Icon(LucideIcons.arrow_left, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),

                // Navigation ETA & Distance Banner
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ProTheme.primaryLight, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ProTheme.primaryEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCar ? LucideIcons.car : LucideIcons.bike,
                            color: ProTheme.primaryLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeMission.status == 'in_progress' ? 'GUIDAGE EN DIRECT' : 'MISSION ATTRIBUÉE',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ProTheme.primaryLight),
                              ),
                              Text(
                                '$dynamicDistanceText ($dynamicEtaText)',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ProTheme.darkSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('#$shortId', style: const TextStyle(fontSize: 10, color: ProTheme.textMuted, fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Recenter on Vehicle Button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.48,
            child: FloatingActionButton.small(
              backgroundColor: ProTheme.darkCard,
              foregroundColor: ProTheme.primaryLight,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(currentTechPosition, 16.5),
                );
              },
              child: const Icon(LucideIcons.locate_fixed),
            ),
          ),

          // 4. Fluid Bottom Modal Sheet (Workflow Actions & Client Details)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.46,
            minChildSize: 0.22,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, -4))
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
                          color: ProTheme.darkBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Stepper Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProTheme.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStepCircle(1, 'Assignée', stepIdx >= 1, Colors.blue),
                          _buildStepLine(stepIdx >= 2),
                          _buildStepCircle(2, 'En Route', stepIdx >= 2, ProTheme.amber),
                          _buildStepLine(stepIdx >= 3),
                          _buildStepCircle(3, 'Sur Place', stepIdx >= 3, ProTheme.primaryLight),
                          _buildStepLine(stepIdx >= 4),
                          _buildStepCircle(4, 'Clôturée', stepIdx >= 4, ProTheme.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Client Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ProTheme.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: ProTheme.primaryEmerald,
                                child: Text(
                                  (activeMission.clientName.isNotEmpty ? activeMission.clientName[0] : 'C').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeMission.clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activeMission.clientPhone,
                                      style: const TextStyle(fontSize: 13, color: ProTheme.primaryLight, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CategoryHelper.getCategoryColor(activeMission.categoryId).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${CategoryHelper.getCategoryEmoji(activeMission.categoryId)} ${CategoryHelper.getShortName(activeMission.categoryId)}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CategoryHelper.getCategoryColor(activeMission.categoryId)),
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
                              onPressed: () => _makePhoneCall(activeMission.clientPhone),
                              icon: const Icon(LucideIcons.phone_call, color: Colors.white, size: 20),
                              label: Text(
                                'Appeler le Client (${activeMission.clientPhone})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Destination Address & Diagnostic + Photo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ProTheme.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.map_pin, color: ProTheme.primaryLight, size: 16),
                              const SizedBox(width: 6),
                              const Text('Adresse d\'intervention', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProTheme.textMuted)),
                              const Spacer(),
                              Text(dynamicDistanceText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProTheme.primaryLight)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeMission.addressText,
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: ProTheme.darkBorder, height: 1),
                          const SizedBox(height: 10),
                          const Text('Panne / Diagnostic & Photo :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProTheme.textMuted)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (activeMission.photoUrl != null && activeMission.photoUrl!.isNotEmpty) ...[
                                InkWell(
                                  onTap: () {
                                    final fullUrl = activeMission.photoUrl!.startsWith('http')
                                        ? activeMission.photoUrl!
                                        : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}${activeMission.photoUrl}';
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
                                      activeMission.photoUrl!.startsWith('http')
                                          ? activeMission.photoUrl!
                                          : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}${activeMission.photoUrl}',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.image_off, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  activeMission.description.isNotEmpty ? '"${activeMission.description}"' : '"Diagnostic et devis sur place"',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Direct Settlement Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProTheme.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ProTheme.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.banknote, color: ProTheme.amber, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Établissez le devis sur place et percevez le paiement direct (Espèces ou Mobile Money).',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // WORKFLOW ACTION BUTTONS
                    if (activeMission.status == 'matched')
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : () => _handleStatusUpdate('in_progress'),
                          icon: const Icon(LucideIcons.bike, size: 22),
                          label: const Text('🚗 PASSER : EN ROUTE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProTheme.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                    if (activeMission.status == 'in_progress')
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : () => _handleStatusUpdate('on_site'),
                          icon: const Icon(LucideIcons.map_pin, size: 22),
                          label: const Text('📍 PASSER : SUR PLACE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProTheme.primaryLight,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                    if (activeMission.status == 'on_site')
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : () => _handleStatusUpdate('completed'),
                          icon: const Icon(LucideIcons.circle_check, size: 22),
                          label: const Text('✅ CLÔTURER LE DOSSIER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProTheme.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Cancel Action Button
                    SizedBox(
                      height: 44,
                      child: TextButton.icon(
                        onPressed: () => _showCancelDialog(context),
                        icon: const Icon(LucideIcons.x, color: Colors.redAccent, size: 18),
                        label: const Text('Annuler l\'intervention', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool active, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active ? color : ProTheme.darkSurface,
          child: Text('$step', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.black : ProTheme.textMuted)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? color : ProTheme.textMuted)),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 24,
      height: 2,
      color: active ? ProTheme.primaryLight : ProTheme.darkBorder,
    );
  }

  void _showCancelDialog(BuildContext context) {
    String selectedReason = 'Client absent';
    final reasons = [
      'Client absent',
      'Problème technique complexe / Matériel manquant',
      'Le client a refusé le devis',
      'Autre'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ProTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Annuler l\'intervention', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Précisez le motif d\'annulation de cette intervention :', style: TextStyle(fontSize: 13, color: ProTheme.textMuted)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                dropdownColor: ProTheme.darkSurface,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12, color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedReason = val ?? reasons.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Retour', style: TextStyle(color: ProTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                _handleStatusUpdate('cancelled', selectedReason);
              },
              child: const Text('Confirmer l\'Annulation'),
            ),
          ],
        ),
      ),
    );
  }
}
