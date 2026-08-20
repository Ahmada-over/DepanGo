import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../core/theme.dart';
import 'notifications_screen.dart';
import 'placeholder_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Profile',
                style: TextStyle(
                    color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.primaryDark),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const NetworkImage(
                        'https://i.pravatar.cc/300'), // Placeholder avatar
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryEmerald,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Utilisateur',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark)),
            const SizedBox(height: 4),
            Text(user?.email ?? 'email@example.com',
                style:
                    const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            _buildMenuItem(Icons.person_outline, 'Éditer le profil',
                onTap: () {}),
            _buildMenuItem(Icons.notifications_none, 'Notifications',
                onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()));
            }),
            _buildMenuItem(Icons.security_outlined, 'Sécurité', onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PlaceholderScreen(title: 'Sécurité')));
            }),
            _buildMenuItem(Icons.language, 'Langue',
                trailingText: 'Français', onTap: () {}),
            _buildMenuItem(Icons.remove_red_eye_outlined, 'Mode Sombre',
                trailingWidget: Switch(value: false, onChanged: (v) {})),
            _buildMenuItem(Icons.lock_outline, 'Politique de confidentialité',
                onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlaceholderScreen(
                          title: 'Politique de confidentialité')));
            }),
            _buildMenuItem(Icons.help_outline, 'Centre d\'aide', onTap: () {}),
            _buildMenuItem(Icons.people_outline, 'Inviter des amis',
                onTap: () {}),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Déconnexion',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {String? trailingText, Widget? trailingWidget, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryDark),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
      trailing: trailingWidget ??
          (trailingText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(trailingText,
                        style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                )
              : const Icon(Icons.chevron_right, color: AppTheme.textMuted)),
      onTap: onTap,
    );
  }
}
