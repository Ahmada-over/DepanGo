import 'package:flutter/material.dart';

/// Design tokens officiels pour l'application TekService Client.
/// Garantit la cohérence ergonomique et visuelle selon les standards 2026.
class AppRadius {
  AppRadius._();
  static const double none = 0.0;
  static const double sm = 8.0;      // Badges, chips, tags
  static const double md = 12.0;     // Cartes d'items, inputs, alertes
  static const double lg = 16.0;     // Cartes principales, modales compacts
  static const double xl = 24.0;     // Bottom sheets, grandes cartes
  static const double pill = 999.0;  // Boutons CTA, Floating Dock, sliders
}

class AppTouchTarget {
  AppTouchTarget._();
  static const double min = 48.0;       // Minimum légal d'accessibilité (WCAG 2.1)
  static const double standard = 52.0;  // Standard de confort tactile
  static const double prominent = 60.0; // Sliders critiques, Floating Dock
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration smooth = Duration(milliseconds: 380);
  static const Curve spring = Curves.easeOutBack;
  static const Curve fluid = Curves.easeInOutCubic;
}
