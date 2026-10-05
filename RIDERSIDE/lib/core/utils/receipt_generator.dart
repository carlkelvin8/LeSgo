import 'package:intl/intl.dart';

class ReceiptGenerator {
  static String generateEarningReceipt({
    required int orderId,
    required String serviceName,
    required double earnings,
    required DateTime? completedAt,
    String? pickupAddress,
    String? dropoffAddress,
    String driverName = '',
    String vehiclePlate = '',
  }) {
    final dateStr = completedAt != null
        ? DateFormat('MMMM d, yyyy h:mm a').format(completedAt)
        : DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('       LESGO RIDER - RECEIPT');
    buffer.writeln('====================================');
    buffer.writeln('');
    buffer.writeln('Order #: $orderId');
    buffer.writeln('Service: $serviceName');
    buffer.writeln('Date: $dateStr');
    if (driverName.isNotEmpty) buffer.writeln('Driver: $driverName');
    if (vehiclePlate.isNotEmpty) buffer.writeln('Vehicle: $vehiclePlate');
    buffer.writeln('');
    if (pickupAddress != null) buffer.writeln('Pickup: $pickupAddress');
    if (dropoffAddress != null) buffer.writeln('Dropoff: $dropoffAddress');
    buffer.writeln('');
    buffer.writeln('------------------------------------');
    buffer.writeln('Earnings: PHP ${earnings.toStringAsFixed(2)}');
    buffer.writeln('------------------------------------');
    buffer.writeln('');
    buffer.writeln('Thank you for riding with LeSGo!');
    buffer.writeln('====================================');
    return buffer.toString();
  }

  static String generateEarningSummaryReceipt({
    required String period,
    required double totalEarnings,
    required int completedTrips,
    required double averagePerTrip,
    required List<Map<String, dynamic>> entries,
  }) {
    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final buffer = StringBuffer();

    buffer.writeln('====================================');
    buffer.writeln('    LESGO EARNINGS SUMMARY');
    buffer.writeln('====================================');
    buffer.writeln('');
    buffer.writeln('Period: $period');
    buffer.writeln('Generated: $dateStr');
    buffer.writeln('');
    buffer.writeln('------------------------------------');
    buffer.writeln('TOTAL EARNINGS: PHP ${totalEarnings.toStringAsFixed(2)}');
    buffer.writeln('Completed Trips: $completedTrips');
    buffer.writeln('Avg per Trip: PHP ${averagePerTrip.toStringAsFixed(2)}');
    buffer.writeln('------------------------------------');
    buffer.writeln('');
    buffer.writeln('TRIP DETAILS:');
    buffer.writeln('');

    for (final entry in entries) {
      final orderId = entry['order_id'] ?? '-';
      final serviceName = entry['service_name'] ?? 'Order';
      final earnings = entry['earnings'] ?? 0.0;
      final date = entry['completed_at'] != null
          ? DateFormat('MMM d, h:mm a').format(entry['completed_at'] as DateTime)
          : 'N/A';
      buffer.writeln('  #$orderId - $serviceName');
      buffer.writeln('  Date: $date');
      buffer.writeln('  Earned: PHP ${(earnings as double).toStringAsFixed(2)}');
      buffer.writeln('');
    }

    buffer.writeln('====================================');
    buffer.writeln('Thank you for riding with LeSGo!');
    buffer.writeln('====================================');
    return buffer.toString();
  }

  static String generateHtmlReceipt({
    required int orderId,
    required String serviceName,
    required double earnings,
    required DateTime? completedAt,
    String? pickupAddress,
    String? dropoffAddress,
  }) {
    final dateStr = completedAt != null
        ? DateFormat('MMMM d, yyyy h:mm a').format(completedAt)
        : DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now());

    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><style>
body { font-family: sans-serif; padding: 20px; color: #333; }
.receipt { max-width: 400px; margin: auto; border: 1px solid #ddd; border-radius: 12px; padding: 24px; }
.header { text-align: center; color: #5F2D82; margin-bottom: 20px; }
.header h1 { margin: 0; font-size: 20px; }
.header p { margin: 4px 0 0; color: #888; font-size: 12px; }
.details { margin: 16px 0; }
.row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
.label { color: #888; font-size: 13px; }
.value { font-weight: 600; font-size: 13px; }
.total { display: flex; justify-content: space-between; padding: 12px 0; margin-top: 8px; border-top: 2px solid #5F2D82; }
.total .label { font-size: 16px; font-weight: 700; color: #333; }
.total .value { font-size: 18px; font-weight: 800; color: #5F2D82; }
.footer { text-align: center; margin-top: 20px; color: #aaa; font-size: 11px; }
</style></head>
<body>
<div class="receipt">
<div class="header">
<h1>LeSGo Rider</h1>
<p>Earning Receipt</p>
</div>
<div class="details">
<div class="row"><span class="label">Order #</span><span class="value">$orderId</span></div>
<div class="row"><span class="label">Service</span><span class="value">$serviceName</span></div>
<div class="row"><span class="label">Completed</span><span class="value">$dateStr</span></div>
${pickupAddress != null ? '<div class="row"><span class="label">Pickup</span><span class="value">$pickupAddress</span></div>' : ''}
${dropoffAddress != null ? '<div class="row"><span class="label">Dropoff</span><span class="value">$dropoffAddress</span></div>' : ''}
</div>
<div class="total">
<span class="label">Earnings</span>
<span class="value">PHP ${earnings.toStringAsFixed(2)}</span>
</div>
<div class="footer">
<p>Thank you for riding with LeSGo!</p>
</div>
</div>
</body>
</html>
''';
  }
}
