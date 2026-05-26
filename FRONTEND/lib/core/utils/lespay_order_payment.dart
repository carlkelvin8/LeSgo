import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/provider/main/lespay/lespay_provider.dart';

/// Updates LesPay balance after a successful wallet order.
Future<void> applyLesPayWalletDeduction(
  dynamic ref, {
  required String paymentMethod,
  required double amount,
}) async {
  if (paymentMethod != 'wallet' || amount <= 0) return;
  await ref.read(lespayProvider.notifier).syncAfterWalletOrder(amount);
}
