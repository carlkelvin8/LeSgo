import 'package:flutter/material.dart';
import '../../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../../provider/main/merchantside/merchant_prep_timer_provider.dart';
import '../../../common/menu_image_widget.dart';
import 'merchant_prep_timer_badge.dart';

class OrderQueuePalette {
  static const purple = Color(0xFF5F2D82);
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
    'pending' || 'searching_driver' || 'accepted' => const Color(0xFF965A08),
    'cancelled' => const Color(0xFFBE303B),
    'ready_for_pickup' || 'completed' => const Color(0xFF087F63),
    'driver_arrived_at_pickup' ||
    'picked_up' ||
    'in_progress' => const Color(0xFF2463B4),
    _ => const Color(0xFF62586F),
  };

  /// Payment badge that reads correctly for the order's state, e.g. a
  /// cancelled cash order was never collected rather than "failed".
  ({String label, IconData icon, Color color})? _paymentBadge(
    String status,
    String Function(String) displayLabel,
    bool dark,
  ) {
    final method = order.paymentMethod.toLowerCase();
    final payStatus = order.paymentStatus.toLowerCase();
    final isCash = method == 'cash' || method == 'cod';
    final methodLabel = isCash ? 'Cash' : displayLabel(order.paymentMethod);
    const grey = Color(0xFF7A6F88);
    const green = Color(0xFF087F63);
    final red = dark ? const Color(0xFFFFA8B8) : const Color(0xFFA12B45);

    if (status == 'cancelled') {
      if (payStatus == 'paid' && !isCash) {
        return (
          label: '$methodLabel · Refund due',
          icon: Icons.replay_rounded,
          color: const Color(0xFF965A08),
        );
      }
      return (
        label: isCash ? 'Cash · Not collected' : '$methodLabel · Not charged',
        icon: Icons.money_off_rounded,
        color: grey,
      );
    }
    if (payStatus == 'paid') {
      return (
        label: '$methodLabel · Paid',
        icon: Icons.check_circle_outline_rounded,
        color: green,
      );
    }
    if (payStatus == 'failed') {
      return (
        label: '$methodLabel · Payment failed',
        icon: Icons.error_outline_rounded,
        color: red,
      );
    }
    if (isCash) {
      return (
        label: status == 'completed' ? 'Cash' : 'Cash on delivery',
        icon: Icons.payments_outlined,
        color: grey,
      );
    }
    return null;
  }

  static String? _ago(DateTime? created) {
    if (created == null) return null;
    final diff = DateTime.now().difference(created);
    if (diff.isNegative || diff.inHours >= 24) return null;
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  static IconData _statusIcon(String status) => switch (status) {
    'pending' => Icons.notifications_active_outlined,
    'cancelled' => Icons.cancel_outlined,
    'completed' => Icons.check_circle_outline_rounded,
    'ready_for_pickup' => Icons.takeout_dining_outlined,
    'searching_driver' || 'accepted' => Icons.soup_kitchen_outlined,
    _ => Icons.delivery_dining_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final status = order.status.toLowerCase();
    final accent = statusColor(status);
    final cancelled = status == 'cancelled';
    String displayLabel(String value) => value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = OrderQueuePalette.text(context);
    final muted = OrderQueuePalette.muted(context);
    final brandText = dark ? const Color(0xFFD7BEFF) : OrderQueuePalette.purple;
    final accentText = dark ? Color.lerp(accent, Colors.white, .55)! : accent;
    final hairline = dark ? const Color(0xFF393044) : const Color(0xFFEDE6F4);
    final items = order.orderItems ?? [];
    final quantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final note =
        MerchantOrderOpsUtils.orderSpecialInstructions(order) ??
        MerchantOrderOpsUtils.itemSpecialInstructions(order).firstOrNull;
    final created = DateTime.tryParse(order.createdAt)?.toLocal();
    final time = created == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(created));
    final ago = _ago(created);
    final actionable =
        MerchantOrderOpsUtils.canAccept(status) ||
        MerchantOrderOpsUtils.canMarkReadyForPickup(status);
    final canReject = MerchantOrderOpsUtils.canReject(status);
    final canCancel = MerchantOrderOpsUtils.canCancelAfterAccept(status);
    final customer = (order.user?.name ?? '').trim();
    final pay =
        _paymentBadge(status, displayLabel, dark) ??
        (
          label: displayLabel(order.paymentMethod),
          icon: Icons.payments_outlined,
          color: muted,
        );
    final shownItems = items.take(3).toList();

    // ── Status band ──────────────────────────────────────────────────
    final band = Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      color: accent.withValues(alpha: dark ? .18 : .08),
      child: Row(
        children: [
          Icon(_statusIcon(status), size: 17, color: accentText),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              statusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentText,
              ),
            ),
          ),
          if (time != null)
            Text(
              ago == null ? time : '$time · $ago',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
        ],
      ),
    );

    // ── Customer ─────────────────────────────────────────────────────
    final initialAvatar = CircleAvatar(
      radius: 22,
      backgroundColor: OrderQueuePalette.purple.withValues(alpha: .12),
      child: Text(
        customer.isEmpty ? 'C' : customer[0].toUpperCase(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: brandText,
        ),
      ),
    );
    final photo = order.user?.resolvedProfilePhotoUrl;
    final avatar = photo == null
        ? initialAvatar
        : ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              // Falls back to the initial while loading or on error.
              child: MenuImageWidget(
                source: photo,
                fit: BoxFit.cover,
                placeholder: initialAvatar,
              ),
            ),
          );

    final customerRow = Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.isEmpty ? 'Customer' : customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              if (order.dropoffAddress.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        order.dropoffAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ORDER',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: muted,
              ),
            ),
            Text(
              '#${order.referenceNumber ?? order.id}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
          ],
        ),
      ],
    );

    // ── Items ────────────────────────────────────────────────────────
    final itemsBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: MenuImageWidget(
              source: imageUrl,
              fit: BoxFit.cover,
              placeholder: Container(
                color: OrderQueuePalette.purple.withValues(alpha: .10),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: brandText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: items.isEmpty
              ? Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'View order items',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: brandText,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in shownItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${item.quantity}×',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: brandText,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (items.length > shownItems.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${items.length - shownItems.length} more · $quantity items',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );

    final noteBlock = note == null
        ? null
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF3A2E14) : const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 17,
                  color: Color(0xFF965A08),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.45, color: text),
                  ),
                ),
              ],
            ),
          );

    // ── Footer: total, payment, actions ──────────────────────────────
    final payPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pay.color.withValues(alpha: dark ? .2 : .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pay.icon, size: 14, color: pay.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              pay.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: pay.color,
              ),
            ),
          ),
        ],
      ),
    );

    final totals = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            Text(
              'PHP ${MerchantOrderAmountUtils.foodEarnings(order).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
                // A cancelled order earns nothing, so de-emphasize it.
                color: cancelled ? muted : text,
                decoration: cancelled ? TextDecoration.lineThrough : null,
                decorationColor: muted,
              ),
            ),
            const SizedBox(height: 6),
            payPill,
          ],
        ),
        const Spacer(),
        // Finished orders have no actions, so the details link sits here.
        if (!actionable)
          Material(
            color: OrderQueuePalette.purple,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onOpen,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    final actions = Row(
      children: [
        if (canReject || canCancel) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : canReject
                  ? onReject
                  : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: dark
                    ? const Color(0xFFFFA8B8)
                    : const Color(0xFFA12B45),
                minimumSize: const Size(0, 46),
                side: BorderSide(
                  color: const Color(0xFFBE303B).withValues(alpha: .3),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(canReject ? 'Reject' : 'Cancel'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: busy ? null : (status == 'pending' ? onAccept : onReady),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    status == 'pending'
                        ? Icons.check_rounded
                        : Icons.takeout_dining_outlined,
                    size: 18,
                  ),
            label: Text(
              busy
                  ? 'Updating…'
                  : status == 'pending'
                  ? 'Accept order'
                  : 'Mark ready',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: OrderQueuePalette.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 46),
              textStyle: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: OrderQueuePalette.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: status == 'pending' ? accent.withValues(alpha: .45) : hairline,
          width: status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: OrderQueuePalette.purple.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            // Cancelled orders recede so active ones stand out.
            opacity: cancelled ? .8 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                band,
                InkWell(
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        customerRow,
                        const SizedBox(height: 14),
                        itemsBlock,
                        if (noteBlock != null) ...[
                          const SizedBox(height: 12),
                          noteBlock,
                        ],
                      ],
                    ),
                  ),
                ),
                _DashedDivider(color: hairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      totals,
                      if (MerchantOrderOpsUtils.showsPrepTimer(status) &&
                          timer != null) ...[
                        const SizedBox(height: 12),
                        MerchantPrepTimerBadge(timer: timer, compact: true),
                      ],
                      if (actionable) ...[
                        const SizedBox(height: 14),
                        actions,
                      ] else if (canCancel) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: busy ? null : onCancel,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Cancel order'),
                            style: TextButton.styleFrom(
                              foregroundColor: muted,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                              textStyle: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Receipt-style dashed separator between the order body and its totals.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dash = 6.0, gap = 4.0;
          final count = (constraints.maxWidth / (dash + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dash,
                height: 1.2,
                child: ColoredBox(color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}
