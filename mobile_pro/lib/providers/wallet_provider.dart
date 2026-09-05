import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/app_toast.dart';
import '../models/models.dart';
import 'pro_providers.dart';

class WalletState {
  final double balance;
  final bool isLoading;
  final List<WalletTransactionModel> transactions;
  final String? errorMessage;

  const WalletState({
    this.balance = 0.0,
    this.isLoading = false,
    this.transactions = const [],
    this.errorMessage,
  });

  int get availableLeads => (balance / 500).floor();

  WalletState copyWith({
    double? balance,
    bool? isLoading,
    List<WalletTransactionModel>? transactions,
    String? errorMessage,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref);
});

class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;

  WalletNotifier(this._ref) : super(const WalletState()) {
    final user = _ref.read(authProvider);
    if (user != null) {
      fetchWallet();
    }
  }

  Future<void> fetchWallet() async {
    final user = _ref.read(authProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dio = _ref.read(apiClientProvider);

      // 1. Balance
      final balanceRes = await dio.get('/wallet/balance');
      double balance = 0.0;
      if (balanceRes.statusCode == 200 && balanceRes.data != null) {
        balance = (balanceRes.data['balance'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Transactions
      final txRes = await dio.get('/wallet/transactions');
      List<WalletTransactionModel> txList = [];
      if (txRes.statusCode == 200 && txRes.data is List) {
        txList = (txRes.data as List)
            .map((item) => WalletTransactionModel.fromJson(item))
            .toList();
      }

      state = state.copyWith(
        balance: balance,
        transactions: txList,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Wallet] Fetch error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger le portefeuille',
      );
    }
  }

  Future<bool> topUp(double amount, {String provider = 'Wave'}) async {
    if (amount <= 0) return false;
    state = state.copyWith(isLoading: true);

    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post('/wallet/top-up', data: {
        'amount': amount,
      });

      if (res.statusCode == 200) {
        AppToast.show(
          null,
          title: 'Recharge réussie !',
          message:
              '+${amount.toStringAsFixed(0)} FCFA ajoutés via $provider.',
          type: AppToastType.success,
        );
        await fetchWallet();
        return true;
      }
    } catch (e) {
      debugPrint('[Wallet] Top-up error: $e');
      AppToast.show(
        null,
        title: 'Échec de recharge',
        message: 'Une erreur est survenue lors du rechargement.',
        type: AppToastType.error,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  Future<bool> requestRefund(String bookingId, {String? reason}) async {
    state = state.copyWith(isLoading: true);

    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post('/wallet/refund', data: {
        'booking_id': bookingId,
      });

      if (res.statusCode == 200) {
        final remaining = res.data['refunds_remaining'] ?? 0;
        AppToast.show(
          null,
          title: 'Remboursement validé (+500 FCFA)',
          message:
              'Votre wallet a été recrédité. Restants ce mois : $remaining.',
          type: AppToastType.success,
        );
        await fetchWallet();
        return true;
      }
    } catch (e) {
      debugPrint('[Wallet] Refund error: $e');
      String msg = 'Impossible de traiter le remboursement.';
      if (e.toString().contains('limite')) {
        msg = 'Limite mensuelle de 2 remboursements atteinte.';
      }
      AppToast.show(
        null,
        title: 'Remboursement refusé',
        message: msg,
        type: AppToastType.error,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }
}
