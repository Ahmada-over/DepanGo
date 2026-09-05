import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/technician_providers.dart';
import '../providers/app_providers.dart';
import '../core/theme.dart';
import 'technician_profile_screen.dart';

class TechniciansSearchScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const TechniciansSearchScreen({super.key, this.initialCategory});

  @override
  ConsumerState<TechniciansSearchScreen> createState() =>
      _TechniciansSearchScreenState();
}

class _TechniciansSearchScreenState
    extends ConsumerState<TechniciansSearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
        ref.read(selectedCategoryFilterProvider.notifier).state =
            widget.initialCategory;
      } else {
        ref.read(selectedCategoryFilterProvider.notifier).state = null;
      }
      ref.read(selectedRatingFilterProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTechs = ref.watch(filteredTechniciansProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final selectedRating = ref.watch(selectedRatingFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        title: const Text('Rechercher',
            style: TextStyle(
                color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrer par catégorie',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c.name),
                                  selected: selectedCat == c.id,
                                  onSelected: (val) {
                                    ref
                                        .read(selectedCategoryFilterProvider
                                            .notifier)
                                        .state = val ? c.id : null;
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                const Text('Note minimale',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
                Row(
                  children: [3.0, 4.0, 4.5, 5.0]
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(r.toString()),
                                  const Icon(LucideIcons.star,
                                      size: 14, color: Colors.amber),
                                ],
                              ),
                              selected: selectedRating == r,
                              onSelected: (val) {
                                ref
                                    .read(selectedRatingFilterProvider.notifier)
                                    .state = val ? r : null;
                              },
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTechs.isEmpty
                ? const Center(
                    child: Text('Aucun technicien trouvé.',
                        style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTechs.length,
                    itemBuilder: (context, index) {
                      final tech = filteredTechs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryEmerald,
                            child: Text(
                                tech.userName.isNotEmpty
                                    ? tech.userName[0].toUpperCase()
                                    : 'T',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ),
                          title: Text(tech.userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(tech.averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Icon(
                                      tech.transportMode == 'voiture'
                                          ? LucideIcons.car
                                          : LucideIcons.bike,
                                      size: 16,
                                      color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(LucideIcons.chevron_right,
                              color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => TechnicianProfileScreen(
                                        technician: tech)));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
