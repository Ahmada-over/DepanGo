import 'package:flutter/material.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    AppToastType type = AppToastType.info,
  }) {
    Color bg;
    IconData icon;

    switch (type) {
      case AppToastType.success:
        bg = const Color(0xFF0F766E);
        icon = Icons.check_circle_rounded;
        break;
      case AppToastType.error:
        bg = const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        break;
      case AppToastType.warning:
        bg = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case AppToastType.info:
        bg = const Color(0xFF1E293B);
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
