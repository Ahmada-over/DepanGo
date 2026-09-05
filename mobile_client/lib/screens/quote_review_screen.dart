import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class QuoteReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const QuoteReviewScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  ConsumerState<QuoteReviewScreen> createState() => _QuoteReviewScreenState();
}

class _QuoteReviewScreenState extends ConsumerState<QuoteReviewScreen> {
  List<Quote>? _quotes;
  bool _isLoading = true;
  bool _isActioning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = ref.read(authProvider.notifier).token;
      final service = QuoteService(
        baseUrl: AppConfig.apiBaseUrl,
        token: token ?? '',
      );
      final quotes = await service.getQuotesForBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToQuote(Quote quote, String status) async {
    final action = status == 'accepted' ? 'accepter' : 'refuser';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${status == 'accepted' ? 'Accepter' : 'Refuser'} le devis ?'),
        content: Text(
          status == 'accepted'
              ? 'Vous acceptez ce devis de ${_formatPrice(quote.grandTotal)} FCFA. Le professionnel pourra commencer les travaux.'
              : 'Vous refusez ce devis. Le professionnel en sera informé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'accepted' ? AppTheme.primaryEmerald : Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'accepted' ? 'Accepter' : 'Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActioning = true);

    try {
      final token = ref.read(authProvider.notifier).token;
      final service = QuoteService(
        baseUrl: AppConfig.apiBaseUrl,
        token: token ?? '',
      );
      await service.updateQuoteStatus(quote.id, status);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'accepted'
              ? '✅ Devis accepté ! Les travaux peuvent commencer.'
              : '❌ Devis refusé.'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.redAccent,
        ),
      );
      Navigator.pop(context, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'labor':
        return LucideIcons.wrench;
      case 'material':
        return LucideIcons.package;
      case 'travel':
        return LucideIcons.car;
      default:
        return LucideIcons.receipt;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'labor':
        return 'Main d\'œuvre';
      case 'material':
        return 'Matériel';
      case 'travel':
        return 'Déplacement';
      default:
        return cat;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'labor':
        return Colors.blue;
      case 'material':
        return Colors.orange;
      case 'travel':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Devis reçu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.triangle_alert, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text('Erreur de chargement', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadQuotes, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _quotes == null || _quotes!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.file_text, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aucun devis pour le moment', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Le professionnel n\'a pas encore envoyé de devis.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _quotes!.length,
                      itemBuilder: (ctx, idx) => _buildQuoteCard(_quotes![idx]),
                    ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final isPending = quote.status == 'draft' || quote.status == 'pending_client_approval';
    final isAccepted = quote.status == 'accepted';
    final isRejected = quote.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
        border: isAccepted
            ? Border.all(color: AppTheme.primaryEmerald, width: 2)
            : isRejected
                ? Border.all(color: Colors.redAccent, width: 2)
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAccepted
                  ? AppTheme.primaryEmerald.withValues(alpha: 0.08)
                  : isRejected
                      ? Colors.red.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  quote.quoteType == 'on_site_quote' ? LucideIcons.map_pin : LucideIcons.send,
                  color: AppTheme.primaryEmerald,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote.quoteTypeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                        : isRejected
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quote.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAccepted
                          ? AppTheme.primaryEmerald
                          : isRejected
                              ? Colors.redAccent
                              : Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Items ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: quote.items.map((item) {
                final color = _categoryColor(item.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_categoryIcon(item.category), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Text(
                              '${_categoryLabel(item.category)} · ${item.quantity} x ${_formatPrice(item.unitPrice)} FCFA',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatPrice(item.totalPrice)} F',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // --- Totals ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildTotalRow('🔧 Main d\'œuvre', quote.totalLabor),
                _buildTotalRow('📦 Matériel', quote.totalMaterials),
                _buildTotalRow('🚗 Déplacement', quote.totalTravel),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(
                      '${_formatPrice(quote.grandTotal)} FCFA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Duration & Notes ---
          if (quote.estimatedDuration != null || quote.notes != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quote.estimatedDuration != null)
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Durée estimée : ${quote.estimatedDuration}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  if (quote.notes != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.message_square, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(quote.notes!, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // --- Accept / Reject buttons ---
          if (isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isActioning ? null : () => _respondToQuote(quote, 'rejected'),
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isActioning ? null : () => _respondToQuote(quote, 'accepted'),
                      icon: _isActioning
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.check, size: 18),
                      label: Text(_isActioning ? 'Envoi...' : 'Accepter le devis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isAccepted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.circle_check, color: AppTheme.primaryEmerald, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Devis accepté — Travaux en cours',
                      style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text('${_formatPrice(amount)} FCFA', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
