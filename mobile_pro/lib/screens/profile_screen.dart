import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../providers/pro_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final profile = ref.watch(technicianProfileProvider);

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(title: const Text('Profil & Paramètres Pro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ProTheme.primaryEmerald,
                    child: Text(
                      (user?.name.isNotEmpty == true ? user!.name[0] : 'T').toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.name ?? 'Technicien Pro',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: ProTheme.primaryLight, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '+221 77 000 00 00',
                    style: const TextStyle(fontSize: 13, color: ProTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${profile?.averageRating.toStringAsFixed(1) ?? '5.0'} / 5.0 (Avis Clients)',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transport Mode Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProTheme.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MODE DE TRANSPORT ACTIF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProTheme.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        profile?.transportMode == 'voiture' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                        color: ProTheme.primaryLight,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile?.transportMode == 'voiture' ? 'Voiture / Fourgonnette' : 'Moto Express',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Categories Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProTheme.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SPÉCIALITÉS DÉCLARÉES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProTheme.textMuted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile?.categoryIds ?? ['cat_plumbing']).map((cat) {
                      String label = 'Dépannage';
                      if (cat.contains('plumb')) label = '🚰 Plomberie Express';
                      if (cat.contains('hvac')) label = '❄️ Froid & Climatisation';
                      if (cat.contains('electr')) label = '⚡ Électricité Générale';
                      if (cat.contains('appliance')) label = '🔌 Électroménager';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ProTheme.darkSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ProTheme.primaryLight.withValues(alpha: 0.3)),
                        ),
                        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    AppToast.show(context, title: 'Déconnexion', message: 'Vous avez été déconnecté.', type: AppToastType.info);
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Se Déconnecter', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
