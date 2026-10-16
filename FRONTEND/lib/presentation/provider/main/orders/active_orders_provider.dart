import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/active_order_limit_guard.dart';
import '../../../../core/utils/order_status_utils.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../../../data/data_source/order_remote_datasource.dart';

class ActiveOrdersState {
  final List<OrderDto> orders;
  final bool isLoading;
  final String? error;

  const ActiveOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  ActiveOrdersState copyWith({
    List<OrderDto>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ActiveOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  OrderDto? get primaryOrder => orders.isEmpty ? null : orders.first;
  int get extraCount => orders.length > 1 ? orders.length - 1 : 0;
}

class ActiveOrdersNotifier extends StateNotifier<ActiveOrdersState> {
  ActiveOrdersNotifier() : super(const ActiveOrdersState());

  Future<void> loadActiveOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      final response = await dataSource.getOrders(perPage: 30);

      if (!response.success) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load active orders',
        );
        return;
      }

      final active =
          response.data
              .where((order) => !OrderStatusUtils.isTerminal(order.status))
              .toList()
            ..sort((a, b) {
              final aDate = a.updatedAt ?? a.createdAt ?? '';
              final bDate = b.updatedAt ?? b.createdAt ?? '';
              return bDate.compareTo(aDate);
            });

      state = state.copyWith(
        orders: active.take(ActiveOrderLimitGuard.maxActiveOrders).toList(),
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load active orders.',
          fallbackTl: 'Hindi ma-load ang active orders.',
        ),
      );
    }
  }
}

final activeOrdersProvider =
    StateNotifierProvider<ActiveOrdersNotifier, ActiveOrdersState>((ref) {
      ref.watch(userSessionEpochProvider);
      return ActiveOrdersNotifier();
    });
