/// Parses LesGo wallet API list/object payloads for RIDERSIDE wallet features.
class WalletResponseParser {
  WalletResponseParser._();

  static List<dynamic> parseListBody(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
    }
    return [];
  }

  static Map<String, dynamic>? extractInvoiceMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['invoice_id'] != null || dataMap['invoice_url'] != null) {
        return dataMap;
      }
      final nested = dataMap['invoice'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    if (map['invoice_id'] != null || map['invoice_url'] != null) {
      return map;
    }
    return null;
  }

  static double computeTotalDeposits(List<dynamic> txList) {
    var topUpTotal = 0.0;
    var allCredits = 0.0;

    for (final raw in txList) {
      if (raw is! Map) continue;
      final tx = Map<String, dynamic>.from(raw);
      if (tx['type']?.toString() != 'credit') continue;

      final amount = _toDouble(tx['amount']);
      allCredits += amount;

      final desc = (tx['description']?.toString() ?? '').toLowerCase();
      if (desc.contains('top-up') ||
          desc.contains('top up') ||
          desc.contains('topup')) {
        topUpTotal += amount;
      }
    }

    return topUpTotal > 0 ? topUpTotal : allCredits;
  }

  static Map<String, dynamic> parseMeta(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static String normalizePhilippineMobile(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('63') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.startsWith('9') && digits.length == 10) {
      digits = '0$digits';
    }
    return digits;
  }

  static bool isInvoicePaidStatus(String? status) {
    final s = status?.toLowerCase();
    return s == 'paid' || s == 'completed' || s == 'settled';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
