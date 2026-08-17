import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/pro_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(interventionsHistoryProvider);

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(
        title: const Text('Historique des Interventions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(interventionsHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ProTheme.primaryLight)),
        error: (err, _) => Center(
          child: Text('Erreur : $err', style: const TextStyle(color: ProTheme.textMuted)),
        ),
        data: (missions) {
          if (missions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: ProTheme.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Aucune intervention passée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Vos interventions terminées apparaîtront ici.', style: TextStyle(color: ProTheme.textMuted, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = missions[index];
              return _buildMissionHistoryCard(m);
            },
          );
        },
      ),
    );
  }

  Widget _buildMissionHistoryCard(BookingModel m) {
    final isDone = m.status == 'completed';
    final isCancel = m.status == 'cancelled';
    final color = isDone ? ProTheme.success : (isCancel ? Colors.redAccent : ProTheme.amber);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.clientName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDone ? 'TERMINÉE' : (isCancel ? 'ANNULÉE' : 'EN COURS'),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m.addressText,
            style: const TextStyle(fontSize: 12, color: ProTheme.textMuted),
          ),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${m.description}"',
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${m.createdAt.day.toString().padLeft(2, '0')}/${m.createdAt.month.toString().padLeft(2, '0')}/${m.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: ProTheme.textMuted),
              ),
              const Text(
                'Règlement direct',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ProTheme.primaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
