import '../../data/data_source/dto/address/address_dto.dart';
import 'booking_geo_utils.dart';

/// LesBuy manual (papabili) orders: delivery fee is calculated after the rider
/// uploads the first item photo — distance from that store location to customer.
class LesbuyManualDeliveryUtils {
  LesbuyManualDeliveryUtils._();

  /// A manual order needs a real customer drop-off, never map defaults.
  static bool hasDeliveryLocation(AddressDto? address) =>
      address != null &&
      address.addressLine1.trim().isNotEmpty &&
      BookingGeoUtils.hasValidCoords(address.latitude, address.longitude);

  static const missingDeliveryMessage =
      'Select a delivery address with a map pin before checkout.';

  static const pendingLabel = 'TBD';
  static const pendingHint =
      'Delivery fee will be calculated after your rider finds the items and uploads a photo at the store.';
  static const orderValuePendingHint =
      'No minimum order — item prices and total are confirmed after your rider finds the products.';

  static bool isManualOnlyCart({
    required bool hasStoreItems,
    required bool hasManualItems,
  }) {
    return hasManualItems && !hasStoreItems;
  }

  static bool hasManualItemsInCart({required bool hasManualItems}) =>
      hasManualItems;

  static bool isUncertainFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return false;
    if (meta['delivery_fee_uncertain'] == true) return true;
    final type = meta['order_type']?.toString().toLowerCase();
    return type == 'lesbuy_manual';
  }

  static bool isOrderValueUncertainFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return false;
    if (meta['order_value_uncertain'] == true) return true;
    if (meta['minimum_order_exempt'] == true) return true;
    return isUncertainFromMeta(meta);
  }

  /// LesPay wallet minimum — manual papabili has no minimum order value at checkout.
  static double walletMinimumAmount({
    required bool orderValueUncertain,
    required double checkoutTotal,
  }) {
    return orderValueUncertain ? 0 : checkoutTotal;
  }

  /// Do not charge wallet/digital at checkout when order value is still TBD.
  static double resolveCheckoutPayAmount({
    required bool orderValueUncertain,
    required double checkoutTotal,
    required double apiEffectiveTotal,
  }) {
    if (orderValueUncertain) return 0;
    return apiEffectiveTotal > 0 ? apiEffectiveTotal : checkoutTotal;
  }

  static bool isDeliveryFeePending({
    required Map<String, dynamic>? meta,
    required double deliveryFee,
  }) {
    return isUncertainFromMeta(meta) && deliveryFee <= 0;
  }

  static String formatDeliveryFee({
    required bool isUncertain,
    required double deliveryFee,
  }) {
    if (isUncertain && deliveryFee <= 0) return pendingLabel;
    return 'PHP ${deliveryFee.toStringAsFixed(2)}';
  }
}
