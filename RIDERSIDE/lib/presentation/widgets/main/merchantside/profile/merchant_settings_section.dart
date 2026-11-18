import '../../../../provider/auth/rider_auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/dark_aware_colors.dart';
import '../../../../provider/theme_provider.dart';
import '../../../../../core/utils/app_localization.dart';

class MerchantSettingsSection extends ConsumerWidget {
  const MerchantSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Settings & Support'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        const _DarkModeTile(),
        const _LanguageTile(),
        _SettingsTile(
          icon: Icons.support_agent_outlined,
          label: context.tr('Admin support chat'),
          route: MainRoutes.riderCustomerServiceChat,
        ),
        _SettingsTile(
          icon: Icons.security,
          label: context.tr('Security & 2FA'),
          route: MainRoutes.merchantSecurity,
        ),
        _SettingsTile(
          icon: Icons.help_outline,
          label: context.tr('FAQs'),
          route: MainRoutes.merchantFaqs,
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: context.tr('Notifications'),
          route: MainRoutes.riderNotifications,
        ),
        _SettingsTile(
          icon: Icons.storefront_outlined,
          label: context.tr('Branches & Pickup Points'),
          route: MainRoutes.merchantBranches,
        ),
        if (ref.watch(riderAuthProvider).user?.isStaff != true)
        _SettingsTile(
          icon: Icons.group_outlined,
          label: context.tr('Staff Accounts'),
          route: MainRoutes.merchantStaff,
        ),
        _SettingsTile(
          icon: Icons.print_outlined,
          label: context.tr('Printer Settings'),
          route: MainRoutes.merchantPrinterSettings,
        ),
        // Required by App Store Guideline 5.1.1(v): accounts created in-app
        // must be deletable in-app.
        _SettingsTile(
          icon: Icons.delete_forever_outlined,
          label: context.tr('Delete account'),
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
          color: isDestructive ? Colors.red.shade700 : context.txt(Colors.black87),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.sub(Colors.grey.shade400)),
      onTap: () => AppRouter.push(context, route),
    );
  }
}

/// Dark mode switch for the merchant app (same setting the rider app uses).
class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: context.acc(const Color(0xFF5F2D82)),
        size: 22,
      ),
      title: Text(
        context.tr('Dark mode'),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
          color: context.txt(Colors.black87),
        ),
      ),
      subtitle: Text(
        context.tr(isDark ? 'On' : 'Off'),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 12),
          color: context.sub(Colors.grey.shade600),
        ),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        activeTrackColor: const Color(0xFF8050AD),
        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
      ),
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

/// English / Filipino switch for the merchant app.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.translate_rounded,
        color: context.acc(const Color(0xFF5F2D82)),
        size: 22,
      ),
      title: Text(
        context.tr('Language'),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
          color: context.txt(Colors.black87),
        ),
      ),
      subtitle: Text(
        lang == AppLanguage.filipino ? 'Filipino' : 'English',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 12),
          color: context.sub(Colors.grey.shade600),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.sub(Colors.grey.shade400)),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in const [
                (AppLanguage.english, 'English'),
                (AppLanguage.filipino, 'Filipino'),
              ])
                ListTile(
                  title: Text(
                    option.$2,
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  trailing: option.$1 == lang
                      ? Icon(Icons.check_rounded,
                          color: sheetContext.acc(const Color(0xFF5F2D82)))
                      : null,
                  onTap: () {
                    ref.read(appLanguageProvider.notifier).setLanguage(option.$1);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
