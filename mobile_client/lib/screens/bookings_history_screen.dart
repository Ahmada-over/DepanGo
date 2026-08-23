import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/models.dart';
import '../core/theme.dart';
import 'tracking_chat_screen.dart';
import 'booking_details_screen.dart';
import 'package:intl/intl.dart';

class BookingsHistoryScreen extends ConsumerWidget {
  const BookingsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userBookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Mes demandes',
              style: TextStyle(
                  color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: AppTheme.primaryEmerald,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primaryEmerald,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'En cours'),
              Tab(text: 'Terminé'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryDark),
              onPressed: () => ref.refresh(userBookingsProvider),
            ),
          ],
        ),
        body: historyAsync.when(
          data: (bookings) {
            final pending = bookings
                .where((b) => ['pending', 'no_technician_found', 'expired']
                    .contains(b.status))
                .toList();
            final inProgress = bookings
                .where((b) => ['matched', 'in_progress', 'on_site', 'arrived']
                    .contains(b.status))
                .toList();
            final completed = bookings
                .where((b) => ['completed', 'cancelled'].contains(b.status))
                .toList();

            return TabBarView(
              children: [
                _buildBookingList(
                    context, ref, pending, 'Aucune demande en attente.'),
                _buildBookingList(
                    context, ref, inProgress, 'Aucune demande en cours.'),
                _buildBookingList(context, ref, completed, 'Aucun historique.'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, WidgetRef ref,
      List<BookingModel> bookings, String emptyMsg) {
    if (bookings.isEmpty) {
      return Center(
          child: Text(emptyMsg,
              style: const TextStyle(color: AppTheme.textMuted)));
    }
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(userBookingsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];
          return _buildBookingCard(context, ref, b);
        },
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, WidgetRef ref, BookingModel booking) {
    // Dynamic technician name lookup
    String dynamicTechName = booking.technicianName ?? 'Technicien assigné';
    if (booking.technicianId != null && booking.technicianName == null) {
      final techsAsync = ref.watch(registeredTechniciansProvider);
      techsAsync.whenData((techs) {
        try {
          final tech = techs.firstWhere((t) => t['user_id'] == booking.technicianId);
          dynamicTechName = tech['name'] ?? 'Technicien assigné';
        } catch (_) {}
      });
    }

    // Format date
    final formattedDate =
        DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt);

    // Status color
    Color statusColor = Colors.grey;
    if (['matched', 'in_progress', 'on_site', 'arrived']
        .contains(booking.status)) statusColor = AppTheme.primaryEmerald;
    if (booking.status == 'completed') statusColor = AppTheme.primaryEmerald;
    if (['cancelled', 'expired', 'no_technician_found']
        .contains(booking.status)) statusColor = Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: InkWell(
        onTap: () {
          if (['completed', 'cancelled', 'expired'].contains(booking.status)) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)));
          } else {
            ref.read(activeBookingProvider.notifier).loadActiveBooking(booking);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrackingChatScreen()));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking.categoryId.toUpperCase().replaceAll('CAT_', ''),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(booking.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(booking.addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (booking.technicianId != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryEmerald,
                      child: const Icon(Icons.person,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dynamicTechName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark)),
                          Text('Cliquez pour suivre',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
