import 'package:flutter/material.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../screens/main/riderside/views/rider_mission_view.dart';
import '../../../../screens/main/riderside/views/rider_wallet_view.dart';

class RiderMoreView extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hp,
        ResponsiveUtils.spacing(context, 16),
        hp,
        ResponsiveUtils.scrollBottomPaddingForBottomNav(context),
      ),
      children: [
        Text(
          'More',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 22),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _SectionTitle(title: 'Work'),
        _MoreTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'LesPay Wallet',
          subtitle: 'Balance, top-up, withdraw',
          onTap: () => _openSubScreen(
            context,
            title: 'LesPay Wallet',
            body: const RiderWalletView(),
          ),
        ),
        _MoreTile(
          icon: Icons.payments_outlined,
          label: 'My Earnings',
          subtitle: 'Today, week, and trip breakdown',
          onTap: () => AppRouter.push(context, MainRoutes.riderEarnings),
        ),
        _MoreTile(
          icon: Icons.star_outline,
          label: 'Missions',
          subtitle: 'Complete missions and earn rewards',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RiderMissionView()),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _SectionTitle(title: 'Benefits'),
        _MoreTile(
          icon: Icons.local_offer_outlined,
          label: 'Offers & vouchers',
          onTap: () => AppRouter.push(context, MainRoutes.riderOffers),
        ),
        _MoreTile(
          icon: Icons.loyalty_outlined,
          label: 'Loyalty rewards',
          onTap: () => AppRouter.push(context, MainRoutes.riderLoyalty),
        ),
        _MoreTile(
          icon: Icons.group_add_outlined,
          label: 'Referral program',
          onTap: () => AppRouter.push(context, MainRoutes.riderReferral),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _SectionTitle(title: 'Help'),
        _MoreTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Order alerts, missions, and promos',
          onTap: () => AppRouter.push(context, MainRoutes.riderNotifications),
        ),
        _MoreTile(
          icon: Icons.help_outline,
          label: 'FAQs',
          onTap: () => AppRouter.push(context, MainRoutes.riderFaqs),
        ),
        _MoreTile(
          icon: Icons.support_agent_outlined,
          label: 'Support tickets',
          subtitle: 'Contact LeSGo support',
          onTap: () => AppRouter.push(context, MainRoutes.riderSupportTickets),
        ),
        _MoreTile(
          icon: Icons.emergency_outlined,
          label: 'Safety & SOS',
          onTap: () => AppRouter.push(context, MainRoutes.riderSafety),
        ),
        _MoreTile(
          icon: Icons.security,
          label: 'Security & 2FA',
          onTap: () => AppRouter.push(context, MainRoutes.riderSecurity),
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
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 13),
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
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
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
