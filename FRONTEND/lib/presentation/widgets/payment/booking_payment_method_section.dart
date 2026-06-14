import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/main/lespay/lespay_provider.dart';
import 'payment_method_selector.dart';

/// Payment method picker for booking flows (LesGo, LesRide, LesEat, LesBuy).
class BookingPaymentMethodSection extends ConsumerStatefulWidget {
  const BookingPaymentMethodSection({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.enabled = true,
    this.minimumAmount,
  });

  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final bool enabled;
  final double? minimumAmount;

  @override
  ConsumerState<BookingPaymentMethodSection> createState() =>
      _BookingPaymentMethodSectionState();
}

class _BookingPaymentMethodSectionState
    extends ConsumerState<BookingPaymentMethodSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lespayProvider.notifier).refreshBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);

    return PaymentMethodSelector(
      selectedMethod: widget.selectedMethod,
      onMethodChanged: widget.onMethodChanged,
      enabled: widget.enabled,
      showWallet: true,
      showDigitalPayments: true,
      walletBalance: lespayState.balance,
      walletBalanceVisible: lespayState.balanceVisible,
      minimumWalletAmount: widget.minimumAmount,
    );
  }
}
