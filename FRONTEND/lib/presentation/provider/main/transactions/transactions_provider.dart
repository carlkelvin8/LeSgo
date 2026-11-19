import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/constants/order_status_constants.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/payment_status_utils.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../data/data_source/dto/wallet/wallet_dto.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/wallet_remote_datasource.dart';
import '../../../../domain/entities/transactions/transaction.dart';

/// `all` | `order` | `wallet`
typedef TransactionKindFilter = String?;

/// `paid` | `pending` | `failed` | `refunded`
typedef PaymentStatusFilter = String?;

class TransactionsState {
  final List<Transaction> transactions;
  final List<Transaction> filteredTransactions;
  final bool isLoading;
  final String? error;

  /// True when only one of the orders / wallet sources failed to load.
  final bool partialLoadFailed;
  final String? selectedService;
  final String? selectedStatus;
  final TransactionKindFilter selectedKind;
  final PaymentStatusFilter selectedPaymentStatus;
  final String searchQuery;

  TransactionsState({
    required this.transactions,
    required this.filteredTransactions,
    this.isLoading = false,
    this.error,
    this.partialLoadFailed = false,
    this.selectedService,
    this.selectedStatus,
    this.selectedKind,
    this.selectedPaymentStatus,
    this.searchQuery = '',
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    List<Transaction>? filteredTransactions,
    bool? isLoading,
    String? error,
    bool? partialLoadFailed,
    String? selectedService,
    String? selectedStatus,
    TransactionKindFilter? selectedKind,
    PaymentStatusFilter? selectedPaymentStatus,
    String? searchQuery,
    bool clearService = false,
    bool clearStatus = false,
    bool clearKind = false,
    bool clearPaymentStatus = false,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
      partialLoadFailed: partialLoadFailed ?? this.partialLoadFailed,
      selectedService: clearService
          ? null
          : (selectedService ?? this.selectedService),
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedKind: clearKind ? null : (selectedKind ?? this.selectedKind),
      selectedPaymentStatus: clearPaymentStatus
          ? null
          : (selectedPaymentStatus ?? this.selectedPaymentStatus),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();
  final WalletRemoteDataSource _walletDataSource =
      getIt<WalletRemoteDataSource>();

  bool _reordering = false;

  TransactionsNotifier({TransactionKindFilter initialKindFilter})
    : super(
        TransactionsState(
          transactions: [],
          filteredTransactions: [],
          isLoading: true,
          selectedKind: initialKindFilter,
        ),
      ) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      List<WalletTransactionDto> walletTxs = [];
      var orderTransactions = <Transaction>[];
      var ordersFailed = false;
      var walletFailed = false;
      Object? firstError;

      try {
        final ordersResponse = await _orderDataSource.getOrders(perPage: 50);
        orderTransactions = ordersResponse.data.map(_mapOrder).toList();
      } catch (e) {
        ordersFailed = true;
        firstError = e;
      }

      try {
        walletTxs = await _walletDataSource.getMyTransactions();
      } catch (e) {
        walletFailed = true;
        firstError ??= e;
      }

      if (ordersFailed && walletFailed) {
        state = state.copyWith(
          isLoading: false,
          partialLoadFailed: false,
          error: ApiErrorMapper.message(firstError),
          transactions: [],
          filteredTransactions: [],
        );
        return;
      }

      final walletTransactions = walletTxs.map(_mapWallet).toList();

      final merged = [...orderTransactions, ...walletTransactions]
        ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

      state = _withFiltered(
        state.copyWith(
          transactions: merged,
          isLoading: false,
          partialLoadFailed: ordersFailed || walletFailed,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(e),
        partialLoadFailed: false,
        transactions: [],
        filteredTransactions: [],
      );
    }
  }

  Transaction _mapOrder(OrderDto orderDto) {
    final items = orderDto.effectiveItems;

    List<TransactionItem>? transactionItems;
    if (items.isNotEmpty) {
      transactionItems = items
          .map(
            (item) => TransactionItem(
              name: item.name,
              quantity: item.quantity,
              price: item.actualPrice ?? item.estimatedPrice ?? 0.0,
              unit: item.unit,
            ),
          )
          .toList();
    }

    return Transaction(
      id: orderDto.id.toString(),
      kind: TransactionKind.order,
      serviceName: _getServiceName(orderDto.serviceId),
      serviceId: orderDto.serviceId,
      date: orderDto.createdAt ?? DateTime.now().toIso8601String(),
      pickupLocation: orderDto.pickupAddress,
      dropoffLocation: orderDto.dropoffAddress,
      amount: orderDto.effectiveTotalAmount,
      status: mapOrderStatus(orderDto.status),
      rawStatus: orderDto.status,
      paymentStatus: PaymentStatusUtils.fromOrderPaymentStatus(
        orderDto.paymentStatus,
      ),
      paymentMethod: orderDto.paymentMethod,
      items: transactionItems,
      proofImages: orderDto.proofImages,
    );
  }

  Transaction _mapWallet(WalletTransactionDto dto) {
    final isCredit = dto.type.toLowerCase() == 'credit';
    return Transaction(
      id: 'w-${dto.id}',
      kind: TransactionKind.wallet,
      serviceName: 'LesPay',
      serviceId: 0,
      date: dto.createdAt,
      amount: dto.amount,
      status: TransactionStatus.completed,
      rawStatus: dto.type,
      paymentStatus: PaymentStatusUtils.fromWalletTransaction(dto),
      walletDescription: (dto.description?.isNotEmpty ?? false)
          ? dto.description!
          : (isCredit ? 'Top-up' : 'Payment'),
      walletReference: dto.reference,
      isWalletCredit: isCredit,
    );
  }

  void filterByKind(TransactionKindFilter kind) {
    final normalized = kind?.trim().toLowerCase();
    state = _withFiltered(
      state.copyWith(
        selectedKind: normalized,
        clearKind: normalized == null || normalized.isEmpty,
      ),
    );
  }

  void filterByService(String? service) {
    final normalized = service?.trim();
    state = _withFiltered(
      state.copyWith(
        selectedService: normalized,
        clearService: normalized == null || normalized.isEmpty,
      ),
    );
  }

  void filterByStatus(String? status) {
    final normalized = status?.trim().toLowerCase();
    state = _withFiltered(
      state.copyWith(
        selectedStatus: normalized,
        clearStatus: normalized == null || normalized.isEmpty,
      ),
    );
  }

  void filterByPaymentStatus(PaymentStatusFilter status) {
    final normalized = status?.trim().toLowerCase();
    state = _withFiltered(
      state.copyWith(
        selectedPaymentStatus: normalized,
        clearPaymentStatus: normalized == null || normalized.isEmpty,
      ),
    );
  }

  void searchOrders(String query) {
    state = _withFiltered(state.copyWith(searchQuery: query));
  }

  void clearFilters() {
    state = _withFiltered(
      state.copyWith(
        clearService: true,
        clearStatus: true,
        clearKind: true,
        clearPaymentStatus: true,
        searchQuery: '',
      ),
    );
  }

  void _applyFilters() {
    state = _withFiltered(state);
  }

  /// Re-run filters on the current in-memory list (e.g. after screen re-opens).
  void reapplyFilters() {
    _applyFilters();
  }

  TransactionsState _withFiltered(TransactionsState current) {
    return current.copyWith(filteredTransactions: _computeFiltered(current));
  }

  List<Transaction> _computeFiltered(TransactionsState current) {
    var filtered = List<Transaction>.from(current.transactions);
    final kind = current.selectedKind?.trim().toLowerCase();

    if (kind == 'order') {
      filtered = filtered.where((t) => t.isOrder).toList();
    } else if (kind == 'wallet') {
      // LesPay tab: wallet ledger only (top-ups, payments, refunds).
      filtered = filtered.where((t) => t.isWallet).toList();
    }

    final service = current.selectedService?.trim();
    if (service != null && service.isNotEmpty) {
      filtered = filtered.where((t) => t.serviceName == service).toList();
    }

    final status = current.selectedStatus?.trim().toLowerCase();
    if (status == OrderStatusConstants.completed) {
      filtered = filtered
          .where((t) => t.status == TransactionStatus.completed)
          .toList();
    } else if (status == OrderStatusConstants.cancelled) {
      filtered = filtered
          .where((t) => t.status == TransactionStatus.cancelled)
          .toList();
    } else if (status == OrderStatusConstants.pending) {
      filtered = filtered
          .where((t) => t.status == TransactionStatus.pending)
          .toList();
    }

    final paymentStatus = current.selectedPaymentStatus?.trim().toLowerCase();
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      filtered = filtered.where((t) {
        switch (paymentStatus) {
          case OrderStatusConstants.paid:
            return t.paymentStatus == PaymentStatus.paid;
          case OrderStatusConstants.refunded:
            return t.paymentStatus == PaymentStatus.refunded;
          case OrderStatusConstants.failed:
            return t.paymentStatus == PaymentStatus.failed;
          case OrderStatusConstants.pending_payment:
            return t.paymentStatus == PaymentStatus.pending;
          default:
            return true;
        }
      }).toList();
    }

    final query = current.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.id.toLowerCase().contains(query) ||
            t.date.toLowerCase().contains(query) ||
            t.pickupLocation.toLowerCase().contains(query) ||
            t.dropoffLocation.toLowerCase().contains(query) ||
            t.displayTitle.toLowerCase().contains(query) ||
            (t.walletDescription?.toLowerCase().contains(query) ?? false) ||
            (t.walletReference?.toLowerCase().contains(query) ?? false) ||
            (t.paymentMethod?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  /// Re-places an order. Returns true on success. Throws on failure so the
  /// caller can show the message without wiping the list via `state.error`.
  /// Returns false when ignored (wallet row or a reorder already in flight).
  Future<bool> reorderTransaction(String orderId) async {
    if (orderId.startsWith('w-')) return false;
    if (_reordering) return false;
    final id = int.tryParse(orderId);
    if (id == null) return false;
    _reordering = true;
    try {
      await _orderDataSource.reorderOrder(id);
    } finally {
      _reordering = false;
    }
    // The order exists now; a failed refresh must not report a failed reorder.
    try {
      await _loadTransactions();
    } catch (_) {}
    return true;
  }

  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  String _getServiceName(int serviceId) {
    switch (serviceId) {
      case 1:
        return 'LesGo';
      case 2:
        return 'LesRide';
      case 3:
        return 'LesEat';
      case 4:
        return 'LesBuy';
      case 5:
        return 'LesTransport';
      default:
        return 'Order';
    }
  }

  /// Active statuses -> pending (live); completed -> completed; every other
  /// status (cancelled, failed, rejected, expired, unknown...) -> cancelled so
  /// an unrecognised status is never shown as a live order.
  static TransactionStatus mapOrderStatus(String status) {
    if (status.toLowerCase() == OrderStatusConstants.completed) {
      return TransactionStatus.completed;
    }
    if (OrderStatusConstants.isActive(status)) {
      return TransactionStatus.pending;
    }
    return TransactionStatus.cancelled;
  }

  DateTime _parseDate(String iso) {
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
      ref.watch(userSessionEpochProvider);
      return TransactionsNotifier();
    });
