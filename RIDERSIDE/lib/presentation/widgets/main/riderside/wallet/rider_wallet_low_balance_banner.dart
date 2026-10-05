import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/rider_wallet_policy.dart';
import '../../../../provider/main/riderside/rider_main_nav_provider.dart';

class RiderWalletLowBalanceBanner extends ConsumerStatefulWidget {
  final double balance;

  const RiderWalletLowBalanceBanner({
    super.key,
    required this.balance,
  });

  @override
  ConsumerState<RiderWalletLowBalanceBanner> createState() =>
      _RiderWalletLowBalanceBannerState();
}

class _RiderWalletLowBalanceBannerState
    extends ConsumerState<RiderWalletLowBalanceBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = RiderWalletPolicy.lowBalanceWarningMessage(widget.balance);
    if (message.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(riderNavProvider.notifier).navigateTo(RiderNavType.more);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2A1A05),
                      const Color(0xFF1F1204),
                    ]
                  : [
                      const Color(0xFFFFF8ED),
                      const Color(0xFFFFF3E0),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(
                  alpha: .35 + .20 * _pulse.value),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B)
                    .withValues(alpha: .10 + .08 * _pulse.value),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: .15 + .08 * _pulse.value),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    // Pulsing dot
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF87171),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF87171).withValues(
                                  alpha: .50 + .30 * _pulse.value),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low wallet balance',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFB45309),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFFD97706).withValues(alpha: .80)
                            : const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Top-up arrow chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: .35),
                    width: .8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Top up',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
