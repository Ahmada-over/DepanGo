import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../core/theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        title: const Text('Notifications',
            style: TextStyle(
                color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text('Aucune notification pour le moment.',
                  style: TextStyle(color: AppTheme.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.bell_ring,
                        color: AppTheme.primaryEmerald),
                  ),
                  title: Text(notif.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif.message),
                  trailing: Text(
                    "${notif.time.hour.toString().padLeft(2, '0')}:${notif.time.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
