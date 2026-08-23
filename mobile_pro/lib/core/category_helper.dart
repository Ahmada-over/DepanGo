import 'package:flutter/material.dart';

class CategoryHelper {
  static const Map<String, Map<String, dynamic>> _categories = {
    'cat_plumbing': {
      'name': 'Plomberie & Sanitaire',
      'shortName': 'Plomberie',
      'icon': Icons.water_drop_rounded,
      'emoji': '',
      'color': Color(0xFF0F766E),
      'description': 'Fuites d\'eau, robinetterie, tuyauterie, débouchage WC et canalisations.',
    },
    'cat_hvac': {
      'name': 'Climatisation & Froid',
      'shortName': 'Froid & Clim',
      'icon': Icons.ac_unit_rounded,
      'emoji': '️',
      'color': Color(0xFF0284C7),
      'description': 'Entretien split, recharge de gaz, panne compresseur, frigos et chambres froides.',
    },
    'cat_electrical': {
      'name': 'Électricité Générale',
      'shortName': 'Électricité',
      'icon': Icons.bolt_rounded,
      'emoji': '',
      'color': Color(0xFFD97706),
      'description': 'Court-circuit, disjoncteur qui saute, tableau électrique, câblage et prises.',
    },
    'cat_appliances': {
      'name': 'Électroménager',
      'shortName': 'Électroménager',
      'icon': Icons.kitchen_rounded,
      'emoji': '',
      'color': Color(0xFF7C3AED),
      'description': 'Lave-linge, lave-vaisselle, micro-ondes, cuisinière et petits appareils.',
    },
    'cat_express': {
      'name': 'Dépannage d\'Urgence',
      'shortName': 'Urgence Express',
      'icon': Icons.flash_on_rounded,
      'emoji': '',
      'color': Color(0xFFDC2626),
      'description': 'Intervention prioritaire immédiate pour dépannage express à Dakar.',
    },
  };

  static String getCategoryName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Dépannage Général';
    return _categories[categoryId]?['name'] ?? categoryId.replaceFirst('cat_', '').toUpperCase();
  }

  static String getShortName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Dépannage';
    return _categories[categoryId]?['shortName'] ?? categoryId.replaceFirst('cat_', '').toUpperCase();
  }

  static IconData getCategoryIcon(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return Icons.build_rounded;
    return _categories[categoryId]?['icon'] ?? Icons.build_rounded;
  }

  static String getCategoryEmoji(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return '️';
    return _categories[categoryId]?['emoji'] ?? '️';
  }

  static Color getCategoryColor(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return const Color(0xFF0F766E);
    return _categories[categoryId]?['color'] ?? const Color(0xFF0F766E);
  }

  static String getCategoryDescription(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Intervention technique de dépannage.';
    return _categories[categoryId]?['description'] ?? 'Intervention technique de dépannage.';
  }

  static List<Map<String, dynamic>> getAllCategories() {
    return _categories.entries.map((e) => {'id': e.key, ...e.value}).toList();
  }
}
