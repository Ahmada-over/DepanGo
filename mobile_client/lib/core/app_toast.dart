import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'theme.dart';

enum AppToastType { success, info, warning, error }

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppToast {
  static void show(
    BuildContext? context, {
    required String title,
    String? message,
    AppToastType type = AppToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = rootScaffoldMessengerKey.currentState ??
        (context != null && context.mounted
            ? ScaffoldMessenger.maybeOf(context)
            : null);

    if (messenger == null) return;

    Color bgGradientStart;
    Color bgGradientEnd;
    IconData icon;
    Color iconColor;

    switch (type) {
      case AppToastType.success:
        bgGradientStart = const Color(0xFF064E3B);
        bgGradientEnd = const Color(0xFF059669);
        icon = LucideIcons.circle_check;
        iconColor = const Color(0xFF34D399);
        break;
      case AppToastType.info:
        bgGradientStart = const Color(0xFF1E3A8A);
        bgGradientEnd = const Color(0xFF2563EB);
        icon = LucideIcons.info;
        iconColor = const Color(0xFF60A5FA);
        break;
      case AppToastType.warning:
        bgGradientStart = const Color(0xFF78350F);
        bgGradientEnd = const Color(0xFFD97706);
        icon = LucideIcons.triangle_alert;
        iconColor = const Color(0xFFFBBF24);
        break;
      case AppToastType.error:
        bgGradientStart = const Color(0xFF881337);
        bgGradientEnd = const Color(0xFFE11D48);
        icon = LucideIcons.circle_alert;
        iconColor = const Color(0xFFFB7185);
        break;
    }

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgGradientStart, bgGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bgGradientEnd.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (message != null && message.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AppToast] Error displaying toast: $e');
    }
  }
}
