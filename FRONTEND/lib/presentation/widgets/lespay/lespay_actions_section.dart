import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/app_localization.dart';
import 'top_up_dialog.dart';
import '../../../core/utils/responsive_utils.dart';

class LespayActionsSection extends ConsumerWidget {
  const LespayActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionConfig(
        icon: Icons.add_circle_rounded,
        iconBg: const Color(0xFF10B981),
        title: tr(context, 'top_up'),
        subtitle: tr(context, 'add_funds_with_card'),
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => TopUpDialog(parentContext: context),
          );
        },
      ),
      _ActionConfig(
        icon: Icons.credit_card_rounded,
        iconBg: const Color(0xFF3B82F6),
        title: tr(context, 'payment_methods'),
        subtitle: tr(context, 'manage_cards_wallets'),
        onTap: () => AppRouter.push(context, MainRoutes.paymentMethods),
      ),
      _ActionConfig(
        icon: Icons.qr_code_scanner_rounded,
        iconBg: const Color(0xFF8B5CF6),
        title: tr(context, 'qr_pay'),
        subtitle: tr(context, 'pay_via_qr_ph'),
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => TopUpDialog(
              parentContext: context,
              purpose: TopUpPurpose.qrPay,
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.isDesktop(context) ? 64 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'quick_actions'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.surface(context, Colors.white),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side:  BorderSide(color: AppColors.border(context, Color(0xFFEDE7F2))),
            ),
            child: Column(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 76,
                      endIndent: 18,
                      color: Color(0xFFF0EBF4),
                    ),
                  _ActionCard(config: actions[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionConfig {
  final IconData icon;
  final Color iconBg;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionConfig({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionConfig config;
  const _ActionCard({required this.config});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: config.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.iconBg.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: config.iconBg, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style:  TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.foreground(context, Color(0xFF897D91)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
           Icon(
            Icons.chevron_right_rounded,
            color: AppColors.foreground(context, Color(0xFFB0A1BB)),
            size: 21,
          ),
        ],
      ),
    ),
  );
}
