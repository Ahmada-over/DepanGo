import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/map_style.dart';
import '../core/category_helper.dart';
import '../models/models.dart';
import '../providers/pro_providers.dart';
import '../providers/connectivity_provider.dart';
import 'active_mission_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  int _currentBottomNav = 0;
  BitmapDescriptor? _techMotoIcon;
  BitmapDescriptor? _techCarIcon;
  bool _hasInitialCameraMove = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMapMarkers();
    _initLocation();
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
    canvas.drawCircle(
        Offset(width / 2, width * 0.45), width * 0.38, shadowPaint);

    // Pin pointer triangle
    final path = Path();
    path.moveTo(width * 0.34, width * 0.72);
    path.lineTo(width / 2, height - 2);
    path.lineTo(width * 0.66, width * 0.72);
    path.close();

    final pinPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // Outer border circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final circlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(width / 2, width * 0.45), width * 0.38, circlePaint);
    canvas.drawCircle(
        Offset(width / 2, width * 0.45), width * 0.38, borderPaint);

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
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadCustomMapMarkers() async {
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
      if (mounted) {
        setState(() {
          _techMotoIcon = moto;
          _techCarIcon = car;
        });
      }
    } catch (e) {
      debugPrint('[Markers] Error creating custom markers: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      final Position position = pos ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );

      if (mounted) {
        ref.read(liveLocationProvider.notifier).state = position;
        if (!_hasInitialCameraMove && _mapController != null) {
          _hasInitialCameraMove = true;
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude), 15.0),
          );
        }
      }
    } catch (e) {
      debugPrint('[InitLocation] Error: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final profile = ref.watch(technicianProfileProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final isServerOnline = ref.watch(serverConnectivityProvider);
    final activeMission = ref.watch(activeMissionProvider);
    final incomingOffer = ref.watch(incomingOfferProvider);
    final livePos = ref.watch(liveLocationProvider);

    // Compute effective technician location (live GPS or fallback to profile or Dakar center)
    final double techLat = livePos?.latitude ?? profile?.latitude ?? 14.6937;
    final double techLng = livePos?.longitude ?? profile?.longitude ?? -17.4441;
    final LatLng currentTechPosition = LatLng(techLat, techLng);

    final bool isCar = profile?.transportMode == 'voiture';
    final BitmapDescriptor techMarkerIcon = isCar
        ? (_techCarIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_techMotoIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      body: Stack(
        children: [
          if (!isServerOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.amber.shade900,
                child: Shimmer.fromColors(
                  baseColor: Colors.amber.shade100,
                  highlightColor: Colors.white,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Reconnexion au réseau...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 1. Google Map Background
          GoogleMap(
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              if (livePos != null && !_hasInitialCameraMove) {
                _hasInitialCameraMove = true;
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(currentTechPosition, 15.0),
                );
              }
            },
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
            padding: const EdgeInsets.only(bottom: 120),
            markers: {
              Marker(
                markerId: const MarkerId('my_pos'),
                position: currentTechPosition,
                icon: techMarkerIcon,
                anchor: const Offset(0.5, 0.95),
                infoWindow: InfoWindow(
                  title:
                      'Vous êtes ${isOnline ? 'En Ligne (Disponible)' : 'En Pause'}',
                  snippet:
                      '${user?.name ?? 'Technicien'} • ${isCar ? 'Voiture' : 'Moto Express'}',
                ),
              ),
            },
          ),

          // 2. Top Header Bar (Driver Controls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Profile Avatar Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: ProTheme.darkBorder, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: ProTheme.primaryEmerald,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'T')
                            .toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Availability Status Pill (Switch)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(isOnlineProvider.notifier).toggleOnline();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: ProTheme.darkCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isOnline
                              ? ProTheme.primaryLight
                              : Colors.redAccent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? ProTheme.success
                                  : Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isOnline
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isOnline
                                      ? 'Disponible en ligne'
                                      : 'En pause (hors ligne)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOnline
                                        ? Colors.white
                                        : ProTheme.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  isOnline
                                      ? 'Prêt à recevoir des dépannages'
                                      : 'Touchez pour passer en ligne',
                                  style: const TextStyle(
                                      fontSize: 10, color: ProTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isOnline
                                ? Icons.power_settings_new_rounded
                                : Icons.play_arrow_rounded,
                            color:
                                isOnline ? ProTheme.success : Colors.redAccent,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Recenter Floating Button
          Positioned(
            right: 16,
            bottom: activeMission != null ? 220 : 130,
            child: FloatingActionButton.small(
              backgroundColor: ProTheme.darkCard,
              foregroundColor: ProTheme.primaryLight,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(currentTechPosition, 16.0),
                );
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 4. Active Mission Floating Banner
          if (activeMission != null)
            Positioned(
              bottom: 110,
              left: 16,
              right: 16,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ActiveMissionScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ProTheme.darkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ProTheme.darkBorder, width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 14,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ProTheme.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.navigation_rounded,
                            color: ProTheme.amber, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Mission en cours',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ProTheme.amber),
                                ),
                                const Spacer(),
                                Text(
                                  activeMission.status,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ProTheme.primaryLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeMission.clientName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              activeMission.addressText,
                              style: const TextStyle(
                                  fontSize: 12, color: ProTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Quick KPI Bottom Bar
          if (activeMission == null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProTheme.darkBorder),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildKpiItem(
                        'Note Pro',
                        '${profile?.averageRating.toStringAsFixed(1) ?? '5.0'} ★',
                        Icons.star_rounded,
                        Colors.amber),
                    Container(width: 1, height: 36, color: ProTheme.darkBorder),
                    _buildKpiItem('Véhicule', isCar ? 'Voiture' : 'Moto',
                        Icons.two_wheeler_rounded, ProTheme.primaryLight),
                    Container(width: 1, height: 36, color: ProTheme.darkBorder),
                    _buildKpiItem(
                        'Statut',
                        isOnline ? 'En Ligne' : 'Pause',
                        Icons.wifi_tethering_rounded,
                        isOnline ? ProTheme.success : Colors.grey),
                  ],
                ),
              ),
            ),

          // 6. INCOMING MISSION OFFER MODAL (Full Attention Driver Overlay)
          if (incomingOffer != null)
            _buildIncomingOfferOverlay(context, incomingOffer),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNav,
        backgroundColor: ProTheme.darkBg,
        selectedItemColor: ProTheme.primaryLight,
        unselectedItemColor: ProTheme.textMuted,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() => _currentBottomNav = idx);
          if (idx == 1) {
            if (activeMission != null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActiveMissionScreen()));
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }
          } else if (idx == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()));
          } else if (idx == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded), label: 'Carte Live'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_history_rounded), label: 'Mission'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: 'Historique'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profil Pro'),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: ProTheme.textMuted)),
      ],
    );
  }

  Widget _buildIncomingOfferOverlay(
      BuildContext context, MatchOfferModel offer) {
    final notifier = ref.watch(incomingOfferProvider.notifier);

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: ProTheme.darkBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Pulsing Alert
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ProTheme.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: ProTheme.amber, size: 18),
                              SizedBox(width: 4),
                              Text('Nouvelle demande',
                                  style: TextStyle(
                                      color: ProTheme.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        // Countdown Timer Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Text(
                            '${notifier.remainingSeconds}s',
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Client & Panne Info
                    Text(
                      offer.clientName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),

                    // French Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CategoryHelper.getCategoryColor(offer.categoryId)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${CategoryHelper.getCategoryEmoji(offer.categoryId)} ${CategoryHelper.getCategoryName(offer.categoryId)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              CategoryHelper.getCategoryColor(offer.categoryId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: ProTheme.primaryLight, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              offer.addressText,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ProTheme.primaryEmerald
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${offer.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ProTheme.primaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Diagnostic Description & Optional Photo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.photoUrl != null &&
                              offer.photoUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                offer.photoUrl!.startsWith('http')
                                    ? offer.photoUrl!
                                    : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}${offer.photoUrl}',
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_rounded,
                                    size: 40,
                                    color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              offer.description.isNotEmpty
                                  ? '"${offer.description}"'
                                  : '"Diagnostic et devis sur place"',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: ProTheme.textMuted,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Accept & Reject Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => notifier.declineOffer(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: ProTheme.darkBorder),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Refuser',
                                  style: TextStyle(
                                      color: ProTheme.textMuted,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final accepted = await notifier.acceptOffer();
                                if (accepted && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ActiveMissionScreen()),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              label: const Text('Accepter la mission',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProTheme.primaryEmerald,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
