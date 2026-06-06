/// Rider package commission rates (mirrors admin panel / backend defaults).
class RiderCommissionUtils {
  RiderCommissionUtils._();

  static const basicRate = 0.70;
  static const advanceRate = 0.80;
  static const proRate = 0.90;

  static double rateForPackage(String? packageTier) {
    switch (normalizePackageTier(packageTier)) {
      case 'advance':
        return advanceRate;
      case 'pro':
        return proRate;
      case 'basic':
      default:
        return basicRate;
    }
  }

  static String normalizePackageTier(String? raw) {
    final tier = (raw ?? 'basic').trim().toLowerCase();
    if (tier == 'advance' || tier == 'advanced') return 'advance';
    if (tier == 'pro' || tier == 'pro_rider' || tier == 'professional') {
      return 'pro';
    }
    return 'basic';
  }

  static String labelForPackage(String? packageTier) {
    switch (normalizePackageTier(packageTier)) {
      case 'advance':
        return 'Advance';
      case 'pro':
        return 'Pro Rider';
      case 'basic':
      default:
        return 'Basic';
    }
  }

  static double earningsFromShipping({
    required double shippingFee,
    double? driverShare,
    String? packageTier,
  }) {
    if (driverShare != null && driverShare > 0) return driverShare;
    return shippingFee * rateForPackage(packageTier);
  }
}
