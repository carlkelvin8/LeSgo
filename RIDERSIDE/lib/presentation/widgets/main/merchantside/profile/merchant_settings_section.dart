import 'package:flutter/material.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';

class MerchantSettingsSection extends StatelessWidget {
  const MerchantSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        _SettingsTile(
          icon: Icons.support_agent_outlined,
          label: 'Admin support chat',
          route: MainRoutes.riderCustomerServiceChat,
        ),
        _SettingsTile(
          icon: Icons.security,
          label: 'Security & 2FA',
          route: MainRoutes.merchantSecurity,
        ),
        _SettingsTile(
          icon: Icons.help_outline,
          label: 'FAQs',
          route: MainRoutes.merchantFaqs,
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          route: MainRoutes.riderNotifications,
        ),
        _SettingsTile(
          icon: Icons.group_outlined,
          label: 'Staff Accounts',
          route: MainRoutes.merchantStaff,
        ),
        _SettingsTile(
          icon: Icons.print_outlined,
          label: 'Printer Settings',
          route: MainRoutes.merchantPrinterSettings,
        ),
        _SettingsTile(
          icon: Icons.person_off_outlined,
          label: 'Deactivate account',
          route: MainRoutes.merchantDeactivateAccount,
          isDestructive: true,
        ),
        _SettingsTile(
          icon: Icons.delete_forever_outlined,
          label: 'Delete account permanently',
          route: MainRoutes.merchantDeleteAccount,
          isDestructive: true,
        ),
      ],
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
