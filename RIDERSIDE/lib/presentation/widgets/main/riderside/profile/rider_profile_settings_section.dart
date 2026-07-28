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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark ? Colors.white : null,
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
            icon: Icons.tune,
            label: AppLocalization.translate('notification_settings', lang),
            route: MainRoutes.riderNotificationSettings,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isDestructive
              ? Colors.red.shade700
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.grey.shade400),
      onTap: () => AppRouter.push(context, route),
    );
  }
}
