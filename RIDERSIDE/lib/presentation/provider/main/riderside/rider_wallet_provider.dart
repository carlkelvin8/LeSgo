import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/lespay_topup_fee.dart';
import '../../../../core/utils/rider_wallet_policy.dart';
import '../../../../core/utils/wallet_response_parser.dart';

class RiderTopUpCheckout {
  final String invoiceId;
  final String invoiceUrl;
  final double walletAmount;
  final double feeAmount;
  final double totalCharge;

  const RiderTopUpCheckout({
    required this.invoiceId,
    required this.invoiceUrl,
    required this.walletAmount,
    required this.feeAmount,
    required this.totalCharge,
  });
}

class RiderWalletState {
  final double balance;
  final double deposit;
  final bool isLoading;
  final bool isProcessingTopUp;
  final String? error;
  final List<Map<String, dynamic>> linkedAccounts;

  const RiderWalletState({
    this.balance = 0.0,
    this.deposit = 0.0,
    this.isLoading = false,
    this.isProcessingTopUp = false,
    this.error,
    this.linkedAccounts = const [],
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';
  String get depositFormatted => 'PHP ${deposit.toStringAsFixed(2)}';

  bool get canAcceptBooking => RiderWalletPolicy.canAcceptBooking(balance);

  bool get showLowBalanceWarning =>
      RiderWalletPolicy.shouldShowTopUpWarning(balance);

  String get acceptBlockedMessage =>
      RiderWalletPolicy.acceptBlockedMessage(balance);

  String get lowBalanceWarningMessage =>
      RiderWalletPolicy.lowBalanceWarningMessage(balance);

  bool isProviderLinked(String provider) {
    return _findLinkedAccount(provider) != null;
  }

  String? linkedAccountSubtitle(String provider) {
    final account = _findLinkedAccount(provider);
    if (account == null) return 'Not linked — tap to add';
    final meta = WalletResponseParser.parseMeta(account['meta']);
    final number = meta['account_number']?.toString();
    final last4 = account['account_last4']?.toString();
    if (number != null && number.length >= 4) {
      return 'Linked •••• ${number.substring(number.length - 4)}';
    }
    if (last4 != null && last4.isNotEmpty) {
      return 'Linked •••• $last4';
    }
    return 'Linked';
  }

  Map<String, dynamic>? _findLinkedAccount(String provider) {
    for (final account in linkedAccounts) {
      if (account['provider']?.toString() == provider) {
        final meta = WalletResponseParser.parseMeta(account['meta']);
        final hasNumber = meta['account_number']?.toString().isNotEmpty == true;
        final hasLast4 = account['account_last4']?.toString().isNotEmpty == true;
        if (hasNumber || hasLast4 || account['is_verified'] == true) {
          return account;
        }
      }
    }
    return null;
  }

  RiderWalletState copyWith({
    double? balance,
    double? deposit,
    bool? isLoading,
    bool? isProcessingTopUp,
    String? error,
    List<Map<String, dynamic>>? linkedAccounts,
    bool clearError = false,
  }) {
    return RiderWalletState(
      balance: balance ?? this.balance,
      deposit: deposit ?? this.deposit,
      isLoading: isLoading ?? this.isLoading,
      isProcessingTopUp: isProcessingTopUp ?? this.isProcessingTopUp,
      error: clearError ? null : (error ?? this.error),
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
    );
  }
}

class RiderWalletNotifier extends StateNotifier<RiderWalletState> {
  RiderWalletNotifier() : super(const RiderWalletState()) {
    loadWallet();
  }

  Future<void> loadWallet({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final data = await ApiService.dio.get('/v1/wallets/my/wallet');
      final wallet = (data.data['data'] ?? data.data) as Map<String, dynamic>;

      final balance = _d(wallet['balance']);
      final deposit = await _loadTotalDeposits();
      final linked = await getLinkedAccounts();

      state = state.copyWith(
        balance: balance,
        deposit: deposit,
        linkedAccounts: linked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<String> _transactionsPath() async {
    final userId = await SecureStorageService.getUserId();
    if (userId != null) {
      return '/v1/wallets/$userId/transactions';
    }

    try {
      final me = await ApiService.getMe();
      final data = me['data'] ?? me['user'] ?? me;
      if (data is Map && data['id'] != null) {
        return '/v1/wallets/${data['id']}/transactions';
      }
    } catch (e) {
      debugPrint('Could not resolve user id for transactions: $e');
    }

    return '/v1/wallets/my/transactions';
  }

  Future<double> _loadTotalDeposits() async {
    try {
      final path = await _transactionsPath();
      final response = await ApiService.dio.get(path);
      final txList = WalletResponseParser.parseListBody(response.data);
      return WalletResponseParser.computeTotalDeposits(txList);
    } catch (e) {
      debugPrint('Deposit total load failed: $e');
      return state.deposit;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final result = await fetchTransactionHistory();
    return result.items;
  }

  /// Loads history without polluting wallet balance error state.
  Future<({List<Map<String, dynamic>> items, String? error})>
      fetchTransactionHistory() async {
    try {
      final path = await _transactionsPath();
      final response = await ApiService.dio.get(path);
      final items = WalletResponseParser.parseListBody(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return (items: items, error: null);
    } catch (e) {
      return (
        items: <Map<String, dynamic>>[],
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load LesPay history. Pull to retry.',
          fallbackTl: 'Hindi ma-load ang history. Subukan muli.',
        ),
      );
    }
  }

  Future<RiderTopUpCheckout?> startTopUp(double walletAmount) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);

    try {
      final pricing = LespayTopupFee.calculate(walletAmount);
      final checkout = await _createTopUpCheckout(pricing);
      if (checkout == null) {
        state = state.copyWith(
          isProcessingTopUp: false,
          error: 'Could not create payment link. Please try again.',
        );
        return null;
      }

      state = state.copyWith(isProcessingTopUp: false);
      return checkout;
    } catch (e, stack) {
      debugPrint('Rider top-up error: $e\n$stack');
      state = state.copyWith(
        isProcessingTopUp: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn:
              'Top-up is unavailable right now. Please try again shortly.',
          fallbackTl:
              'Hindi available ang top-up ngayon. Subukan muli maya-maya.',
        ),
      );
      return null;
    }
  }

  Future<RiderTopUpCheckout?> _createTopUpCheckout(LespayTopupFee pricing) async {
    final description =
        'LesPay Top-up PHP ${pricing.walletAmount.toStringAsFixed(2)} '
        '+ 1.5% fee (PHP ${pricing.feeAmount.toStringAsFixed(2)})';

    try {
      final response = await ApiService.dio.post(
        '/v1/wallets/my/topup',
        data: {
          'amount': pricing.walletAmount,
          'payment_method': 'paymongo',
        },
      );
      final checkout = _checkoutFromResponse(response.data, pricing);
      if (checkout != null) return checkout;
    } catch (e) {
      debugPrint('Wallet API top-up failed, trying gateway: $e');
    }

    try {
      final response = await ApiService.dio.post(
        '/v1/payment-gateway/invoices',
        data: {
          'amount': pricing.walletAmount,
          'description': description,
          'payment_method': 'paymongo',
          'metadata': {
            'wallet_amount': pricing.walletAmount,
            'fee_amount': pricing.feeAmount,
            'purpose': 'lespay_topup',
          },
        },
      );
      return _checkoutFromResponse(response.data, pricing);
    } catch (e) {
      if (e is DioException) rethrow;
      throw Exception(e.toString());
    }
  }

  RiderTopUpCheckout? _checkoutFromResponse(
    dynamic raw,
    LespayTopupFee pricing,
  ) {
    final invoice = WalletResponseParser.extractInvoiceMap(raw);
    if (invoice == null) return null;

    final invoiceId = invoice['invoice_id']?.toString() ?? invoice['id']?.toString();
    final invoiceUrl = invoice['invoice_url']?.toString();

    if (invoiceId == null ||
        invoiceId.isEmpty ||
        invoiceUrl == null ||
        invoiceUrl.isEmpty) {
      return null;
    }

    return RiderTopUpCheckout(
      invoiceId: invoiceId,
      invoiceUrl: invoiceUrl,
      walletAmount: pricing.walletAmount,
      feeAmount: pricing.feeAmount,
      totalCharge: pricing.totalCharge,
    );
  }

  Future<bool> completeTopUp(RiderTopUpCheckout checkout) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);

    try {
      await _confirmTopUpOnServer(checkout);
      await loadWallet();
      state = state.copyWith(isProcessingTopUp: false);
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 409) {
        final paid = await _pollGatewayInvoicePaid(checkout.invoiceId);
        if (paid) {
          try {
            await _confirmTopUpOnServer(checkout);
            await loadWallet();
            state = state.copyWith(isProcessingTopUp: false);
            return true;
          } catch (retryErr) {
            debugPrint('Top-up confirm retry failed: $retryErr');
          }
        }
      }

      final message = ApiService.extractError(e);
      state = state.copyWith(
        isProcessingTopUp: false,
        error: message.contains('not completed')
            ? message
            : '$message If you already paid, wait a moment and tap again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isProcessingTopUp: false,
        error: ApiErrorMapper.message(e),
      );
      return false;
    }
  }

  Future<void> _confirmTopUpOnServer(RiderTopUpCheckout checkout) async {
    final response = await ApiService.dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': checkout.walletAmount,
          'payment_method': 'paymongo',
          'gateway_reference': checkout.invoiceId,
      },
    );
    
    // Verify response contains success confirmation
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('TopUp confirmation failed: No response data');
    }
    
    // Check for success flag
    final success = data['success'] as bool?;
    if (success == false) {
      final message = data['message'] as String? ?? 'TopUp confirmation failed';
      throw Exception(message);
    }
  }

  Future<bool> _pollGatewayInvoicePaid(String invoiceId) async {
    try {
      final response =
          await ApiService.dio.get('/v1/payment-gateway/invoices/$invoiceId');
      final payload = response.data;
      if (payload is! Map) return false;

      final data = payload['data'];
      final status = (data is Map ? data['status'] : null)?.toString();
      return WalletResponseParser.isInvoicePaidStatus(status);
    } catch (e) {
      debugPrint('Gateway invoice poll failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    try {
      final response = await ApiService.dio.get('/v1/wallets/my/linked-accounts');
      return WalletResponseParser.parseListBody(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> linkAccount({
    required String provider,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      await ApiService.dio.post('/v1/wallets/my/linked-accounts', data: {
        'provider': provider,
        'account_number':
            WalletResponseParser.normalizePhilippineMobile(accountNumber),
        'account_holder_name': accountHolderName.trim(),
      });
      final linked = await getLinkedAccounts();
      state = state.copyWith(linkedAccounts: linked, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> unlinkAccount(String provider) async {
    state = state.copyWith(clearError: true);
    try {
      await ApiService.dio.delete('/v1/wallets/my/linked-accounts/$provider');
      final linked = await getLinkedAccounts();
      state = state.copyWith(linkedAccounts: linked, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> withdraw(double amount, String method) async {
    state = state.copyWith(clearError: true);
    try {
      final response = await ApiService.dio.post('/v1/wallets/my/withdraw', data: {
        'amount': amount,
        'withdrawal_method': method,
      });
      final raw = response.data;
      if (raw is! Map) {
        await loadWallet();
        return true;
      }
      final body = Map<String, dynamic>.from(raw);
      final data = body['data'];
      final walletData = data is Map ? (data['wallet'] ?? data) : null;
      if (walletData is Map) {
        final walletMap = Map<String, dynamic>.from(walletData);
        state = state.copyWith(
          balance: _d(walletMap['balance']),
          clearError: true,
        );
      } else {
        await loadWallet();
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

final riderWalletProvider =
    StateNotifierProvider<RiderWalletNotifier, RiderWalletState>(
      (ref) => RiderWalletNotifier(),
    );
