import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import 'tracking_chat_screen.dart';

class BookingsHistoryScreen extends ConsumerWidget {
  const BookingsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBooking = ref.watch(activeBookingProvider);
    final historyAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations & Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(userBookingsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(userBookingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Booking Banner if present
            if (activeBooking != null) ...[
              const Text('Réservation en cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  ref.read(activeBookingProvider.notifier).loadActiveBooking(activeBooking);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingChatScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppTheme.primaryEmerald, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demande en cours (${_formatStatus(activeBooking.status)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(activeBooking.description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.primaryEmerald),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('Historique Passé (Base de données)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            historyAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.history_outlined, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text('Aucune commande enregistrée', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: bookings.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildHistoryItem(
                        category: _formatCategory(b.categoryId),
                        description: b.description,
                        date: '${b.createdAt.day}/${b.createdAt.month}/${b.createdAt.year} à ${b.createdAt.hour}:${b.createdAt.minute.toString().padLeft(2, '0')}',
                        status: _formatStatus(b.status),
                        priceNote: 'Payé direct (Sur devis)',
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Column(
                children: List.generate(4, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: Text('Erreur de chargement: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCategory(String catId) {
    if (catId == 'cat_plumbing') return 'Plomberie';
    if (catId == 'cat_hvac') return 'Climatisation';
    if (catId == 'cat_electrical') return 'Électricité';
    if (catId == 'cat_appliances') return 'Électroménager';
    return 'Dépannage';
  }

  static String _formatStatus(String status) {
    if (status == 'completed') return 'Terminée';
    if (status == 'in_progress') return 'En cours';
    if (status == 'matched') return 'Technicien Assigné';
    return 'En attente';
  }

  Widget _buildHistoryItem({
    required String category,
    required String description,
    required String date,
    required String status,
    required String priceNote,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryEmerald)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text(priceNote, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
