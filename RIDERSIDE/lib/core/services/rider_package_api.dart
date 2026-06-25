import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';

double? _parseAmount(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class RiderPackageOption {
  final String tier;
  final String label;
  final double? commissionRate;
  final double? commissionPercent;
  final String profitShareLabel;
  final double? oneTimePrice;
  final bool isCurrent;
  final bool isUpgradeable;

  const RiderPackageOption({
    required this.tier,
    required this.label,
    this.commissionRate,
    this.commissionPercent,
    required this.profitShareLabel,
    this.oneTimePrice,
    required this.isCurrent,
    required this.isUpgradeable,
  });

  factory RiderPackageOption.fromJson(Map<String, dynamic> json) {
    return RiderPackageOption(
      tier: json['tier']?.toString() ?? 'basic',
      label: json['label']?.toString() ?? 'Basic',
      commissionRate: _parseAmount(json['commission_rate']),
      commissionPercent: _parseAmount(json['commission_percent']),
      profitShareLabel: json['profit_share_label']?.toString() ?? '',
      oneTimePrice: _parseAmount(json['one_time_price']),
      isCurrent: json['is_current'] == true,
      isUpgradeable: json['is_upgradeable'] == true,
    );
  }

  String get priceLabel {
    final price = oneTimePrice;
    if (price == null) return 'Employer assigned';
    if (price <= 0) return 'Free';
    return '₱${_formatAmount(price)} one-time';
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class RiderPackageCatalog {
  final String currentTier;
  final String currentLabel;
  final List<RiderPackageOption> packages;

  const RiderPackageCatalog({
    required this.currentTier,
    required this.currentLabel,
    required this.packages,
  });

  factory RiderPackageCatalog.fromJson(Map<String, dynamic> json) {
    final rawPackages = json['packages'];
    final packages = rawPackages is List
        ? rawPackages
            .whereType<Map>()
            .map((e) => RiderPackageOption.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <RiderPackageOption>[];

    return RiderPackageCatalog(
      currentTier: json['current_tier']?.toString() ?? 'basic',
      currentLabel: json['current_label']?.toString() ?? 'Basic',
      packages: packages,
    );
  }
}

class RiderPackageUpgradeCheckout {
  final String status;
  final String? invoiceId;
  final String? invoiceUrl;
  final double amount;
  final String targetTier;
  final String targetLabel;
  final String? packageTier;
  final double? commissionRate;

  const RiderPackageUpgradeCheckout({
    required this.status,
    this.invoiceId,
    this.invoiceUrl,
    required this.amount,
    required this.targetTier,
    required this.targetLabel,
    this.packageTier,
    this.commissionRate,
  });

  bool get isCompleted => status == 'completed';
  bool get needsPayment => status == 'pending_payment';
}

class RiderPackageApi {
  RiderPackageApi._();

  static Future<RiderPackageCatalog> fetchCatalog() async {
    final response = await ApiService.dio.get(ApiConstants.driverPackageTiers);
    final body = response.data;
    final data = body is Map ? (body['data'] ?? body) : body;
    if (data is! Map) {
      throw Exception('Invalid package tier response');
    }
    return RiderPackageCatalog.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<RiderPackageUpgradeCheckout> startUpgrade({
    required String tier,
    required String paymentMethod,
  }) async {
    final response = await ApiService.dio.post(
      ApiConstants.driverPackageUpgrade,
      data: {
        'tier': tier,
        'payment_method': paymentMethod,
      },
    );
    return _checkoutFromResponse(response.data);
  }

  static Future<RiderPackageUpgradeCheckout> confirmUpgrade({
    required String invoiceId,
  }) async {
    final response = await ApiService.dio.post(
      ApiConstants.driverPackageUpgrade,
      data: {'xendit_invoice_id': invoiceId},
    );
    return _checkoutFromResponse(response.data);
  }

  static RiderPackageUpgradeCheckout _checkoutFromResponse(dynamic raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw['data'] ?? raw) : <String, dynamic>{};

    final commissionRate = _parseAmount(
      map['commission_rate'] ?? map['driver_profile']?['commission_rate'],
    );

    return RiderPackageUpgradeCheckout(
      status: map['status']?.toString() ?? 'completed',
      invoiceId: map['invoice_id']?.toString(),
      invoiceUrl: map['invoice_url']?.toString(),
      amount: _parseAmount(map['amount']) ?? 0,
      targetTier: map['target_tier']?.toString() ?? map['package_tier']?.toString() ?? '',
      targetLabel: map['target_label']?.toString() ?? map['package_label']?.toString() ?? '',
      packageTier: map['package_tier']?.toString(),
      commissionRate: commissionRate,
    );
  }
}
