import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/order_cancel_utils.dart';

class OrderHistoryState {
  final List<OrderDto> orders;
  final bool isLoading;
  final String? error;
  final String selectedFilter; // 'all', 'completed', 'cancelled', 'active'
  final bool hasMore;
  final int currentPage;

  OrderHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'all',
    this.hasMore = true,
    this.currentPage = 1,
  });

  OrderHistoryState copyWith({
    List<OrderDto>? orders,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    bool? hasMore,
    int? currentPage,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<OrderDto> get filteredOrders {
    switch (selectedFilter) {
      case 'completed':
        return orders.where((o) => o.status == 'completed').toList();
      case 'cancelled':
        return orders.where((o) => o.status == 'cancelled').toList();
      case 'active':
        return orders
            .where((o) =>
                o.status != 'completed' &&
                o.status != 'cancelled' &&
                o.status != 'failed')
            .toList();
      default:
        return orders;
    }
  }
}

class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  OrderHistoryNotifier() : super(OrderHistoryState()) {
    loadOrders();
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        orders: [],
        currentPage: 1,
        hasMore: true,
        isLoading: true,
        error: null,
      );
    } else if (state.isLoading) {
      return;
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      
      String? statusFilter;
      if (state.selectedFilter == 'completed') {
        statusFilter = 'completed';
      } else if (state.selectedFilter == 'cancelled') {
        statusFilter = 'cancelled';
      } else if (state.selectedFilter == 'active') {
        // For active, we'll filter client-side
        statusFilter = null;
      }

      final response = await dataSource.getOrders(
        status: statusFilter,
        perPage: 20,
      );

      if (response.success) {
        final newOrders = response.data;

        state = state.copyWith(
          orders: refresh ? newOrders : [...state.orders, ...newOrders],
          isLoading: false,
          hasMore: newOrders.length >= 20,
          currentPage: state.currentPage + 1,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load orders',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void changeFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    loadOrders(refresh: true);
  }

  Future<void> refreshOrders() async {
    await loadOrders(refresh: true);
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      final response = await dataSource.cancelOrder(orderId, reason);

      if (response.success) {
        // Update the order in the list
        final updatedOrders = state.orders.map((order) {
          if (order.id == orderId) {
            return response.data;
          }
          return order;
        }).toList();

        state = state.copyWith(orders: updatedOrders);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not cancel order.',
          fallbackTl: 'Hindi makansela ang order.',
        ),
      );
      return false;
    }
  }

  Future<bool> reorder(int orderId) async {
    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      final response = await dataSource.reorderOrder(orderId);

      if (response.success) {
        // Add the new order to the top of the list
        state = state.copyWith(
          orders: [response.data, ...state.orders],
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  return OrderHistoryNotifier();
});
