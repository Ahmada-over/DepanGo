import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/design_tokens.dart';
import '../core/app_toast.dart';
import '../services/pro_haptic_service.dart';
import '../providers/pro_providers.dart';

class QuoteBuilderScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const QuoteBuilderScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  String _quoteType = 'on_site_quote';
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  List<QuoteItem> _items = [];
  bool _isLoading = false;

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final descCtrl = TextEditingController();
        final qtyCtrl = TextEditingController(text: '1');
        final priceCtrl = TextEditingController();
        String category = 'labor';

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Barre de drag supérieure
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. En-tête
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ajouter une prestation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: AppTouchTarget.min,
                          height: AppTouchTarget.min,
                          child: IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Sélecteur de catégorie en Chips tactiles (50px de hauteur)
                    const Text(
                      'CATÉGORIE',
                      style: TextStyle(
                        color: ProTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryChip(
                            label: 'Main d\'œuvre',
                            icon: LucideIcons.wrench,
                            isSelected: category == 'labor',
                            onTap: () {
                              ProHapticService.instance.onSelectionClick();
                              setSheetState(() => category = 'labor');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCategoryChip(
                            label: 'Matériel / Pièces',
                            icon: LucideIcons.package,
                            isSelected: category == 'material',
                            onTap: () {
                              ProHapticService.instance.onSelectionClick();
                              setSheetState(() => category = 'material');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 4. Description détaillée
                    const Text(
                      'DESCRIPTION DE LA PRESTATION',
                      style: TextStyle(
                        color: ProTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ProTheme.darkSurface,
                        hintText: 'Ex: Remplacement robinet mitigeur...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: ProTheme.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: ProTheme.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: ProTheme.primaryLight, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Quantité et Prix Unitaire
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUANTITÉ',
                                style: TextStyle(
                                  color: ProTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: qtyCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: ProTheme.darkSurface,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.darkBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.darkBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.primaryLight, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRIX UNITAIRE (FCFA)',
                                style: TextStyle(
                                  color: ProTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: ProTheme.darkSurface,
                                  hintText: 'Ex: 10000',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.darkBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.darkBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: ProTheme.primaryLight, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6. Bouton d'ajout pleine largeur 54px
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 20),
                        label: const Text(
                          'AJOUTER CETTE LIGNE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProTheme.primaryLight,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: () {
                          final qty = int.tryParse(qtyCtrl.text) ?? 1;
                          final price = double.tryParse(priceCtrl.text) ?? 0.0;

                          if (descCtrl.text.trim().isEmpty || price <= 0) {
                            AppToast.show(
                              context,
                              title: 'Champs incomplets',
                              message: 'Veuillez saisir une description et un prix supérieur à 0.',
                              type: AppToastType.warning,
                            );
                            return;
                          }

                          ProHapticService.instance.onSliderConfirmed();
                          setState(() {
                            _items.add(QuoteItem(
                              description: descCtrl.text.trim(),
                              category: category,
                              quantity: qty,
                              unitPrice: price,
                              totalPrice: qty * price,
                            ));
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? ProTheme.primaryLight.withValues(alpha: 0.15) : ProTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? ProTheme.primaryLight : const Color(0xFF334155),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? ProTheme.primaryLight : ProTheme.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : ProTheme.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalLabor => _items.where((i) => i.category == 'labor').fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _totalMaterials => _items.where((i) => i.category == 'material').fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _totalTravel => 0.0;
  double get _grandTotal => _totalLabor + _totalMaterials;

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'labor': return LucideIcons.wrench;
      case 'material': return LucideIcons.package;
      default: return LucideIcons.receipt;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'labor': return 'Main d\'œuvre';
      case 'material': return 'Matériel / Pièces';
      default: return cat;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'labor': return const Color(0xFF0284C7);
      case 'material': return const Color(0xFFD97706);
      default: return Colors.grey;
    }
  }

  Future<void> _submitQuote() async {
    if (_items.isEmpty) {
      AppToast.show(
        context,
        title: 'Devis vide',
        message: 'Ajoutez au moins une ligne de prestation avant d\'envoyer le devis.',
        type: AppToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authProvider.notifier).token;
      final quoteService = QuoteService(
        baseUrl: AppConfig.apiBaseUrl,
        token: token ?? '',
      );

      final newQuote = Quote(
        bookingId: widget.bookingId,
        quoteType: _quoteType,
        totalLabor: _totalLabor,
        totalMaterials: _totalMaterials,
        totalTravel: _totalTravel,
        grandTotal: _grandTotal,
        estimatedDuration: _durationController.text.isNotEmpty ? _durationController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _items,
      );

      await quoteService.createQuote(newQuote);

      if (!mounted) return;
      AppToast.show(
        context,
        title: 'Devis envoyé !',
        message: 'Le devis a été transmis au client avec succès.',
        type: AppToastType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[QuoteBuilder] Error submitting quote: $e');
      if (!mounted) return;
      AppToast.show(
        context,
        title: 'Échec de transmission',
        message: 'Impossible de transmettre le devis. Veuillez réessayer.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(
        backgroundColor: ProTheme.darkCard,
        title: const Text('Créer un Devis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Type de devis ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Type de devis', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _quoteType,
                          dropdownColor: ProTheme.darkSurface,
                          items: const [
                            DropdownMenuItem(value: 'on_site_quote', child: Text('📍 Devis sur place', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'remote_estimate', child: Text('📡 Estimation à distance', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _quoteType = val);
                          },
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Durée + Notes ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _durationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '⏱ Durée estimée',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Ex: 2 heures',
                            hintStyle: TextStyle(color: Colors.white30),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '📝 Notes / Conditions',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Ex: Garantie 6 mois sur les pièces',
                            hintStyle: TextStyle(color: Colors.white30),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Lignes de facturation ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lignes de facturation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProTheme.primaryLight,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: ProTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ProTheme.darkBorder, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long, size: 40, color: Colors.white24),
                          SizedBox(height: 8),
                          Text('Aucune ligne ajoutée', style: TextStyle(color: Colors.white38)),
                          Text('Appuyez sur "Ajouter" pour commencer', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),

                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final color = _categoryColor(item.category);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: ProTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(_categoryIcon(item.category), color: color, size: 20),
                        ),
                        title: Text(item.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${_categoryLabel(item.category)} · ${item.quantity} x ${_formatPrice(item.unitPrice)} FCFA',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_formatPrice(item.totalPrice)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeItem(idx),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // --- Récapitulatif Pro ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: const Color(0xFF334155), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RÉCAPITULATIF DU DEVIS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: ProTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Main d\'œuvre',
                          _totalLabor,
                          icon: LucideIcons.wrench,
                          iconColor: const Color(0xFF38BDF8),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Matériel / Pièces',
                          _totalMaterials,
                          icon: LucideIcons.package,
                          iconColor: const Color(0xFFFBBF24),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFF334155), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL CLIENT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${_formatPrice(_grandTotal)} FCFA',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: ProTheme.primaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Bouton soumettre ---
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProTheme.primaryLight,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _items.isEmpty ? null : _submitQuote,
                      icon: const Icon(Icons.send, size: 22),
                      label: const Text('Soumettre le devis au client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: iconColor ?? Colors.white70),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_formatPrice(amount)} FCFA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
