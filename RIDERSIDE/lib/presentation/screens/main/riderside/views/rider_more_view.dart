import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../screens/main/riderside/views/rider_mission_view.dart';
import '../../../../screens/main/riderside/views/rider_wallet_view.dart';
import '../../../../provider/theme_provider.dart';
import '../../../../screens/main/riderside/rider_language_screen.dart';
import '../../../../screens/main/riderside/rider_package_tier_screen.dart';

class RiderMoreView extends ConsumerWidget {
  const RiderMoreView({super.key});

  void _openSubScreen(
    BuildContext context, {
    required String title,
    required Widget body,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F2D82),
              ),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: body,
        ),
      ),
    );
  }

  void _openLanguageScreen(BuildContext context, AppLanguage lang) {
    _openSubScreen(
      context,
      title: AppLocalization.translate('language', lang),
      body: const RiderLanguageView(),
    );
  }

  void _openPackageTierScreen(BuildContext context, AppLanguage lang) {
    _openSubScreen(
      context,
      title: AppLocalization.translate('package_tier', lang),
      body: const RiderPackageTierView(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hp,
        ResponsiveUtils.spacing(context, 16),
        hp,
        ResponsiveUtils.scrollBottomPaddingForBottomNav(context),
      ),
      children: [
        Text(
          AppLocalization.translate('more', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 22),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _SectionTitle(title: AppLocalization.translate('work_section', lang)),
        _MoreTile(
          icon: Icons.account_balance_wallet_outlined,
          label: AppLocalization.translate('wallet', lang),
          subtitle: 'Balance, top-up, withdraw',
          onTap: () => _openSubScreen(
            context,
            title: AppLocalization.translate('wallet', lang),
            body: const RiderWalletView(),
          ),
        ),
        _MoreTile(
          icon: Icons.payments_outlined,
          label: AppLocalization.translate('earnings', lang),
          subtitle: 'Today, week, and trip breakdown',
          onTap: () => AppRouter.push(context, MainRoutes.riderEarnings),
        ),
        _MoreTile(
          icon: Icons.insights,
          label: 'Earnings Insights',
          subtitle: 'Charts, projections, and key metrics',
          onTap: () => AppRouter.push(context, MainRoutes.riderEarningsInsights),
        ),
        _MoreTile(
          icon: Icons.star_outline,
          label: AppLocalization.translate('missions', lang),
          subtitle: 'Complete missions and earn rewards',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RiderMissionView(includeBottomNavPadding: false),
            ),
          ),
        ),
        _MoreTile(
          icon: Icons.star_half_outlined,
          label: AppLocalization.translate('my_rating', lang),
          subtitle: 'Overall rating, reviews, and performance',
          onTap: () => AppRouter.push(context, MainRoutes.riderRating),
        ),
        _MoreTile(
          icon: Icons.directions_bike_outlined,
          label: AppLocalization.translate('my_vehicles', lang),
          subtitle: 'Manage your registered vehicles',
          onTap: () => AppRouter.push(context, MainRoutes.riderVehicleManagement),
        ),
        _MoreTile(
          icon: Icons.schedule,
          label: AppLocalization.translate('scheduled_availability', lang),
          subtitle: 'Set your on/off duty times',
          onTap: () => AppRouter.push(context, MainRoutes.riderSchedule),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _SectionTitle(title: AppLocalization.translate('settings', lang)),
        Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark;
            return _MoreTileWithSwitch(
              icon: Icons.dark_mode,
              label: 'Dark Mode',
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            );
          },
        ),
        _MoreTile(
          icon: Icons.language,
          label: AppLocalization.translate('language', lang),
          subtitle: AppLocalization.translate('english_filipino', lang),
          onTap: () => _openLanguageScreen(context, lang),
        ),
        _MoreTile(
          icon: Icons.workspace_premium_outlined,
          label: AppLocalization.translate('package_tier', lang),
          subtitle: AppLocalization.translate('view_tier_benefits', lang),
          onTap: () => _openPackageTierScreen(context, lang),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 13),
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _MoreTileWithSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MoreTileWithSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF5F2D82), size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: isDark ? Colors.white : null,
          ),
        ),
        value: value,
        activeThumbColor: const Color(0xFF5F2D82),
        activeTrackColor: const Color(0xFF5F2D82).withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF5F2D82), size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: isDark ? Colors.white : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.white54 : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
