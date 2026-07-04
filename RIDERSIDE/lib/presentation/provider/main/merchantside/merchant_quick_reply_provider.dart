import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Predefined quick reply templates for merchants.
final merchantQuickReplyTemplatesProvider = Provider<List<String>>((ref) {
  return const [
    'Your order is being prepared! 🍳',
    'Almost ready! 5 minutes left ⏱️',
    'Order is ready for pickup! 📦',
    'Sorry for the delay, we\'re working on it! 🙏',
  ];
});
