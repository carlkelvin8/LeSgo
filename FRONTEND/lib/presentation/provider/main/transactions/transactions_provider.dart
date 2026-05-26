import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
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
      filteredTransactions:
          filteredTransactions ?? this.filteredTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
      selectedService:
          clearService ? null : (selectedService ?? this.selectedService),
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
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

  TransactionsNotifier({TransactionKindFilter initialKindFilter})
      : super(TransactionsState(
          transactions: [],
          filteredTransactions: [],
          isLoading: true,
          selectedKind: initialKindFilter,
        )) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      List<WalletTransactionDto> walletTxs = [];
      var orderTransactions = <Transaction>[];

      try {
        final ordersResponse = await _orderDataSource.getOrders(perPage: 50);
        orderTransactions =
            ordersResponse.data.map(_mapOrder).toList();
      } catch (_) {}

      try {
        walletTxs = await _walletDataSource.getMyTransactions();
      } catch (_) {}
      final walletTransactions = walletTxs.map(_mapWallet).toList();

      final merged = [...orderTransactions, ...walletTransactions]
        ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

      state = state.copyWith(
        transactions: merged,
        filteredTransactions: merged,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
              price: item.actualPrice ?? item.estimatedPrice,
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
      status: _mapOrderStatus(orderDto.status),
      rawStatus: orderDto.status,
      paymentStatus:
          PaymentStatusUtils.fromOrderPaymentStatus(orderDto.paymentStatus),
      paymentMethod: orderDto.paymentMethod,
      items: transactionItems,
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
      walletDescription:
          dto.description.isNotEmpty ? dto.description : (isCredit ? 'Top-up' : 'Payment'),
      walletReference: dto.reference,
      isWalletCredit: isCredit,
    );
  }

  void filterByKind(TransactionKindFilter kind) {
    state = state.copyWith(
      selectedKind: kind,
      clearKind: kind == null,
    );
    _applyFilters();
  }

  void filterByService(String? service) {
    state = state.copyWith(
      selectedService: service,
      clearService: service == null,
    );
    _applyFilters();
  }

  void filterByStatus(String? status) {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
    _applyFilters();
  }

  void filterByPaymentStatus(PaymentStatusFilter status) {
    state = state.copyWith(
      selectedPaymentStatus: status,
      clearPaymentStatus: status == null,
    );
    _applyFilters();
  }

  void searchOrders(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      clearService: true,
      clearStatus: true,
      clearKind: true,
      clearPaymentStatus: true,
      searchQuery: '',
    );
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Transaction>.from(state.transactions);

    if (state.selectedKind == 'order') {
      filtered = filtered.where((t) => t.isOrder).toList();
    } else if (state.selectedKind == 'wallet') {
      filtered = filtered.where((t) => t.isWallet).toList();
    }

    if (state.selectedService != null) {
      filtered =
          filtered.where((t) => t.serviceName == state.selectedService).toList();
    }

    if (state.selectedStatus != null) {
      if (state.selectedStatus == 'completed') {
        filtered = filtered
            .where((t) => t.status == TransactionStatus.completed)
            .toList();
      } else if (state.selectedStatus == 'cancelled') {
        filtered = filtered
            .where((t) => t.status == TransactionStatus.cancelled)
            .toList();
      } else if (state.selectedStatus == 'pending') {
        filtered = filtered
            .where((t) => t.status == TransactionStatus.pending)
            .toList();
      }
    }

    if (state.selectedPaymentStatus != null) {
      filtered = filtered.where((t) {
        switch (state.selectedPaymentStatus) {
          case 'paid':
            return t.paymentStatus == PaymentStatus.paid;
          case 'failed':
            return t.paymentStatus == PaymentStatus.failed;
          case 'refunded':
            return t.paymentStatus == PaymentStatus.refunded;
          case 'pending':
            return t.paymentStatus == PaymentStatus.pending;
          default:
            return true;
        }
      }).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
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

    state = state.copyWith(filteredTransactions: filtered);
  }

  Future<void> reorderTransaction(String orderId) async {
    if (orderId.startsWith('w-')) return;
    try {
      await _orderDataSource.reorderOrder(int.parse(orderId));
      await _loadTransactions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to reorder: $e');
    }
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

  TransactionStatus _mapOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return TransactionStatus.completed;
      case 'cancelled':
      case 'failed':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  DateTime _parseDate(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier();
});
