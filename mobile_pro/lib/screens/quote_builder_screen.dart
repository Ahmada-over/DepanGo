import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../core/config.dart';
import '../core/theme.dart';
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
    showDialog(
      context: context,
      builder: (ctx) {
        final descCtrl = TextEditingController();
        final qtyCtrl = TextEditingController(text: '1');
        final priceCtrl = TextEditingController();
        String category = 'labor';

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: ProTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text('Ajouter une ligne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: ProTheme.darkSurface,
                    items: const [
                      DropdownMenuItem(value: 'labor', child: Text('🔧 Main d\'œuvre', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'material', child: Text('📦 Matériel', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'travel', child: Text('🚗 Déplacement', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                    decoration: const InputDecoration(labelText: 'Catégorie', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Ex: Remplacement tuyau PVC',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Qté', labelStyle: TextStyle(color: Colors.white70)),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Prix Unitaire (FCFA)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ProTheme.primaryLight),
                onPressed: () {
                  final qty = int.tryParse(qtyCtrl.text) ?? 1;
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;

                  if (descCtrl.text.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Remplissez la description et le prix')),
                    );
                    return;
                  }

                  setState(() {
                    _items.add(QuoteItem(
                      description: descCtrl.text,
                      category: category,
                      quantity: qty,
                      unitPrice: price,
                      totalPrice: qty * price,
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalLabor => _items.where((i) => i.category == 'labor').fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _totalMaterials => _items.where((i) => i.category == 'material').fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _totalTravel => _items.where((i) => i.category == 'travel').fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _grandTotal => _totalLabor + _totalMaterials + _totalTravel;

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'labor': return Icons.build;
      case 'material': return Icons.inventory_2;
      case 'travel': return Icons.directions_car;
      default: return Icons.receipt;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'labor': return 'Main d\'œuvre';
      case 'material': return 'Matériel';
      case 'travel': return 'Déplacement';
      default: return cat;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'labor': return Colors.blue;
      case 'material': return Colors.orange;
      case 'travel': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _submitQuote() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une ligne au devis')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Devis envoyé au client avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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

                  // --- Récapitulatif ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ProTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('🔧 Main d\'œuvre', _totalLabor),
                        _buildSummaryRow('📦 Matériel', _totalMaterials),
                        _buildSummaryRow('🚗 Déplacement', _totalTravel),
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(
                              '${_formatPrice(_grandTotal)} FCFA',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ProTheme.primaryLight),
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

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('${_formatPrice(amount)} FCFA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
