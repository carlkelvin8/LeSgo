import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/dark_aware_colors.dart';
import '../../../provider/auth/registration_fee_provider.dart';

/// Heads-up for annual partners whose renewal falls due within 30 days.
///
/// Renewal can only be paid once it opens (the fee is "already paid" until
/// then), so this is informational: it tells the owner the date and amount to
/// prepare. Renders nothing for exempt partners, riders, or when not due soon.
class MerchantRenewalBanner extends ConsumerStatefulWidget {
  const MerchantRenewalBanner({super.key});

  @override
  ConsumerState<MerchantRenewalBanner> createState() =>
      _MerchantRenewalBannerState();
}

class _MerchantRenewalBannerState extends ConsumerState<MerchantRenewalBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(registrationFeeProvider.notifier).loadStatus(silent: true);
      }
    });
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(registrationFeeProvider.select((s) => s.status));
    if (status == null || !status.renewalDueSoon()) {
      return const SizedBox.shrink();
    }

    final due = status.renewalDate!;
    final days = status.daysUntilRenewal() ?? 0;
    final dateLabel = '${_months[due.month - 1]} ${due.day}, ${due.year}';
    final when = days == 0
        ? context.tr('today')
        : days == 1
            ? context.tr('tomorrow')
            : '${context.tr('in')} $days ${context.tr('days')}';

    return Container(
      key: const ValueKey('merchant-renewal-banner'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surf(const Color(0xFFFFF4E5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.brd(const Color(0xFFFFB74D))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_repeat_rounded,
              color: context.acc(const Color(0xFFEF6C00)), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('Annual renewal due')} $when',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.txt(const Color(0xFF4E342E)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.tr('Your annual renewal is due on')} $dateLabel '
                  '(${status.amountLabel}). '
                  '${context.tr('Please prepare the payment so your shop stays open.')}',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: context.sub(const Color(0xFF6D4C41)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
