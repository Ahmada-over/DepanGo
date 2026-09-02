import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'theme.dart';
import 'theme.dart';

class CategoryHelper {
  static const Map<String, Map<String, dynamic>> _categories = {
    'cat_plumbing': {
      'name': 'Plomberie & Sanitaire',
      'shortName': 'Plomberie',
      'icon': LucideIcons.droplet,
      'color': AppTheme.primaryEmerald,
      'description':
          'Fuites d\'eau, robinetterie, tuyauterie, débouchage WC et canalisations.',
    },
    'cat_hvac': {
      'name': 'Climatisation & Froid',
      'shortName': 'Froid & Clim',
      'icon': LucideIcons.snowflake,
      'color': AppTheme.primaryEmerald,
      'description':
          'Entretien split, recharge de gaz, panne compresseur, frigos et chambres froides.',
    },
    'cat_electrical': {
      'name': 'Électricité Générale',
      'shortName': 'Électricité',
      'icon': LucideIcons.zap,
      'color': AppTheme.primaryEmerald,
      'description':
          'Court-circuit, disjoncteur qui saute, tableau électrique, câblage et prises.',
    },
    'cat_appliances': {
      'name': 'Électroménager',
      'shortName': 'Électroménager',
      'icon': LucideIcons.refrigerator,
      'color': AppTheme.primaryEmerald,
      'description':
          'Lave-linge, lave-vaisselle, micro-ondes, cuisinière et petits appareils.',
    },
    'cat_express': {
      'name': 'Dépannage d\'Urgence',
      'shortName': 'Urgence Express',
      'icon': LucideIcons.zap,
      'color': AppTheme.primaryEmerald,
      'description':
          'Intervention prioritaire immédiate pour dépannage express à Dakar.',
    },
  };

  static String getCategoryName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Dépannage Général';
    return _categories[categoryId]?['name'] ??
        categoryId.replaceFirst('cat_', '').toUpperCase();
  }

  static String getShortName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Dépannage';
    return _categories[categoryId]?['shortName'] ??
        categoryId.replaceFirst('cat_', '').toUpperCase();
  }

  static IconData getCategoryIcon(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return LucideIcons.wrench;
    return _categories[categoryId]?['icon'] ?? LucideIcons.wrench;
  }

  static Color getCategoryColor(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return AppTheme.primaryEmerald;
    }
    return _categories[categoryId]?['color'] ?? AppTheme.primaryEmerald;
  }

  static String getCategoryDescription(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return 'Intervention technique de dépannage.';
    }
    return _categories[categoryId]?['description'] ??
        'Intervention technique de dépannage.';
  }

  static List<Map<String, dynamic>> getAllCategories() {
    return _categories.entries.map((e) => {'id': e.key, ...e.value}).toList();
  }
}
