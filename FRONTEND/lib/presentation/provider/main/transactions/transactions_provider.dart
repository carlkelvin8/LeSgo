import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/transactions/transaction.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../core/di/injection.dart';

class TransactionsState {
  final List<Transaction> transactions;
  final List<Transaction> filteredTransactions;
  final bool isLoading;
  final String? error;
  final String? selectedService; // null = All
  final String? selectedStatus; // null = All
  final String searchQuery;

  TransactionsState({
    required this.transactions,
    required this.filteredTransactions,
    this.isLoading = false,
    this.error,
    this.selectedService,
    this.selectedStatus,
    this.searchQuery = '',
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    List<Transaction>? filteredTransactions,
    bool? isLoading,
    String? error,
    String? selectedService,
    String? selectedStatus,
    String? searchQuery,
    bool clearService = false,
    bool clearStatus = false,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
      selectedService: clearService ? null : (selectedService ?? this.selectedService),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();

  TransactionsNotifier()
      : super(TransactionsState(
          transactions: [],
          filteredTransactions: [],
          isLoading: true,
        )) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      print('🔵 Transactions: Fetching orders from API...');
      final response = await _orderDataSource.getOrders(perPage: 100);
      
      print('🟢 Transactions: Got ${response.data.length} orders');
      
      final transactions = response.data.map((orderDto) {
        return Transaction(
          id: orderDto.id.toString(),
          serviceName: _getServiceName(orderDto.serviceId),
          serviceId: orderDto.serviceId,
          date: orderDto.createdAt ?? DateTime.now().toIso8601String(),
          pickupLocation: orderDto.pickupAddress,
          dropoffLocation: orderDto.dropoffAddress,
          amount: (orderDto.actualFare ?? orderDto.estimatedFare),
          status: _mapOrderStatus(orderDto.status),
          rawStatus: orderDto.status,
        );
      }).toList();
      
      state = state.copyWith(
        transactions: transactions,
        filteredTransactions: transactions,
        isLoading: false,
      );
      
      // Apply current filters
      _applyFilters();
    } catch (e) {
      print('🔴 Transactions: Error fetching orders - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        transactions: [],
        filteredTransactions: [],
      );
    }
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

  void searchOrders(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      clearService: true,
      clearStatus: true,
      searchQuery: '',
    );
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Transaction>.from(state.transactions);

    // Filter by service
    if (state.selectedService != null) {
      filtered = filtered.where((t) => t.serviceName == state.selectedService).toList();
    }

    // Filter by status
    if (state.selectedStatus != null) {
      if (state.selectedStatus == 'completed') {
        filtered = filtered.where((t) => t.status == TransactionStatus.completed).toList();
      } else if (state.selectedStatus == 'cancelled') {
        filtered = filtered.where((t) => t.status == TransactionStatus.cancelled).toList();
      } else if (state.selectedStatus == 'pending') {
        filtered = filtered.where((t) => t.status == TransactionStatus.pending).toList();
      }
    }

    // Search by order ID or date
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.id.toLowerCase().contains(query) ||
               t.date.toLowerCase().contains(query) ||
               t.pickupLocation.toLowerCase().contains(query) ||
               t.dropoffLocation.toLowerCase().contains(query);
      }).toList();
    }

    state = state.copyWith(filteredTransactions: filtered);
  }

  Future<void> reorderTransaction(String orderId) async {
    try {
      print('🔵 Transactions: Reordering order #$orderId');
      await _orderDataSource.reorderOrder(int.parse(orderId));
      print('🟢 Transactions: Order reordered successfully');
      
      // Refresh transactions to show new order
      await _loadTransactions();
    } catch (e) {
      print('🔴 Transactions: Reorder error - $e');
      state = state.copyWith(error: 'Failed to reorder: $e');
    }
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

  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier();
});
