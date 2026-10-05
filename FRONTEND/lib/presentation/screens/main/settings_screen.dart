import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../provider/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.grey[50]!),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.fontSize(context, 20),
            color: AppColors.foreground(context, Colors.black87),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          tr(context, 'settings'),
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: AppColors.foreground(context, Colors.black87),
            fontFamily: 'TT Fors',
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          _SettingsSection(
            title: tr(context, 'account'),
            items: [
              _SettingsItem(
                icon: Icons.location_on_outlined,
                title: tr(context, 'saved_addresses'),
                subtitle: 'Manage your delivery addresses',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.addressManagement),
              ),
              _SettingsItem(
                icon: Icons.person_outline,
                title: tr(context, 'profile_information'),
                subtitle: 'Update your personal details',
                onTap: () => AppRouter.push(context, MainRoutes.profile),
              ),
              _SettingsItem(
                icon: Icons.security,
                title: tr(context, 'security'),
                subtitle: '2FA, biometrics, and login activity',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.securitySettings),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: tr(context, 'change_password'),
                subtitle: 'Update your login password',
                onTap: () => AppRouter.push(context, MainRoutes.changePassword),
              ),
              _SettingsItem(
                icon: Icons.person_off_outlined,
                title: tr(context, 'deactivate_account'),
                subtitle: 'Temporarily disable your account',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.deactivateAccount),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _SettingsSection(
            title: tr(context, 'app_section'),
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notification center',
                subtitle: 'View order updates and offers',
                onTap: () => AppRouter.push(context, MainRoutes.notifications),
              ),
              _SettingsItem(
                icon: Icons.notifications_active_outlined,
                title: tr(context, 'notification_settings'),
                subtitle: 'Promotions and order alert preferences',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.notificationSettings),
              ),
              _SettingsItem(
                icon: Icons.language_outlined,
                title: tr(context, 'language'),
                subtitle: 'English or Filipino',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.languageSettings),
              ),
              _SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: tr(context, 'dark_mode'),
                subtitle: isDark ? 'Dark theme enabled' : 'Light theme',
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (value) =>
                      ref.read(themeModeProvider.notifier).setDarkMode(value),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _SettingsSection(
            title: tr(context, 'support'),
            items: [
              _SettingsItem(
                icon: Icons.smart_toy_outlined,
                title: tr(context, 'lesgo_support'),
                subtitle: 'Chat with our customer service team',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.customerServiceChat),
              ),
              _SettingsItem(
                icon: Icons.confirmation_number_outlined,
                title: tr(context, 'support_tickets'),
                subtitle: 'Get help from our support team',
                onTap: () => AppRouter.push(context, MainRoutes.supportTickets),
              ),
              _SettingsItem(
                icon: Icons.badge_outlined,
                title: tr(context, 'document_verification'),
                subtitle: 'Submit and track your documents',
                onTap: () =>
                    AppRouter.push(context, MainRoutes.documentVerification),
              ),
              _SettingsItem(
                icon: Icons.help_outline,
                title: tr(context, 'faqs'),
                subtitle: 'Frequently asked questions',
                onTap: () => AppRouter.push(context, MainRoutes.faqs),
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: tr(context, 'about'),
                subtitle: 'App information and version',
                onTap: () => AppRouter.push(context, MainRoutes.about),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground(context, Colors.grey[600]!),
              fontFamily: 'TT Fors',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.border(context, Colors.grey[200]!),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent(
            context,
            Color(0xFF5F2D82),
          ).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.accent(context, Color(0xFF5F2D82)),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 15),
          fontWeight: FontWeight.w600,
          color: AppColors.foreground(context, Colors.black87),
          fontFamily: 'TT Fors',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 13),
          color: AppColors.foreground(context, Colors.grey[600]!),
          fontFamily: 'TT Fors',
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.foreground(context, Colors.grey[400]!),
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
