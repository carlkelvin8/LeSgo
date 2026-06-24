import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/app_localization.dart';

class RiderProfileSettingsSection extends ConsumerWidget {
  const RiderProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hp = ResponsiveUtils.horizontalPadding(context);
    final lang = ref.watch(appLanguageProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.translate('settings_support', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 15),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: AppLocalization.translate('change_password', lang),
            route: MainRoutes.riderChangePassword,
          ),
          _SettingsTile(
            icon: Icons.security,
            label: AppLocalization.translate('security', lang),
            route: MainRoutes.riderSecurity,
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: AppLocalization.translate('document_verification', lang),
            route: MainRoutes.riderDocuments,
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            label: AppLocalization.translate('offers_vouchers', lang),
            route: MainRoutes.riderOffers,
          ),
          _SettingsTile(
            icon: Icons.stars_outlined,
            label: AppLocalization.translate('loyalty_rewards_short', lang),
            route: MainRoutes.riderLoyalty,
          ),
          _SettingsTile(
            icon: Icons.group_add_outlined,
            label: AppLocalization.translate('referral_program', lang),
            route: MainRoutes.riderReferral,
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: AppLocalization.translate('faqs', lang),
            route: MainRoutes.riderFaqs,
          ),
          _SettingsTile(
            icon: Icons.emergency_outlined,
            label: AppLocalization.translate('safety_sos', lang),
            route: MainRoutes.riderSafety,
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: AppLocalization.translate('notifications', lang),
            route: MainRoutes.riderNotifications,
          ),
          _SettingsTile(
            icon: Icons.tune,
            label: AppLocalization.translate('notification_settings', lang),
            route: MainRoutes.riderNotificationSettings,
          ),
          _SettingsTile(
            icon: Icons.smart_toy_outlined,
            label: AppLocalization.translate('ai_support_chat', lang),
            route: MainRoutes.riderCustomerServiceChat,
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            label: AppLocalization.translate('support_tickets', lang),
            route: MainRoutes.riderSupportTickets,
          ),
          _SettingsTile(
            icon: Icons.person_off_outlined,
            label: AppLocalization.translate('deactivate_account', lang),
            route: MainRoutes.riderDeactivateAccount,
            isDestructive: true,
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: AppLocalization.translate('delete_account_permanently', lang),
            route: MainRoutes.riderDeleteAccount,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.route,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade700 : const Color(0xFF5F2D82);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade700 : Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () => AppRouter.push(context, route),
    );
  }
}
