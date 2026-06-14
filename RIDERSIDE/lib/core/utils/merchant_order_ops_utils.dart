import '../../data/data_source/dto/merchant/order_dto.dart';

class MerchantOrderOpsUtils {
  MerchantOrderOpsUtils._();

  static String normalizedStatus(String status) => status.toLowerCase();

  static bool isPending(String status) => normalizedStatus(status) == 'pending';

  static bool canReject(String status) => isPending(status);

  static bool canAccept(String status) => isPending(status);

  static bool canCancelAfterAccept(String status) {
    final s = normalizedStatus(status);
    return s == 'searching_driver' ||
        s == 'accepted' ||
        s == 'ready_for_pickup';
  }

  /// Rider has picked up — merchant can no longer cancel.
  static bool isRiderFlowStatus(String status) {
    final s = normalizedStatus(status);
    return s == 'picked_up' ||
        s == 'in_progress' ||
        s == 'driver_arrived_at_pickup' ||
        s == 'completed';
  }

  static bool canMarkReadyForPickup(String status) {
    final s = normalizedStatus(status);
    return s == 'searching_driver' || s == 'accepted';
  }

  static bool showsPrepTimer(String status) {
    final s = normalizedStatus(status);
    return s == 'searching_driver' || s == 'accepted';
  }

  static String? orderSpecialInstructions(OrderDto order) {
    final notes = order.specialInstructions?.trim();
    if (notes == null || notes.isEmpty) return null;
    return notes;
  }

  static List<String> itemSpecialInstructions(OrderDto order) {
    final items = order.orderItems;
    if (items == null || items.isEmpty) return const [];

    final instructions = <String>[];
    for (final item in items) {
      final note = item.notes?.trim();
      if (note == null || note.isEmpty) continue;
      instructions.add('${item.quantity}x ${item.itemName}: $note');
    }
    return instructions;
  }

  static bool hasSpecialInstructions(OrderDto order) {
    return orderSpecialInstructions(order) != null ||
        itemSpecialInstructions(order).isNotEmpty;
  }
}
