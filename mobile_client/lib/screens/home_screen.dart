import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techconnect_mobile/screens/tracking_chat_screen.dart';
import '../core/theme.dart';
import '../core/design_tokens.dart';
import '../services/client_haptic_service.dart';
import 'location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/map_style.dart';
import '../core/app_toast.dart';
import 'package:techconnect_mobile/models/models.dart';
import '../providers/app_providers.dart';
import '../providers/connectivity_provider.dart';
import 'bookings_history_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'login_screen.dart';
import 'profile_tab.dart';
import 'notifications_screen.dart';
import 'all_services_screen.dart';
import 'map_selection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocation();
      ref.read(activeBookingProvider.notifier).fetchActiveBooking();
    });
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
            '[Location] Location services disabled, checking last known or requesting...');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Location] Location permission denied: $permission');
        return;
      }

      // 1. Try fast last known position first (instant)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. If no cached position, get fresh current position with 8s timeout
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      debugPrint(
          '[Location] GPS coordinates: ${position.latitude}, ${position.longitude}');

      // 3. Reverse geocode coordinates to human-readable address
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
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

          address = parts.join(', ');
        }
      } catch (geoError) {
        debugPrint('[Location] Reverse geocoding error: $geoError');
      }

      if (address.isEmpty) {
        address =
            'Dakar (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})';
      }

      if (mounted) {
        ref.read(selectedLocationProvider.notifier).state = address;
        debugPrint('[Location] Topbar location updated to: $address');
      }
    } catch (e) {
      debugPrint('[Location] Error fetching location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  final List<Map<String, dynamic>> _popularServices = [
    {
      'name': 'Froid & Clim',
      'icon': LucideIcons.snowflake,
      'catId': 'cat_hvac'
    },
    {'name': 'Plomberie', 'icon': LucideIcons.droplet, 'catId': 'cat_plumbing'},
    {'name': 'Électricité', 'icon': LucideIcons.zap, 'catId': 'cat_electrical'},
    {
      'name': 'Lave-Linge & Frigo',
      'icon': LucideIcons.refrigerator,
      'catId': 'cat_appliances'
    },
    {
      'name': 'Électroménager',
      'icon': LucideIcons.microwave,
      'catId': 'cat_appliances'
    },
    {
      'name': 'Urgence Express',
      'icon': LucideIcons.zap,
      'catId': 'cat_express'
    },
    {
      'name': 'Tous les Métiers',
      'icon': LucideIcons.layout_grid,
      'catId': 'cat_plumbing'
    },
  ];

  final List<Map<String, dynamic>> _recommendedServices = [
    {
      'title': 'Entretien & Recharge Climatisation',
      'category': 'Climatisation & Froid',
      'rating': '4.8',
      'reviews': '1.8K',
      'duration': '60 mins',
      'badge': 'Très Demandé',
      'price': 'Sur devis direct',
      'catId': 'cat_hvac',
    },
    {
      'title': 'Réparation Fuite d\'Eau & Débouchage',
      'category': 'Plomberie & Sanitaire',
      'rating': '4.9',
      'reviews': '2.3K',
      'duration': '45 mins',
      'badge': 'Populaire',
      'price': 'Sur devis direct',
      'catId': 'cat_plumbing',
    },
    {
      'title': 'Dépannage Disjoncteur & Court-Circuit',
      'category': 'Électricité Générale',
      'rating': '4.9',
      'reviews': '950',
      'duration': '30 mins',
      'badge': 'Recommandé',
      'price': 'Sur devis direct',
      'catId': 'cat_electrical',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(serverConnectivityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.amber.shade50,
                child: Shimmer.fromColors(
                  baseColor: Colors.amber.shade800,
                  highlightColor: Colors.amber.shade400,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.wifi_off, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Reconnexion au réseau en cours...',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex > 3 ? 3 : _currentIndex,
                children: [
                  _buildHomeContent(context),
                  const BookingsHistoryScreen(),
                  _buildPlaceholderTab('Favoris', LucideIcons.heart),
                  const ProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final user = ref.watch(authProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 12.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Booking Banner
          if (ref.watch(activeBookingProvider) != null &&
              !['completed', 'cancelled', 'no_technician_found']
                  .contains(ref.watch(activeBookingProvider)!.status)) ...[
            _buildActiveBookingBanner(ref.watch(activeBookingProvider)!),
            const SizedBox(height: 16),
          ],
          // 1. Top Greeting & User Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name != null && user!.name.isNotEmpty
                          ? 'Bonjour, ${user.name} 👋'
                          : 'Bonjour 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'De quel dépannage avez-vous besoin ?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final notifs = ref.watch(appNotificationsProvider);
                      final hasUnread = notifs.any((n) => !n.isRead);

                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.bell,
                                color: AppTheme.textDark),
                            onPressed: () {
                              ClientHapticService.instance.onSelectionClick();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen()));
                            },
                          ),
                          if (hasUnread)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (user == null)
                    ElevatedButton(
                      onPressed: () {
                        ClientHapticService.instance.onSelectionClick();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      child: const Text('Se Connecter',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        ClientHapticService.instance.onSelectionClick();
                        setState(() => _currentIndex = 3);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryEmerald, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: AppTheme.primaryEmerald,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Dakar Location Capsule Pill
          InkWell(
            onTap: () {
              ClientHapticService.instance.onSelectionClick();
              _showLocationModalBottomSheet(context);
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.map_pin,
                        color: AppTheme.primaryEmerald, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LIEU D\'INTERVENTION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        _isFetchingLocation
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[400]!,
                                highlightColor: Colors.grey[100]!,
                                child: const Text(
                                  'Détection de votre position...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              )
                            : Text(
                                selectedLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textDark,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.chevron_down,
                      size: 16, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Smart Search Bar & Quick Suggestion Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search,
                    color: AppTheme.primaryEmerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      ClientHapticService.instance.onSelectionClick();
                      _showQuickBookingCategories(context);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une panne ou un artisan...',
                      hintStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    ClientHapticService.instance.onSelectionClick();
                    _showQuickBookingCategories(context);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(LucideIcons.sliders_horizontal,
                        size: 16, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Prestige Green Hero Banner (LISIBILITÉ MAXIMALE & ZERO JARGON)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF064E3B),
                  Color(0xFF047857),
                  Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Un artisan chez vous en 30 minutes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tarification transparente avant validation • Dépanneurs certifiés',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ClientHapticService.instance.onSoftPulse();
                    _showQuickBookingCategories(context);
                  },
                  icon: const Icon(LucideIcons.arrow_right, size: 18),
                  label: const Text(
                    'Demander un dépannage express',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF064E3B),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Bento Grid of Star Services (2x2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services d\'Artisanat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ClientHapticService.instance.onSelectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllServicesScreen()),
                  );
                },
                child: const Text(
                  'Tous les services >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.22,
            children: [
              _buildBentoServiceCard(
                title: 'Clim & Froid',
                subtitle: 'Recharge & Dépannage',
                icon: LucideIcons.snowflake,
                tintColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                onTap: () => _openBooking(context, 'cat_hvac', 'Froid & Clim'),
              ),
              _buildBentoServiceCard(
                title: 'Plomberie',
                subtitle: 'Fuites & Sanitaire',
                icon: LucideIcons.droplet,
                tintColor: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () =>
                    _openBooking(context, 'cat_plumbing', 'Plomberie'),
              ),
              _buildBentoServiceCard(
                title: 'Électricité',
                subtitle: 'Pannes & Tableaux',
                icon: LucideIcons.zap,
                tintColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                onTap: () =>
                    _openBooking(context, 'cat_electrical', 'Électricité'),
              ),
              _buildBentoServiceCard(
                title: 'Électroménager',
                subtitle: 'Fours, Machines, Froid',
                icon: LucideIcons.microwave,
                tintColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                onTap: () => _openBooking(
                    context, 'cat_appliances', 'Électroménager'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6. Registered Elite Technicians Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artisans d\'Élite Disponibles',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark),
                    ),
                    Text(
                      'Interventions rapides par des professionnels vérifiés',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refresh_ccw,
                    size: 18, color: AppTheme.primaryEmerald),
                onPressed: () {
                  ClientHapticService.instance.onSelectionClick();
                  ref.refresh(registeredTechniciansProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          ref.watch(registeredTechniciansProvider).when(
                data: (techs) {
                  if (techs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Aucun technicien inscrit pour l\'instant.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  }
                  return SizedBox(
                    height: 122,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: techs.length,
                      itemBuilder: (context, index) {
                        final t = techs[index];
                        final name = t['name'] ?? 'Artisan Pro';
                        final rating = t['average_rating'] ?? 5.0;
                        final status = t['availability_status'] ?? 'online';
                        final catList =
                            (t['category_ids'] as List?)?.cast<String>() ?? [];
                        final cats = catList
                            .map((c) => c.replaceAll('cat_', ''))
                            .join(', ');

                        return Container(
                          width: 195,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                                color: const Color(0xFFF1F5F9), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryEmerald,
                                    child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: AppTheme.textDark),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            const Icon(LucideIcons.badge_check,
                                                size: 13,
                                                color: AppTheme.primaryEmerald),
                                          ],
                                        ),
                                        Text(
                                          cats.isNotEmpty ? cats : 'Artisan polyvalent',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: status == 'online'
                                          ? AppTheme.primaryEmerald
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                      status == 'online'
                                          ? 'Disponible'
                                          : 'En intervention',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: status == 'online'
                                              ? AppTheme.primaryEmerald
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  const Icon(LucideIcons.star,
                                      size: 13, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating is double
                                        ? rating.toStringAsFixed(1)
                                        : '$rating',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(LucideIcons.map_pin,
                                      size: 11, color: AppTheme.textMuted),
                                  const SizedBox(width: 3),
                                  const Expanded(
                                    child: Text(
                                      'À ~1.5 km • Dakar',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: 122,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
          const SizedBox(height: 24),

          // 6. Recommended For You Horizontal Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recommandés pour vous',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllServicesScreen()));
                },
                child: const Text('Voir tout >',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _recommendedServices.length,
              itemBuilder: (context, index) {
                final rec = _recommendedServices[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.wrench,
                                  size: 40, color: AppTheme.primaryEmerald),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rec['badge']!,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rec['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.star,
                              size: 13, color: Colors.amber),
                          Text(' ${rec['rating']} (${rec['reviews']})  •  ',
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted)),
                          Text(rec['duration']!,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(LucideIcons.badge_check,
                              size: 12, color: AppTheme.primaryEmerald),
                          SizedBox(width: 4),
                          Text('Technicien Certifié',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryEmerald)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              rec['price']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: () => _openBooking(
                                context, rec['catId']!, rec['title']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryEmerald,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Commander',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 7. Feature Badges Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureBadge(
                    LucideIcons.shield_check, 'Techniciens\nCertifiés'),
                _buildFeatureBadge(LucideIcons.banknote, 'Paiement\nDirect'),
                _buildFeatureBadge(LucideIcons.shield, 'Garantie\nQualité'),
                _buildFeatureBadge(LucideIcons.locate, 'Suivi GPS\nTemps Réel'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLocationModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentLocation = ref.watch(selectedLocationProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre position actuelle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map Card Preview (Uber style)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LocationPickerScreen()),
                      );
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Static map preview (disabled interaction)
                            const AbsorbPointer(
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                      14.6928, -17.4467), // Default Dakar
                                  zoom: 14.0,
                                ),
                                style: kMinimalMapStyle,
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                            ),

                            // Center Marker
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 24.0),
                                child: Icon(
                                  LucideIcons.map_pin,
                                  size: 32,
                                  color: AppTheme.primaryEmerald,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 2))
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Label Overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent
                                  ],
                                )),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.locate,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currentLocation,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Text instructions
                  Center(
                    child: Text(
                      'Appuyez sur la carte pour ajuster votre position exacte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final notifications = ref.watch(appNotificationsProvider);

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(appNotificationsProvider.notifier)
                              .markAllAsRead();
                        },
                        child: const Text('Tout marquer comme lu',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryEmerald,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Aucune notification pour l\'instant.',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.white
                                  : AppTheme.primaryLight
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: notif.isRead
                                      ? const Color(0xFFF1F5F9)
                                      : AppTheme.primaryEmerald
                                          .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: notif.type == 'chat'
                                      ? AppTheme.primaryEmerald
                                          .withValues(alpha: 0.15)
                                      : AppTheme.primaryEmerald
                                          .withValues(alpha: 0.2),
                                  child: Icon(
                                    notif.type == 'chat'
                                        ? LucideIcons.message_square
                                        : LucideIcons.bell_ring,
                                    size: 16,
                                    color: notif.type == 'chat'
                                        ? AppTheme.primaryEmerald
                                        : AppTheme.primaryEmerald,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(notif.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppTheme.textDark)),
                                      const SizedBox(height: 2),
                                      Text(notif.message,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientAccountTab(BuildContext context) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.user, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('Non Connecté',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Connectez-vous pour voir vos commandes',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Se Connecter',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryEmerald,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          Text(user.email,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(user.phone,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.badge_check,
                    size: 16, color: AppTheme.primaryEmerald),
                SizedBox(width: 6),
                Text('Compte Client Certifié',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.user,
                      color: AppTheme.primaryEmerald),
                  title: const Text('Modifier mes informations',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nom, email, téléphone',
                      style: TextStyle(fontSize: 11)),
                  trailing:
                      const Icon(LucideIcons.chevron_right, color: Colors.grey),
                  onTap: () => _showEditProfileDialog(context, user),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.clock,
                      color: AppTheme.primaryEmerald),
                  title: const Text('Historique de mes commandes',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing:
                      const Icon(LucideIcons.chevron_right, color: Colors.grey),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(LucideIcons.credit_card,
                      color: AppTheme.primaryEmerald),
                  title: Text('Mode de règlement direct',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Sur devis • Espèces / Mobile Money',
                      style: TextStyle(fontSize: 11)),
                  trailing: Icon(LucideIcons.chevron_right, color: Colors.grey),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.log_out, color: Colors.red),
                  title: const Text('Se Déconnecter',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red)),
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier mes informations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom complet', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Téléphone', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald),
            onPressed: () {
              ref.read(authProvider.notifier).updateProfile(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
              AppToast.show(
                context,
                title: 'Profil Mis à Jour !',
                message: 'Vos informations personnelles ont été enregistrées.',
                type: AppToastType.success,
              );
            },
            child: const Text('Enregistrer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tintColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        ClientHapticService.instance.onSelectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: tintColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: tintColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Icon(icon, color: tintColor, size: 22),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    LucideIcons.arrow_up_right,
                    size: 14,
                    color: tintColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryEmerald, size: 20),
        ),
        const SizedBox(height: 4),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: AppTheme.primaryEmerald),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildClientNavItem(0, LucideIcons.house, 'Accueil'),
                  _buildClientNavItem(1, LucideIcons.list, 'Demandes'),
                  _buildClientNavItem(2, LucideIcons.heart, 'Favoris'),
                  _buildClientNavItem(3, LucideIcons.user, 'Profil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        ClientHapticService.instance.onSelectionClick();
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        constraints: const BoxConstraints(
            minWidth: AppTouchTarget.standard,
            minHeight: AppTouchTarget.standard),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 22 : 20,
              color: isSelected ? AppTheme.primaryEmerald : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryEmerald : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickBookingCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisissez un service rapide',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryDark)),
              const SizedBox(height: 16),
              ..._popularServices.map((cat) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      child: Icon(cat['icon'], color: AppTheme.primaryEmerald),
                    ),
                    title: Text(cat['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(LucideIcons.chevron_right,
                        color: Colors.grey),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openBooking(context, cat['catId'], cat['name']);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _openBooking(
      BuildContext context, String catId, String categoryName) async {
    // Check if at least one technician covers this category before opening booking
    final techs =
        await ref.read(categoryFilteredTechniciansProvider(catId).future);
    final categories = await ref.read(categoryListProvider.future);
    final category = categories.firstWhere((c) => c.id == catId,
        orElse: () => ServiceCategoryModel(
            id: catId, name: categoryName, description: '', iconName: 'build'));
    final basePrice = category.basePrice;

    if (!context.mounted) return;

    if (techs.isEmpty) {
      AppToast.show(
        context,
        title: 'Aucun technicien disponible',
        message:
            'Pas de technicien qualifié en $categoryName dans votre zone pour l\'instant.',
        type: AppToastType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapSelectionScreen(
                        categoryId: catId,
                        categoryName: categoryName,
                        basePrice: basePrice,
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.map),
                label: const Text('Localiser et Commander'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveBookingBanner(BookingModel booking) {
    if (booking.status == 'cancelled' || booking.status == 'completed') {
      return const SizedBox.shrink();
    }

    String statusText = 'En attente d\'un technicien...';
    Color bannerColor = AppTheme.primaryEmerald;
    IconData statusIcon = LucideIcons.hourglass;

    if (booking.status == 'matched') {
      statusText = 'Un technicien a été trouvé ! En route.';
      bannerColor = AppTheme.primaryDark;
      statusIcon = LucideIcons.car;
    } else if (booking.status == 'in_progress') {
      statusText = 'Le technicien est en route vers vous.';
      bannerColor = AppTheme.primaryEmerald;
      statusIcon = LucideIcons.bike;
    } else if (booking.status == 'on_site') {
      statusText = 'Le technicien est sur place !';
      bannerColor = AppTheme.primaryEmerald;
      statusIcon = LucideIcons.wrench;
    }

    return InkWell(
      onTap: () {
        ref.read(activeBookingProvider.notifier).loadActiveBooking(booking);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TrackingChatScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.1),
          border: Border.all(color: bannerColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bannerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.status == 'pending'
                        ? 'Recherche en cours...'
                        : 'Intervention en cours',
                    style: TextStyle(
                      color: bannerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevron_right, color: bannerColor, size: 16),
          ],
        ),
      ),
    );
  }
}
