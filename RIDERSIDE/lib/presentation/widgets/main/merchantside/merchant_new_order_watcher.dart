import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/merchant_order_alert_service.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../provider/main/merchantside/merchant_sound_settings_provider.dart';
import '../../../provider/main/merchantside/printer_settings_provider.dart';

class MerchantNewOrderWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const MerchantNewOrderWatcher({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MerchantNewOrderWatcher> createState() =>
      _MerchantNewOrderWatcherState();
}

class _MerchantNewOrderWatcherState extends ConsumerState<MerchantNewOrderWatcher> {
  final Set<int> _knownPendingIds = {};
  bool _initialized = false;

  void _handleOrders(List<OrderDto> orders) {
    final pendingOrders = orders
        .where((order) => MerchantOrderOpsUtils.isPending(order.status))
        .toList();
    final pendingIds = pendingOrders.map((order) => order.id).toSet();

    if (_initialized) {
      final newIds = pendingIds.difference(_knownPendingIds);
      for (final id in newIds) {
        final order = pendingOrders.firstWhere((item) => item.id == id);
        final orderRef = order.referenceNumber ?? '#${order.id}';
        final playSound = ref.read(soundEnabledProvider);
        MerchantOrderAlertService.alertNewOrder(orderRef: orderRef, playSound: playSound);
        _autoPrintOrder(order);
      }
    }

    _knownPendingIds
      ..clear()
      ..addAll(pendingIds);
    _initialized = true;
  }

  void _autoPrintOrder(OrderDto order) {
    final printerState = ref.read(printerSettingsProvider);
    if (!printerState.isAutoPrintEnabled) return;
    if (printerState.connectedAddress == null) return;

    final storeName = order.partner?.name ?? 'Store';
    PrinterService().printOrder(order, storeName);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<OrderDto>>>(merchantOrdersProvider, (previous, next) {
      next.whenData(_handleOrders);
    });

    ref.watch(merchantOrdersProvider);

    return widget.child;
  }
}
