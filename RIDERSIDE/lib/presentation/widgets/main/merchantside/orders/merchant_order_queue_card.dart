import 'package:flutter/material.dart';
import '../../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../../provider/main/merchantside/merchant_prep_timer_provider.dart';
import '../../../common/menu_image_widget.dart';
import 'merchant_prep_timer_badge.dart';

class OrderQueuePalette {
  static const purple = Color(0xFF6D36C8);
  static const ink = Color(0xFF251A38);
  static Color surface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFF211B2E)
      : Colors.white;
  static Color text(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFFF5EFFF) : ink;
  static Color muted(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFFB8ACC9)
      : const Color(0xFF62586F);
}

class MerchantOrderQueueCard extends StatelessWidget {
  const MerchantOrderQueueCard({
    super.key,
    required this.order,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
    required this.onReady,
    required this.onCancel,
    this.imageUrl,
    this.timer,
    this.busy = false,
  });
  final OrderDto order;
  final VoidCallback onOpen, onAccept, onReject, onReady, onCancel;
  final String? imageUrl;
  final MerchantPrepTimerEntry? timer;
  final bool busy;

  static String statusLabel(String status) => switch (status.toLowerCase()) {
    'pending' => 'New order',
    'searching_driver' => 'Preparing · finding rider',
    'accepted' => 'Preparing · rider assigned',
    'ready_for_pickup' => 'Ready for pickup',
    'driver_arrived_at_pickup' => 'Rider at store',
    'picked_up' || 'in_progress' => 'Out for delivery',
    'completed' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status.replaceAll('_', ' '),
  };

  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'pending' => const Color(0xFFB85E0C),
    'searching_driver' || 'accepted' => OrderQueuePalette.purple,
    'cancelled' => const Color(0xFFBE4059),
    'ready_for_pickup' || 'completed' => const Color(0xFF15816A),
    _ => const Color(0xFF3276B6),
  };

  @override
  Widget build(BuildContext context) {
    final status = order.status.toLowerCase();
    final accent = statusColor(status);
    String displayLabel(String value) => value.replaceAll('_', ' ').split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = order.orderItems ?? [];
    final quantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final summary = items.isEmpty
        ? 'View order items'
        : items.map((i) => '${i.quantity}× ${i.itemName}').join(' · ');
    final note =
        MerchantOrderOpsUtils.orderSpecialInstructions(order) ??
        MerchantOrderOpsUtils.itemSpecialInstructions(order).firstOrNull;
    final created = DateTime.tryParse(order.createdAt)?.toLocal();
    final time = created == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(created));
    final actionable =
        MerchantOrderOpsUtils.canAccept(status) ||
        MerchantOrderOpsUtils.canMarkReadyForPickup(status);
    final canReject = MerchantOrderOpsUtils.canReject(status);
    final canCancel = MerchantOrderOpsUtils.canCancelAfterAccept(status);
    return Material(
      color: OrderQueuePalette.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: status == 'pending'
              ? accent.withValues(alpha: .30)
              : (dark ? const Color(0xFF393044) : const Color(0xFFDDD4E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: dark ? .22 : .12),
                          border: Border.all(color: accent.withValues(alpha: .18)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel(status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: dark
                                ? Color.lerp(accent, Colors.white, .55)
                                : accent,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            color: OrderQueuePalette.muted(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${order.referenceNumber ?? order.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                                color: OrderQueuePalette.text(context),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              order.user?.name ?? 'Customer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: OrderQueuePalette.text(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 20,
                        color: OrderQueuePalette.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: MenuImageWidget(
                            source: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: OrderQueuePalette.purple.withValues(
                                alpha: .10,
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: OrderQueuePalette.purple,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: OrderQueuePalette.text(context),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              quantity == 0
                                  ? 'Order details'
                                  : '$quantity ${quantity == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: OrderQueuePalette.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (order.dropoffAddress.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: OrderQueuePalette.muted(context),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            order.dropoffAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: OrderQueuePalette.muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF392F22)
                            : const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Note: $note',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: dark
                              ? const Color(0xFFFFD78A)
                              : const Color(0xFF805516),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(
                  height: 1,
                  color: dark
                      ? const Color(0xFF393044)
                      : const Color(0xFFEFEAF4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOOD TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: OrderQueuePalette.muted(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'PHP ${MerchantOrderAmountUtils.foodEarnings(order).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6,
                            color: OrderQueuePalette.text(context),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${displayLabel(order.paymentMethod)} · ${displayLabel(order.paymentStatus)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: order.paymentStatus == 'failed'
                            ? (dark ? const Color(0xFFFFA8B8) : const Color(0xFFA12B45))
                            : OrderQueuePalette.muted(context),
                      ),
                    ),
                  ],
                ),
                if (MerchantOrderOpsUtils.showsPrepTimer(status) &&
                    timer != null) ...[
                  const SizedBox(height: 12),
                  MerchantPrepTimerBadge(timer: timer, compact: true),
                ],
                const SizedBox(height: 14),
                if (actionable) ...[
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : (status == 'pending' ? onAccept : onReady),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            status == 'pending'
                                ? Icons.check_rounded
                                : Icons.takeout_dining_outlined,
                            size: 18,
                          ),
                    label: Text(
                      busy
                          ? 'Updating order…'
                          : status == 'pending'
                          ? 'Accept order'
                          : 'Mark ready for pickup',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: OrderQueuePalette.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  if (canReject || canCancel)
                    TextButton(
                      onPressed: busy
                          ? null
                          : canReject
                          ? onReject
                          : onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: OrderQueuePalette.muted(context),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(canReject ? 'Reject order' : 'Cancel order'),
                    ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: const Text('View order details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark
                          ? const Color(0xFFD7BEFF)
                          : OrderQueuePalette.purple,
                      minimumSize: const Size(0, 48),
                      backgroundColor: dark ? const Color(0xFF2C203C) : const Color(0xFFF5EFFB),
                      side: BorderSide(color: dark ? const Color(0xFF624A7C) : const Color(0xFFD6C3E9)),
                      animationDuration: Duration.zero,
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontFamily: 'TT Fors', fontSize: 14, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  if (canCancel)
                    TextButton(
                      onPressed: busy ? null : onCancel,
                      child: const Text('Cancel order'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
