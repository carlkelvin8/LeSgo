/// Mirrors the `registration_fee` object the API attaches to rider/merchant
/// user responses and to the `/v1/registration-fee/status` endpoint.
class RegistrationFeeStatus {
  final bool requiresFee;
  final bool paymentWaived;
  final bool canAccessApp;
  final bool isActive;
  final bool canAccessOperationalFeatures;
  final String paymentStatus;
  final String applicationStatus;
  final double? amount;
  final String billingPeriod;
  final String currency;
  final String? displayStatus;
  final String? accountStatus;
  final String? checkoutUrl;
  final String? paymongoCheckoutId;
  final String? paymongoReference;
  final String? paymentDate;
  final String? waivedAt;
  final String? waiverReason;
  final String? approvedAt;
  final String? activatedAt;
  final String? failureReason;

  /// When the current annual fee period ends (null for riders, exempt partners
  /// and fees that are not yet paid or waived).
  final String? registrationExpiresAt;

  /// Long-time partners exempt from the annual renewal.
  final bool isGrandfathered;

  const RegistrationFeeStatus({
    required this.requiresFee,
    required this.paymentWaived,
    required this.canAccessApp,
    required this.isActive,
    required this.canAccessOperationalFeatures,
    required this.paymentStatus,
    required this.applicationStatus,
    this.amount,
    this.billingPeriod = 'one_time',
    this.currency = 'PHP',
    this.displayStatus,
    this.accountStatus,
    this.checkoutUrl,
    this.paymongoCheckoutId,
    this.paymongoReference,
    this.paymentDate,
    this.waivedAt,
    this.waiverReason,
    this.approvedAt,
    this.activatedAt,
    this.failureReason,
    this.registrationExpiresAt,
    this.isGrandfathered = false,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isWaived => paymentStatus == 'waived';
  bool get isPendingPayment => paymentStatus == 'pending';
  bool get isUnpaid => paymentStatus == 'unpaid';
  bool get isRejected => applicationStatus == 'rejected';
  bool get isApproved => applicationStatus == 'approved';
  bool get isApplicationPending => applicationStatus == 'pending';

  /// Fee is satisfied when paid or waived by an admin.
  bool get isFeeSatisfied => isPaid || isWaived;

  /// Full activation: approved AND (paid OR waived).
  bool get shouldBeActive => isApproved && isFeeSatisfied;

  /// The user must complete payment before using the app.
  bool get needsPayment =>
      !isWaived && !isPaid && paymentStatus != 'pending' &&
      applicationStatus != 'rejected';

  bool get awaitingApprovalAfterPayment =>
      isFeeSatisfied && !isApproved;

  double get amountValue => amount ?? 0;

  /// Renewal reminder window, matching the backend's 30-day push.
  static const int renewalReminderDays = 30;

  DateTime? get renewalDate {
    final raw = registrationExpiresAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Whole days until the annual renewal falls due (0 = today), or null.
  int? daysUntilRenewal({DateTime? now}) {
    final due = renewalDate;
    if (due == null) return null;
    final today = now ?? DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(due.year, due.month, due.day);
    return b.difference(a).inDays;
  }

  /// True when an annual partner is within the reminder window and still active.
  bool renewalDueSoon({DateTime? now}) {
    if (billingPeriod != 'annual' || isGrandfathered || !isFeeSatisfied) {
      return false;
    }
    final days = daysUntilRenewal(now: now);
    return days != null && days >= 0 && days <= renewalReminderDays;
  }

  String get amountLabel =>
      '${currency.isEmpty ? 'PHP' : currency} ${amountValue.toStringAsFixed(2)}';

  String get resolvedDisplayStatus =>
      displayStatus ??
      (shouldBeActive
          ? 'Active'
          : isWaived
              ? 'Registration fee waived'
              : isPaid
                  ? 'Payment received — awaiting approval'
                  : 'Restricted — registration fee required');

  static RegistrationFeeStatus? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);

    return RegistrationFeeStatus(
      requiresFee: _asBool(map['requires_fee'], true),
      paymentWaived: _asBool(map['payment_waived'], false),
      canAccessApp: _asBool(map['can_access_app'], false),
      isActive: _asBool(map['is_active'], false),
      canAccessOperationalFeatures:
          _asBool(map['can_access_operational_features'], false),
      paymentStatus: map['payment_status']?.toString() ?? 'unpaid',
      applicationStatus: map['application_status']?.toString() ?? 'pending',
      amount: _asDouble(map['amount']),
      billingPeriod: map['billing_period']?.toString() ?? 'one_time',
      currency: map['currency']?.toString() ?? 'PHP',
      displayStatus: map['display_status']?.toString(),
      accountStatus: map['account_status']?.toString(),
      checkoutUrl: map['checkout_url']?.toString(),
      paymongoCheckoutId: map['paymongo_checkout_id']?.toString(),
      paymongoReference: map['paymongo_reference']?.toString(),
      paymentDate: map['payment_date']?.toString(),
      waivedAt: map['waived_at']?.toString(),
      waiverReason: map['waiver_reason']?.toString(),
      approvedAt: map['approved_at']?.toString(),
      activatedAt: map['activated_at']?.toString(),
      failureReason: map['failure_reason']?.toString(),
      registrationExpiresAt: map['registration_expires_at']?.toString(),
      isGrandfathered: _asBool(map['is_grandfathered'], false),
    );
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}