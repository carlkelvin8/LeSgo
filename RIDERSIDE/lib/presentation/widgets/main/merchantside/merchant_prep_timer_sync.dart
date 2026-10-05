import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../provider/main/merchantside/merchant_prep_timer_provider.dart';

/// Syncs prep timers whenever merchant orders are refreshed.
class MerchantPrepTimerSync extends ConsumerWidget {
  final Widget child;

  const MerchantPrepTimerSync({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<OrderDto>>>(merchantOrdersProvider, (previous, next) {
      next.whenData((orders) {
        ref.read(merchantPrepTimerProvider.notifier).syncWithOrders(orders);
      });
    });

    // Keep orders provider warm for sync while merchant shell is open.
    ref.watch(merchantOrdersProvider);

    return child;
  }
}
