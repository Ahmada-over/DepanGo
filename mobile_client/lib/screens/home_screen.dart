import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techconnect_mobile/screens/tracking_chat_screen.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import 'package:techconnect_mobile/models/models.dart';
import '../providers/app_providers.dart';
import 'create_booking_screen.dart';
import 'bookings_history_screen.dart';
import 'login_screen.dart';
import 'map_selection_screen.dart';
import 'map_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _popularServices = [
    {
      'name': 'House Cleaning',
      'icon': Icons.cleaning_services_outlined,
      'catId': 'cat_cleaning'
    },
    {'name': 'AC Repair', 'icon': Icons.ac_unit_outlined, 'catId': 'cat_hvac'},
    {
      'name': 'Plumbing',
      'icon': Icons.water_drop_outlined,
      'catId': 'cat_plumbing'
    },
    {
      'name': 'Electrical',
      'icon': Icons.bolt_outlined,
      'catId': 'cat_electrical'
    },
    {
      'name': 'Washing Machine',
      'icon': Icons.local_laundry_service_outlined,
      'catId': 'cat_appliances'
    },
    {
      'name': 'Refrigerator',
      'icon': Icons.kitchen_outlined,
      'catId': 'cat_appliances'
    },
    {
      'name': 'Microwave Oven',
      'icon': Icons.microwave_outlined,
      'catId': 'cat_appliances'
    },
    {
      'name': 'More Services',
      'icon': Icons.grid_view_outlined,
      'catId': 'cat_plumbing'
    },
  ];

  final List<Map<String, dynamic>> _recommendedServices = [
    {
      'title': 'AC Repair & Servicing',
      'category': 'Climatisation',
      'rating': '4.7',
      'reviews': '1.8K',
      'duration': '60 mins',
      'badge': 'Bestseller',
      'price': 'Sur devis',
      'catId': 'cat_hvac',
    },
    {
      'title': 'Plumbing Leakage Repair',
      'category': 'Plomberie',
      'rating': '4.8',
      'reviews': '2.3K',
      'duration': '45 mins',
      'badge': 'Populaire',
      'price': 'Sur devis',
      'catId': 'cat_plumbing',
    },
    {
      'title': 'Electrical Wiring Fix',
      'category': 'Électricité',
      'rating': '4.9',
      'reviews': '950',
      'duration': '30 mins',
      'badge': 'Recommandé',
      'price': 'Sur devis',
      'catId': 'cat_electrical',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(context),
            const BookingsHistoryScreen(),
            _buildPlaceholderTab(
                'Support & Assistance 24/7', Icons.support_agent),
            _buildClientAccountTab(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Booking Banner
          if (ref.watch(activeBookingProvider) != null) ...[
            _buildActiveBookingBanner(ref.watch(activeBookingProvider)!),
            const SizedBox(height: 16),
          ],
          // 1. Header Location Picker (Opens ModalBottomSheet on tap)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showLocationModalBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.primaryEmerald, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textDark),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 18, color: AppTheme.textDark),
                                ],
                              ),
                              const Text(
                                'Changer ma position d\'intervention',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                            icon: const Icon(Icons.notifications_none_outlined,
                                color: AppTheme.textDark),
                            onPressed: () =>
                                _showNotificationModalBottomSheet(context),
                          ),
                          if (hasUnread)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
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
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Se Connecter',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.person_outline,
                          color: AppTheme.primaryEmerald),
                      onPressed: () {
                        setState(() => _currentIndex = 3);
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Search Bar with Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.textMuted),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un service (Clim, Plomberie...)',
                      hintStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune,
                      size: 18, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Green Gradient Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF065F46),
                  Color(0xFF047857),
                  Color(0xFF10B981)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primaryEmerald.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Un problème à la maison ?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Text('Techniciens qualifiés en 30 min',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Attribution automatique PostGIS  •  Paiement direct',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openBooking(
                          context, 'cat_express', 'Recherche Rapide'),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Commander en 1-Clic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Popular Services Grid Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Services Populaires',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              Text('Tout voir >',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald)),
            ],
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _popularServices.length,
            itemBuilder: (context, index) {
              final item = _popularServices[index];
              return GestureDetector(
                onTap: () => _openBooking(context, item['catId'], item['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: AppTheme.primaryEmerald, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 5. Registered SaaS Technicians Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Techniciens Certifiés SaaS Pro',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark),
                    ),
                    Text(
                      'Chaque technicien n\'accepte que les demandes de ses spécialités',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh,
                    size: 18, color: AppTheme.primaryEmerald),
                onPressed: () => ref.refresh(registeredTechniciansProvider),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: techs.length,
                      itemBuilder: (context, index) {
                        final t = techs[index];
                        final name = t['name'] ?? 'Technicien Pro';
                        final rating = t['average_rating'] ?? 5.0;
                        final status = t['availability_status'] ?? 'online';
                        final catList =
                            (t['category_ids'] as List?)?.cast<String>() ?? [];
                        final cats = catList
                            .map((c) => c.replaceAll('cat_', ''))
                            .join(', ');

                        return Container(
                          width: 175,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppTheme.primaryEmerald.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primaryEmerald,
                                    child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'T',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.textDark),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 8,
                                      color: status == 'online'
                                          ? Colors.green
                                          : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                      status == 'online'
                                          ? 'En Ligne'
                                          : 'Hors Ligne',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: status == 'online'
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  const Icon(Icons.star,
                                      size: 12, color: Colors.amber),
                                  Text(' $rating',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark)),
                                ],
                              ),
                              const Spacer(),
                              Text('Métiers: $cats',
                                  style: const TextStyle(
                                      fontSize: 9, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: 180,
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
                          width: 140,
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
            children: const [
              Text('Recommandés pour vous',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              Text('Voir tout >',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald)),
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
                          color: Colors.black.withOpacity(0.03),
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
                              child: Icon(Icons.build_circle_outlined,
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
                                color: Colors.white.withOpacity(0.9),
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
                          const Icon(Icons.star, size: 13, color: Colors.amber),
                          Text(' ${rec['rating']} (${rec['reviews']})  •  ',
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted)),
                          Text(rec['duration']!,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.verified,
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
                    Icons.verified_user_outlined, 'Techniciens\nCertifiés'),
                _buildFeatureBadge(Icons.payments_outlined, 'Paiement\nDirect'),
                _buildFeatureBadge(Icons.shield_outlined, 'Garantie\nQualité'),
                _buildFeatureBadge(Icons.my_location, 'Suivi GPS\nTemps Réel'),
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
            final customController = TextEditingController();

            final popularLocations = [
              'Point E, Dakar, Sénégal',
              'Mermoz Pyrotechnie, Dakar',
              'Sacré Cœur 3, Dakar',
              'Les Almadies, Dakar',
              'Plateau, Ave Léopold S. Senghor',
              'Yoff Océan, Dakar',
              'Ouakam, Cité Comico',
            ];

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
                  const Row(
                    children: [
                      Icon(Icons.my_location,
                          color: AppTheme.primaryEmerald, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Définir votre position d\'intervention',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      ref.read(selectedLocationProvider.notifier).state =
                          'Position GPS (14.6937, -17.4441) • Dakar';
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        title: 'Position GPS Détectée !',
                        message: 'Coordonnées (14.6937, -17.4441) configurées.',
                        type: AppToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.primaryEmerald.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              color: AppTheme.primaryEmerald, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Utiliser ma position GPS actuelle',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.primaryDark)),
                                Text('Détection automatique PostGIS Dakar',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppTheme.primaryEmerald),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customController,
                    decoration: InputDecoration(
                      hintText: 'Entrer un quartier ou une rue (ex: Fann Hock)',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: AppTheme.primaryEmerald),
                        onPressed: () {
                          if (customController.text.trim().isNotEmpty) {
                            ref.read(selectedLocationProvider.notifier).state =
                                customController.text.trim();
                            Navigator.pop(context);
                          }
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        ref.read(selectedLocationProvider.notifier).state =
                            val.trim();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text('Quartiers & Locations Populaires',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  Column(
                    children: popularLocations.map((loc) {
                      final isSelected = loc == currentLocation;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: isSelected
                              ? AppTheme.primaryEmerald
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                        title: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryEmerald
                                : AppTheme.textDark,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                size: 18, color: AppTheme.primaryEmerald)
                            : null,
                        onTap: () {
                          ref.read(selectedLocationProvider.notifier).state =
                              loc;
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
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
                                  : AppTheme.primaryLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: notif.isRead
                                      ? const Color(0xFFF1F5F9)
                                      : AppTheme.primaryEmerald
                                          .withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: notif.type == 'chat'
                                      ? Colors.blue.withOpacity(0.2)
                                      : AppTheme.primaryEmerald
                                          .withOpacity(0.2),
                                  child: Icon(
                                    notif.type == 'chat'
                                        ? Icons.message_outlined
                                        : Icons.notifications_active_outlined,
                                    size: 16,
                                    color: notif.type == 'chat'
                                        ? Colors.blue
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
            const Icon(Icons.account_circle_outlined,
                size: 64, color: AppTheme.textMuted),
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
                Icon(Icons.verified, size: 16, color: AppTheme.primaryEmerald),
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
                  leading: const Icon(Icons.person_outline,
                      color: AppTheme.primaryEmerald),
                  title: const Text('Modifier mes informations',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nom, email, téléphone',
                      style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showEditProfileDialog(context, user),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.history, color: AppTheme.primaryEmerald),
                  title: const Text('Historique de mes commandes',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment_outlined,
                      color: AppTheme.primaryEmerald),
                  title: const Text('Mode de règlement direct',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sur devis • Espèces / Mobile Money',
                      style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
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

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.4),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryEmerald,
        unselectedItemColor: AppTheme.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppTheme.primaryEmerald),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon:
                Icon(Icons.calendar_today, color: AppTheme.primaryEmerald),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            activeIcon:
                Icon(Icons.support_agent, color: AppTheme.primaryEmerald),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: AppTheme.primaryEmerald),
            label: 'Compte',
          ),
        ],
      ),
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
                icon: const Icon(Icons.map_outlined),
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
    IconData statusIcon = Icons.hourglass_empty;

    if (booking.status == 'matched') {
      statusText = 'Un technicien a été trouvé ! En route.';
      bannerColor = Colors.blue;
      statusIcon = Icons.directions_car;
    } else if (booking.status == 'in_progress') {
      statusText = 'Le technicien est en route vers vous.';
      bannerColor = Colors.orange;
      statusIcon = Icons.motorcycle;
    } else if (booking.status == 'on_site') {
      statusText = 'Le technicien est sur place !';
      bannerColor = Colors.purple;
      statusIcon = Icons.handyman;
    }

    return InkWell(
      onTap: () {
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
          color: bannerColor.withOpacity(0.1),
          border: Border.all(color: bannerColor.withOpacity(0.5)),
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
                    'Intervention en cours',
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
            Icon(Icons.arrow_forward_ios, color: bannerColor, size: 16),
          ],
        ),
      ),
    );
  }
}
