import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _techMotoIcon;
  BitmapDescriptor? _techCarIcon;
  List<LatLng> _polylineCoordinates = [];
  LatLng? _lastRouteStart;
  LatLng? _lastRouteEnd;
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
    PolylinePoints polylinePoints = PolylinePoints(apiKey: AppConfig.googleMapsApiKey);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(startLat, startLng),
        destination: PointLatLng(endLat, endLng),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _polylineCoordinates = result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    super.dispose();
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

  String _getStatusDescription(String status, String? eta) {
    if (status == 'matched') {
      return 'Technicien assigné • Préparation en cours';
    }
    if (status == 'in_progress') {
      return 'En route • ETA ${eta ?? '15 min'}';
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
    final notifier = ref.read(activeBookingProvider.notifier);

    final status = activeBooking?.status ?? 'matched';
    final stepIdx = _getStepIndex(status);
    final etaText = activeBooking?.scheduledEta ?? '15 mins';

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

    if (activeBooking != null && techLat != null && techLng != null) {
      final start = LatLng(techLat!, techLng!);
      final end = LatLng(activeBooking.latitude, activeBooking.longitude);
      if (_lastRouteStart != start || _lastRouteEnd != end) {
        _lastRouteStart = start;
        _lastRouteEnd = end;
        _fetchRoute(start.latitude, start.longitude, end.latitude, end.longitude);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Full Screen Background
          if (activeBooking != null)
            Positioned.fill(
              child: GoogleMap(
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
                  if (techLat != null && techLng != null)
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.85),
                      width: 5,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      points: _polylineCoordinates.isNotEmpty 
                        ? _polylineCoordinates 
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
                  if (techLat != null && techLng != null)
                    Marker(
                      markerId: const MarkerId('tech'),
                      position: LatLng(techLat!, techLng!),
                      icon: techTransport == 'voiture'
                          ? (_techCarIcon ?? BitmapDescriptor.defaultMarker)
                          : (_techMotoIcon ?? BitmapDescriptor.defaultMarker),
                      anchor: const Offset(0.5, 0.85),
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
                    subtitle: _getStatusDescription(status, etaText),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Modal Sheet (Draggable)
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.9,
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
                                            Text(etaText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Action Buttons
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.submitReview(selectedStars, commentController.text);
                Navigator.pop(ctx);
                Navigator.pop(context);
                AppToast.show(
                  context,
                  title: 'Prestation Clôturée !',
                  message: 'Merci pour votre évaluation $selectedStars ★.',
                  type: AppToastType.success,
                );
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
                Navigator.pop(ctx);
                Navigator.pop(context);
                AppToast.show(
                  context,
                  title: 'Intervention annulée',
                  message: 'L\'intervention a bien été annulée.',
                  type: AppToastType.error,
                );
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}
