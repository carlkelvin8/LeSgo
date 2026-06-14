import 'package:flutter/material.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';

class RiderProfileSettingsSection extends StatelessWidget {
  const RiderProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & Support',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 15),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Change password',
            route: MainRoutes.riderChangePassword,
          ),
          _SettingsTile(
            icon: Icons.security,
            label: 'Security & 2FA',
            route: MainRoutes.riderSecurity,
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Document verification',
            route: MainRoutes.riderDocuments,
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            label: 'Offers & vouchers',
            route: MainRoutes.riderOffers,
          ),
          _SettingsTile(
            icon: Icons.stars_outlined,
            label: 'Loyalty rewards',
            route: MainRoutes.riderLoyalty,
          ),
          _SettingsTile(
            icon: Icons.group_add_outlined,
            label: 'Referral program',
            route: MainRoutes.riderReferral,
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'FAQs',
            route: MainRoutes.riderFaqs,
          ),
          _SettingsTile(
            icon: Icons.emergency_outlined,
            label: 'Safety & SOS',
            route: MainRoutes.riderSafety,
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            route: MainRoutes.riderNotifications,
          ),
          _SettingsTile(
            icon: Icons.tune,
            label: 'Notification settings',
            route: MainRoutes.riderNotificationSettings,
          ),
          _SettingsTile(
            icon: Icons.smart_toy_outlined,
            label: 'AI Support Chat',
            route: MainRoutes.riderCustomerServiceChat,
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            label: 'Support tickets',
            route: MainRoutes.riderSupportTickets,
          ),
          _SettingsTile(
            icon: Icons.person_off_outlined,
            label: 'Deactivate account',
            route: MainRoutes.riderDeactivateAccount,
            isDestructive: true,
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: 'Delete account permanently',
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
