import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/design_tokens.dart';
import '../core/app_toast.dart';
import '../providers/app_providers.dart';
import '../widgets/slide_to_confirm.dart';
import '../services/client_haptic_service.dart';

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
    if (status == 'accepted') {
      ClientHapticService.instance.onConfirmed();
    } else {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.triangle_alert,
                        color: Colors.redAccent, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Refuser ce devis ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si vous refusez ce devis, l\'artisan sera immédiatement notifié et l\'intervention ne pourra pas débuter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppTouchTarget.standard,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: AppTouchTarget.standard,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: const Text(
                            'Confirmer le refus',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isActioning = true);

    try {
      final token = ref.read(authProvider.notifier).token;
      final service = QuoteService(
        baseUrl: AppConfig.apiBaseUrl,
        token: token ?? '',
      );
      await service.updateQuoteStatus(quote.id, status);

      if (!mounted) return;
      AppToast.show(
        context,
        title: status == 'accepted' ? 'Devis accepté !' : 'Devis refusé',
        message: status == 'accepted'
            ? 'Les travaux peuvent commencer.'
            : 'Le professionnel en a été informé.',
        type: status == 'accepted' ? AppToastType.success : AppToastType.warning,
      );
      Navigator.pop(context, status);
    } catch (e) {
      debugPrint('[QuoteReview] Error responding to quote: $e');
      if (!mounted) return;
      AppToast.show(
        context,
        title: 'Échec de transmission',
        message: 'Impossible de mettre à jour le statut du devis.',
        type: AppToastType.error,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSoberTotalRow(
                  icon: LucideIcons.wrench,
                  label: 'Main d\'œuvre',
                  amount: quote.totalLabor,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 8),
                _buildSoberTotalRow(
                  icon: LucideIcons.package,
                  label: 'Matériel / Pièces',
                  amount: quote.totalMaterials,
                  color: const Color(0xFFD97706),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${_formatPrice(quote.grandTotal)} FCFA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryEmerald,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Déplacement inclus • Règlement direct après validation des travaux',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
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

          // --- Accept / Reject actions ---
          if (isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  SlideToConfirm(
                    label: "GLISSER POUR ACCEPTER LE DEVIS",
                    sublabel: "TOTAL : ${_formatPrice(quote.grandTotal)} FCFA",
                    activeColor: AppTheme.primaryEmerald,
                    icon: LucideIcons.circle_check,
                    onConfirmed: () => _respondToQuote(quote, 'accepted'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: AppTouchTarget.min,
                    child: TextButton.icon(
                      onPressed: _isActioning ? null : () => _respondToQuote(quote, 'rejected'),
                      icon: const Icon(LucideIcons.x, size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Refuser ce devis',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildSoberTotalRow({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const Spacer(),
        Text(
          '${_formatPrice(amount)} FCFA',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
