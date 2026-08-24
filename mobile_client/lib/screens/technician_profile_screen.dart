import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/technician_providers.dart';
import '../core/theme.dart';
import 'package:intl/intl.dart';

class TechnicianProfileScreen extends ConsumerWidget {
  final TechnicianProfileModel technician;
  const TechnicianProfileScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync =
        ref.watch(technicianBookingsProvider(technician.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        title: const Text('Profil Technicien',
            style: TextStyle(
                color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryEmerald,
                    child: Text(
                        technician.userName.isNotEmpty
                            ? technician.userName[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32)),
                  ),
                  const SizedBox(height: 16),
                  Text(technician.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: AppTheme.primaryDark)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                          '${technician.averageRating.toStringAsFixed(1)} (Note)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(width: 16),
                      Icon(
                          technician.verified
                              ? LucideIcons.badge_check
                              : LucideIcons.circle_alert,
                          color: technician.verified
                              ? AppTheme.primaryEmerald
                              : Colors.grey,
                          size: 20),
                      const SizedBox(width: 4),
                      Text(technician.verified ? 'Vérifié' : 'Non vérifié',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Historique des interventions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryDark)),
            ),
            const SizedBox(height: 8),
            bookingsAsync.when(
              data: (bookings) {
                final completedBookings =
                    bookings.where((b) => b.status == 'completed').toList();
                if (completedBookings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Aucune intervention terminée.',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: completedBookings.length,
                  itemBuilder: (context, index) {
                    final b = completedBookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          child: const Icon(LucideIcons.circle_check,
                              color: AppTheme.primaryEmerald),
                        ),
                        title: Text('Intervention Terminée',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(b.createdAt)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Erreur lors du chargement de l\'historique.',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
