import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../data/data_source/dto/order/orders_response_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
class OrderHistoryState {
  final List<OrderDto> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String selectedFilter; // 'all', 'completed', 'cancelled', 'active'
  final bool hasMore;
  final int currentPage;

  OrderHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedFilter = 'all',
    this.hasMore = true,
    this.currentPage = 1,
  });

  OrderHistoryState copyWith({
    List<OrderDto>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? selectedFilter,
    bool? hasMore,
    int? currentPage,
    bool clearError = false,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
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
    loadOrders(refresh: true);
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    final pageToLoad = refresh ? 1 : state.currentPage;

    state = state.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: refresh,
    );

    try {
      final dataSource = getIt<OrderRemoteDataSource>();

      String? statusFilter;
      if (state.selectedFilter == 'completed') {
        statusFilter = 'completed';
      } else if (state.selectedFilter == 'cancelled') {
        statusFilter = 'cancelled';
      }

      final response = await dataSource.getOrders(
        status: statusFilter,
        perPage: 20,
        page: pageToLoad,
      );

      if (response.success) {
        final newOrders = response.data;
        final merged = refresh
            ? newOrders
            : _mergeOrders(state.orders, newOrders);

        state = state.copyWith(
          orders: merged,
          isLoading: false,
          isLoadingMore: false,
          hasMore: _resolveHasMore(response, newOrders.length),
          currentPage: pageToLoad + 1,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: 'Failed to load orders',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load orders.',
          fallbackTl: 'Hindi ma-load ang orders.',
        ),
      );
    }
  }

  List<OrderDto> _mergeOrders(List<OrderDto> existing, List<OrderDto> incoming) {
    final seen = existing.map((o) => o.id).toSet();
    final merged = List<OrderDto>.from(existing);
    for (final order in incoming) {
      if (!seen.contains(order.id)) {
        merged.add(order);
        seen.add(order.id);
      }
    }
    return merged;
  }

  bool _resolveHasMore(OrdersResponseDto response, int fetchedCount) {
    final meta = response.meta;
    if (meta != null) {
      final current = meta['current_page'];
      final last = meta['last_page'];
      if (current is num && last is num) {
        return current.toInt() < last.toInt();
      }
    }
    return fetchedCount >= 20;
  }

  Future<void> loadMoreOrders() => loadOrders(refresh: false);

  void changeFilter(String filter) {
    if (state.selectedFilter == filter) return;
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
        final updatedOrders = state.orders.map((order) {
          if (order.id == orderId) {
            return response.data;
          }
          return order;
        }).toList();

        state = state.copyWith(orders: updatedOrders, clearError: true);
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
