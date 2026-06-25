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
    if (tier == 'employee') return 'employee';
    return 'basic';
  }

  static String labelForPackage(String? packageTier) {
    switch (normalizePackageTier(packageTier)) {
      case 'advance':
        return 'Advance';
      case 'pro':
        return 'Pro';
      case 'employee':
        return 'Employee';
      case 'basic':
      default:
        return 'Basic';
    }
  }

  static String profitShareLabel(String? packageTier) {
    switch (normalizePackageTier(packageTier)) {
      case 'advance':
        return '80/20 profit share (you keep 80%)';
      case 'pro':
        return '90/10 profit share (you keep 90%)';
      case 'employee':
        return 'Fixed daily salary';
      case 'basic':
      default:
        return '70/30 profit share (you keep 70%)';
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
