import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/responsive_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About ${AppInfo.appName}',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            fontFamily: 'TT Fors',
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 44,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Center(
            child: Text(
              AppInfo.appName,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 24),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
          Center(
            child: Text(
              AppInfo.versionLabel,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _InfoCard(
            title: 'About us',
            body: '${AppInfo.companyName}\n\n${AppInfo.aboutDescription}',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          _InfoCard(
            title: 'Contact',
            body:
                'Email: ${AppInfo.supportEmail}\n'
                'Privacy: ${AppInfo.privacyEmail}\n'
                'Website: ${AppInfo.website}\n'
                'Address: ${AppInfo.companyAddress}',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we collect and use your data',
            onTap: () => AppRouter.push(context, MainRoutes.privacyPolicy),
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Rules for using LeSgo services',
            onTap: () => AppRouter.push(context, MainRoutes.termsOfService),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F2D82),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF5F2D82)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
