import 'dart:ui' as ui;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/design_tokens.dart';
import '../core/map_style.dart';
import '../core/category_helper.dart';
import '../core/app_toast.dart';
import '../models/hardware_store.dart';
import '../providers/pro_providers.dart';
import '../providers/connectivity_provider.dart';
import '../services/pro_haptic_service.dart';
import 'active_mission_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import '../providers/wallet_provider.dart';
import '../widgets/circular_countdown_timer.dart';
import '../widgets/slide_to_accept.dart';

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
  BitmapDescriptor? _hardwareStoreIcon;
  bool _showHardwareStores = true;
  String? _currentCommuneName;
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
        icon: LucideIcons.bike,
        primaryColor: const Color(0xFF0F766E), // Emerald
        iconColor: Colors.white,
      );
      final car = await _createCustomMarkerBitmap(
        icon: LucideIcons.car,
        primaryColor: const Color(0xFF1E40AF), // Deep Blue
        iconColor: Colors.white,
      );
      final hardware = await _createCustomMarkerBitmap(
        icon: LucideIcons.wrench,
        primaryColor: const Color(0xFFD97706), // Amber Gold
        iconColor: Colors.white,
        size: 90.0,
      );
      if (mounted) {
        setState(() {
          _techMotoIcon = moto;
          _techCarIcon = car;
          _hardwareStoreIcon = hardware;
        });
      }
    } catch (e) {
      debugPrint('[Markers] Error creating custom markers: $e');
    }
  }

  Future<void> _resolveCommuneName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final subLoc = p.subLocality?.trim();
        final loc = p.locality?.trim();
        final thoroughfare = p.thoroughfare?.trim();
        final name = p.name?.trim();

        String zone = '';
        if (subLoc != null && subLoc.isNotEmpty && !subLoc.contains('+')) {
          zone = subLoc;
          if (loc != null && loc.isNotEmpty && loc.toLowerCase() != subLoc.toLowerCase()) {
            zone += ', $loc';
          }
        } else if (thoroughfare != null && thoroughfare.isNotEmpty && !thoroughfare.contains('+')) {
          zone = thoroughfare;
          if (loc != null && loc.isNotEmpty) zone += ', $loc';
        } else if (loc != null && loc.isNotEmpty) {
          zone = loc;
        } else if (name != null && name.isNotEmpty && !name.contains('+')) {
          zone = name;
        }

        if (zone.isNotEmpty && mounted) {
          setState(() => _currentCommuneName = zone);
        }
      }
    } catch (e) {
      debugPrint('[HomeScreen] Geocoding error: $e');
    }
  }

  String _extractCommuneName(String addressText) {
    if (addressText.trim().isEmpty) return 'Dakar';
    final parts = addressText.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      return '${parts[1]}, ${parts[2]}';
    } else if (parts.length == 2) {
      return parts[0];
    }
    return addressText;
  }

  Future<void> _callStore(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(' ', ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Cannot call $phone: $e');
    }
  }

  void _showHardwareStoreDetails(HardwareStore store, String distKm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: ProTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.wrench,
                      color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${store.commune} • à ~$distKm km',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(LucideIcons.map_pin,
                    color: ProTheme.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.address,
                    style: const TextStyle(
                        color: ProTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: store.specialties
                  .map((spec) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ProTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          spec,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(store.latitude, store.longitude),
                          16.5,
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.navigation, size: 18),
                    label: const Text('Centrer la carte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProTheme.primaryLight,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _callStore(store.phone),
                  icon: const Icon(LucideIcons.phone, color: Colors.white),
                  tooltip: 'Appeler',
                  style: IconButton.styleFrom(
                    backgroundColor: ProTheme.darkSurface,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) return;
        position = lastKnown;
      }

      if (mounted) {
        ref.read(liveLocationProvider.notifier).state = position;
        _resolveCommuneName(position.latitude, position.longitude);
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
    final walletState = ref.watch(walletProvider);

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

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double contextualSlotBottom = bottomInset + 92.0; // 80px dock + 12px gap
    final double mapControlsBottom = contextualSlotBottom + 96.0; // Au-dessus de la carte KPI / Mission

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
                      Icon(LucideIcons.wifi_off, size: 16, color: Colors.white),
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
            padding: const EdgeInsets.fromLTRB(-100, 0, 0, -100),
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
                      '${_currentCommuneName ?? user?.name ?? 'Technicien'} • ${isCar ? 'Voiture' : 'Moto Express'}',
                ),
              ),
              if (_showHardwareStores && _hardwareStoreIcon != null)
                ...kDakarHardwareStores.map((store) {
                  final distMeters = Geolocator.distanceBetween(
                    currentTechPosition.latitude,
                    currentTechPosition.longitude,
                    store.latitude,
                    store.longitude,
                  );
                  final distKm = (distMeters / 1000).toStringAsFixed(1);
                  return Marker(
                    markerId: MarkerId(store.id),
                    position: LatLng(store.latitude, store.longitude),
                    icon: _hardwareStoreIcon!,
                    anchor: const Offset(0.5, 0.95),
                    onTap: () => _showHardwareStoreDetails(store, distKm),
                  );
                }),
            },
          ),

          // 2. High-Tech Cockpit Driver Bar (Slate 900 Glass / Pill)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Slate 900
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isOnline
                      ? ProTheme.primaryLight.withValues(alpha: 0.6)
                      : const Color(0xFF334155),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOnline
                        ? ProTheme.primaryEmerald.withValues(alpha: 0.25)
                        : Colors.black54,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile Avatar Button
                  InkWell(
                    onTap: () {
                      ProHapticService.instance.onSelectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOnline
                              ? ProTheme.primaryLight
                              : const Color(0xFF475569),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: ProTheme.primaryEmerald,
                        child: Text(
                          (user?.name.isNotEmpty == true ? user!.name[0] : 'T')
                              .toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Center Driver Availability Switch
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!isOnline) {
                          ProHapticService.instance.onSliderConfirmed();
                        } else {
                          ProHapticService.instance.onOfferDismissed();
                        }
                        ref.read(isOnlineProvider.notifier).toggleOnline();
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? ProTheme.primaryEmerald.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isOnline
                                        ? const Color(0x9910B981)
                                        : const Color(0x66EF4444),
                                    blurRadius: isOnline ? 10 : 4,
                                    spreadRadius: isOnline ? 2 : 0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isOnline ? 'EN LIGNE' : 'EN PAUSE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: isOnline
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    isOnline
                                        ? 'Prêt pour missions'
                                        : 'Touchez pour activer',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isOnline
                                  ? LucideIcons.power
                                  : LucideIcons.play,
                              color: isOnline
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Wallet Quick Capsule
                  InkWell(
                    onTap: () {
                      ProHapticService.instance.onSelectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: walletState.balance >= 500
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                              : const Color(0xFFEF4444).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.wallet,
                            size: 15,
                            color: walletState.balance >= 500
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${walletState.balance.toStringAsFixed(0)} F',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Demand & Zone Capsule (under Cockpit Bar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 78,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xEE0B1120),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.zap, color: Color(0xFFF59E0B), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    _currentCommuneName != null
                        ? '$_currentCommuneName • Forte demande ⚡'
                        : 'Dakar • Forte demande ⚡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Action Controls (Quincailleries & Recenter)
          Positioned(
            right: 16,
            bottom: mapControlsBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'toggle_hardware_stores',
                  backgroundColor: _showHardwareStores
                      ? const Color(0xFFD97706)
                      : ProTheme.darkCard,
                  foregroundColor:
                      _showHardwareStores ? Colors.black : Colors.white70,
                  onPressed: () {
                    setState(() {
                      _showHardwareStores = !_showHardwareStores;
                    });
                    AppToast.show(
                      context,
                      title: _showHardwareStores ? 'Quincailleries' : 'Carte épurée',
                      message: _showHardwareStores
                          ? 'Affichage des quincailleries de Dakar activé.'
                          : 'Quincailleries masquées sur la carte.',
                      type: AppToastType.info,
                    );
                  },
                  tooltip: 'Quincailleries Dakar',
                  child: const Icon(LucideIcons.store, size: 18),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenter_driver_pos',
                  backgroundColor: ProTheme.darkCard,
                  foregroundColor: ProTheme.primaryLight,
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(currentTechPosition, 16.0),
                    );
                  },
                  tooltip: 'Recentrer',
                  child: const Icon(LucideIcons.locate_fixed),
                ),
              ],
            ),
          ),

          // 4. Active Mission Floating Banner
          if (activeMission != null)
            Positioned(
              bottom: contextualSlotBottom,
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
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: ProTheme.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: ProTheme.amber.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ProTheme.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(LucideIcons.navigation,
                            color: ProTheme.amber, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'MISSION EN COURS',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: ProTheme.amber,
                                      letterSpacing: 0.6),
                                ),
                                const Spacer(),
                                Text(
                                  activeMission.status.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
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
                              _extractCommuneName(activeMission.addressText),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_extractCommuneName(activeMission.addressText) !=
                                activeMission.addressText)
                              Text(
                                activeMission.addressText,
                                style: const TextStyle(
                                    fontSize: 11, color: ProTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevron_right,
                          color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Quick KPI Bottom Bar
          if (activeMission == null)
            Positioned(
              bottom: contextualSlotBottom,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: ProTheme.darkBorder, width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 14,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildKpiItem(
                        'Note Pro',
                        '${profile?.averageRating.toStringAsFixed(1) ?? '5.0'} ★',
                        LucideIcons.star,
                        Colors.amber),
                    Container(width: 1, height: 32, color: ProTheme.darkBorder),
                    _buildKpiItem(
                        'Véhicule',
                        isCar ? 'Voiture' : 'Moto',
                        isCar ? LucideIcons.car : LucideIcons.bike,
                        ProTheme.primaryLight),
                    Container(width: 1, height: 32, color: ProTheme.darkBorder),
                    _buildKpiItem(
                        'Statut',
                        isOnline ? 'En Ligne' : 'Pause',
                        LucideIcons.radio,
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
      extendBody: true,
      bottomNavigationBar: _buildFloatingDock(context, activeMission),
    );
  }

  Widget _buildFloatingDock(BuildContext context, dynamic activeMission) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Slate 900
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: const Color(0xFF334155), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(
                index: 0,
                icon: LucideIcons.map,
                label: 'Carte',
                isSelected: _currentBottomNav == 0,
                onTap: () {
                  ProHapticService.instance.onSelectionClick();
                  setState(() => _currentBottomNav = 0);
                },
              ),
              _buildDockItem(
                index: 1,
                icon: LucideIcons.clock,
                label: 'Mission',
                isSelected: _currentBottomNav == 1,
                badge: activeMission != null,
                onTap: () {
                  ProHapticService.instance.onSelectionClick();
                  setState(() => _currentBottomNav = 1);
                  if (activeMission != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveMissionScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  }
                },
              ),
              _buildDockItem(
                index: 2,
                icon: LucideIcons.receipt,
                label: 'Historique',
                isSelected: _currentBottomNav == 2,
                onTap: () {
                  ProHapticService.instance.onSelectionClick();
                  setState(() => _currentBottomNav = 2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              _buildDockItem(
                index: 3,
                icon: LucideIcons.user,
                label: 'Profil',
                isSelected: _currentBottomNav == 3,
                onTap: () {
                  ProHapticService.instance.onSelectionClick();
                  setState(() => _currentBottomNav = 3);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        constraints: const BoxConstraints(
            minWidth: AppTouchTarget.standard,
            minHeight: AppTouchTarget.standard),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: isSelected ? 23 : 21,
                  color:
                      isSelected ? ProTheme.primaryLight : ProTheme.textMuted,
                ),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ProTheme.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? ProTheme.primaryLight : ProTheme.textMuted,
              ),
            ),
          ],
        ),
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
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ProTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingOfferOverlay(
      BuildContext context, IncomingOfferState offerState) {
    final offer = offerState.offer;
    final remainingSeconds = offerState.remainingSeconds;
    final totalSeconds = offerState.totalSeconds;
    final notifier = ref.read(incomingOfferProvider.notifier);

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ProTheme.darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ProTheme.darkBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar: Alerte, Timer Canvas haute visibilité, Bouton Fermer discret
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ProTheme.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ProTheme.amber.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.zap,
                                  color: ProTheme.amber, size: 16),
                              SizedBox(width: 5),
                              Text(
                                'Nouvelle intervention',
                                style: TextStyle(
                                  color: ProTheme.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Compte à rebours circulaire dynamique haute visibilité
                        CircularCountdownTimer(
                          remainingSeconds: remainingSeconds,
                          totalSeconds: totalSeconds,
                          size: 58,
                        ),

                        // Bouton discret "Ignorer" (Touch target >= 48px)
                        IconButton(
                          onPressed: () => notifier.declineOffer(),
                          icon: const Icon(LucideIcons.x,
                              color: ProTheme.textMuted, size: 22),
                          tooltip: 'Ignorer l\'offre',
                          style: IconButton.styleFrom(
                            backgroundColor: ProTheme.darkSurface,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nom Client & Catégorie
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.clientName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CategoryHelper.getCategoryColor(
                                          offer.categoryId)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${CategoryHelper.getCategoryEmoji(offer.categoryId)} ${CategoryHelper.getCategoryName(offer.categoryId)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: CategoryHelper.getCategoryColor(
                                        offer.categoryId),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Adresse & Distance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ProTheme.darkBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.map_pin,
                              color: ProTheme.primaryLight, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _extractCommuneName(offer.addressText),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_extractCommuneName(offer.addressText) !=
                                    offer.addressText)
                                  Text(
                                    offer.addressText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ProTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: ProTheme.primaryEmerald
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${offer.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ProTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description / Diagnostic
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
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
                                  LucideIcons.image_off,
                                  size: 36,
                                  color: Colors.grey,
                                ),
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
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // État solde (affiché uniquement si recharge requise, aucun montant de débit affiché)
                    Builder(
                      builder: (ctx) {
                        final wallet = ref.watch(walletProvider);
                        final hasEnough = wallet.balance >= 500;
                        if (hasEnough) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Solde insuffisant pour recevoir cette mission. Veuillez recharger votre compte.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // SLIDE TO ACCEPT GESTUEL (Anti-clic accidentel)
                    Builder(
                      builder: (ctx) {
                        final wallet = ref.watch(walletProvider);
                        final hasEnough = wallet.balance >= 500;

                        if (!hasEnough) {
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const WalletScreen()),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  color: Colors.black, size: 20),
                              label: const Text(
                                'Recharger mon compte',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProTheme.amber,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          );
                        }

                        return SlideToAccept(
                          label: 'GLISSER POUR ACCEPTER',
                          activeColor: const Color(0xFF10B981),
                          onConfirmed: () async {
                            final accepted = await notifier.acceptOffer();
                            if (accepted) {
                              ref.read(walletProvider.notifier).fetchWallet();
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ActiveMissionScreen(),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
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
