class XenditInvoiceDto {
  final String id;
  final String externalId;
  final double amount;
  final String currency;
  final String status;
  final String? invoiceUrl;
  final String? paidAt;

  const XenditInvoiceDto({
    required this.id,
    required this.externalId,
    required this.amount,
    required this.currency,
    required this.status,
    this.invoiceUrl,
    this.paidAt,
  });

  factory XenditInvoiceDto.fromJson(Map<String, dynamic> json) {
    return XenditInvoiceDto(
      id: json['id']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'PHP',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      invoiceUrl: json['invoice_url']?.toString(),
      paidAt: json['paid_at']?.toString(),
    );
  }

  bool get isPaid => status == 'PAID' || status == 'SETTLED';
  bool get isExpired => status == 'EXPIRED';

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
