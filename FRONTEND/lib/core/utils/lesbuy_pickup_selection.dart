import '../../data/data_source/dto/order/create_order_request_dto.dart';

/// The current order API has exactly one pickup. Never infer a common pickup
/// for a cart containing both merchant inventory and a manual buying request.
class LesbuyPickupSelection {
  static const mixedCartMessage =
      'Store and manual purchases need separate orders. Remove one group to continue; your manual buying location is preserved.';

  static OrderAddressDto select({
    required bool hasStoreItems,
    required bool hasManualItems,
    required OrderAddressDto store,
    OrderAddressDto? manual,
  }) {
    if (hasStoreItems && hasManualItems) {
      throw StateError(mixedCartMessage);
    }
    if (hasManualItems) {
      if (manual == null || manual.address.trim().isEmpty ||
          !manual.lat.isFinite || !manual.lng.isFinite ||
          manual.lat.abs() > 90 || manual.lng.abs() > 180 ||
          (manual.lat == 0 && manual.lng == 0)) {
        throw StateError('Select and pin the buying location before checkout.');
      }
      return manual;
    }
    if (!hasStoreItems) throw StateError('Add items before checkout.');
    return store;
  }
}
