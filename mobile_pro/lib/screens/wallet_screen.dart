import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    // Refresh wallet on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWallet();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      appBar: AppBar(
        backgroundColor: ProTheme.darkBg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: ProTheme.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Portefeuille Pro',
          style: TextStyle(
            color: ProTheme.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: walletState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProTheme.primaryLight,
                    ),
                  )
                : const Icon(LucideIcons.rotate_cw,
                    size: 20, color: ProTheme.textMuted),
            onPressed: walletState.isLoading
                ? null
                : () => ref.read(walletProvider.notifier).fetchWallet(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: ProTheme.primaryLight,
          backgroundColor: ProTheme.darkCard,
          onRefresh: () => ref.read(walletProvider.notifier).fetchWallet(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Balance Hero Card
                _buildHeroBalanceCard(walletState),
                const SizedBox(height: 24),

                // 2. Quick Actions
                _buildActionButtons(context),
                const SizedBox(height: 28),

                // 3. Information Rule Card
                _buildRuleInfoCard(),
                const SizedBox(height: 28),

                // 4. Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historique des opérations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ProTheme.textWhite,
                      ),
                    ),
                    Text(
                      '${walletState.transactions.length} opération(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ProTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Transactions List
                if (walletState.transactions.isEmpty && !walletState.isLoading)
                  _buildEmptyTransactions()
                else
                  _buildTransactionList(walletState.transactions),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBalanceCard(WalletState wallet) {
    final balanceFormatted =
        wallet.balance.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]} ',
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Emerald Teal
            Color(0xFF134E4A), // Deep Emerald
            Color(0xFF0D9488), // Teal accent
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.wallet, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Solde disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: wallet.balance >= 500
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : Colors.redAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: wallet.balance >= 500
                        ? const Color(0xFF10B981)
                        : Colors.redAccent,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  wallet.balance >= 500 ? 'Actif' : 'Recharge requise',
                  style: TextStyle(
                    color: wallet.balance >= 500
                        ? const Color(0xFFA7F3D0)
                        : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$balanceFormatted FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.zap, color: Color(0xFFFDE047), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${wallet.availableLeads} mission(s) disponible(s) • 500 F / contact',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showTopUpBottomSheet(context),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Recharger le wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProTheme.primaryLight,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProTheme.darkBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: ProTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'Modèle Transparent DepanGo',
                style: TextStyle(
                  color: ProTheme.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.phone_in_talk_rounded,
            '500 FCFA déduits uniquement lorsque vous acceptez un client.',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.payments_rounded,
            'Vous encaissez 100% du montant de votre prestation en direct.',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.support_agent_rounded,
            'Garantie contact : 2 remboursements automatiques / mois si client injoignable.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ProTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: ProTheme.textMuted,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ProTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProTheme.darkBorder, width: 0.8),
      ),
      child: const Column(
        children: [
          Icon(LucideIcons.receipt, size: 40, color: ProTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'Aucune transaction enregistrée',
            style: TextStyle(
              color: ProTheme.textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Vos recharges et achats de missions apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ProTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<WalletTransactionModel> transactions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.type == 'credit';

        String title;
        IconData icon;
        Color color;

        switch (tx.reason) {
          case 'welcome_bonus':
            title = 'Bonus de bienvenue';
            icon = Icons.card_giftcard_rounded;
            color = const Color(0xFF10B981);
            break;
          case 'lead_purchase':
            title = 'Mission acceptée';
            icon = Icons.person_pin_rounded;
            color = const Color(0xFFF59E0B);
            break;
          case 'refund':
            title = 'Remboursement litige';
            icon = Icons.replay_rounded;
            color = const Color(0xFF38BDF8);
            break;
          case 'top_up':
            title = 'Recharge Mobile Money';
            icon = Icons.account_balance_wallet_rounded;
            color = const Color(0xFF10B981);
            break;
          default:
            title = isCredit ? 'Crédit' : 'Débit';
            icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
            color = isCredit ? const Color(0xFF10B981) : Colors.redAccent;
        }

        final amountFormatted = tx.amount.toStringAsFixed(0);
        final dateStr = tx.createdAt != null
            ? '${tx.createdAt!.day.toString().padLeft(2, '0')}/${tx.createdAt!.month.toString().padLeft(2, '0')} à ${tx.createdAt!.hour.toString().padLeft(2, '0')}:${tx.createdAt!.minute.toString().padLeft(2, '0')}'
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ProTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProTheme.darkBorder, width: 0.6),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ProTheme.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: ProTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : '-'}$amountFormatted FCFA',
                style: TextStyle(
                  color: isCredit ? const Color(0xFF10B981) : const Color(0xFFF87171),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTopUpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _TopUpSheet(
        onConfirm: (amount, provider) async {
          Navigator.of(ctx).pop();
          await ref
              .read(walletProvider.notifier)
              .topUp(amount, provider: provider);
        },
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  final Function(double amount, String provider) onConfirm;

  const _TopUpSheet({required this.onConfirm});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  double _selectedAmount = 2000;
  String _selectedProvider = 'Wave';
  final TextEditingController _customAmountController = TextEditingController();
  bool _isCustom = false;

  final List<double> _presets = [2000, 3000, 5000, 10000];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: ProTheme.darkBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recharger mon portefeuille',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisissez un montant pour recevoir de nouvelles demandes.',
            style: TextStyle(
              fontSize: 13,
              color: ProTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Presets
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((amount) {
              final isSelected = !_isCustom && _selectedAmount == amount;
              final missionsCount = (amount / 500).floor();
              return InkWell(
                onTap: () {
                  setState(() {
                    _isCustom = false;
                    _selectedAmount = amount;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ProTheme.primaryLight.withValues(alpha: 0.18)
                        : ProTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? ProTheme.primaryLight
                          : ProTheme.darkBorder,
                      width: isSelected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${amount.toStringAsFixed(0)} F',
                        style: TextStyle(
                          color: isSelected
                              ? ProTheme.primaryLight
                              : ProTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$missionsCount missions',
                        style: TextStyle(
                          color: isSelected
                              ? ProTheme.primaryLight.withValues(alpha: 0.8)
                              : ProTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // Provider Choice
          const Text(
            'Moyen de paiement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildProviderCard('Wave', LucideIcons.smartphone,
                  const Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              _buildProviderCard('Orange Money', LucideIcons.zap,
                  const Color(0xFFEA580C)),
            ],
          ),
          const SizedBox(height: 26),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final amount = _isCustom
                    ? (double.tryParse(_customAmountController.text) ?? 0)
                    : _selectedAmount;
                if (amount > 0) {
                  widget.onConfirm(amount, _selectedProvider);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProTheme.primaryLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirmer la recharge (${_isCustom ? _customAmountController.text : _selectedAmount.toStringAsFixed(0)} FCFA)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(String name, IconData icon, Color brandColor) {
    final isSelected = _selectedProvider == name;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedProvider = name),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? brandColor.withValues(alpha: 0.2)
                : ProTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? brandColor : ProTheme.darkBorder,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? brandColor : ProTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : ProTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
