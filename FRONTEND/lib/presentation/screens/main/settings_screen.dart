import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.fontSize(context, 20),
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'TT Fors',
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          // Account Section
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                subtitle: 'Manage your delivery addresses',
                onTap: () => AppRouter.push(context, MainRoutes.addressManagement),
              ),
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Profile Information',
                subtitle: 'Update your personal details',
                onTap: () => AppRouter.push(context, MainRoutes.profile),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          
          // App Section
          _SettingsSection(
            title: 'App',
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  // TODO: Implement notifications settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'Change app language',
                onTap: () {
                  // TODO: Implement language settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          
          // Support Section
          _SettingsSection(
            title: 'Support',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'FAQs',
                subtitle: 'Frequently asked questions',
                onTap: () => AppRouter.push(context, MainRoutes.faqs),
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'About',
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

  const _SettingsSection({
    required this.title,
    required this.items,
  });

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
              color: Colors.grey[600],
              fontFamily: 'TT Fors',
            ),
          ),
        ),
        Container(
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
                      color: Colors.grey[200],
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
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF5F2D82),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 15),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'TT Fors',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 13),
          color: Colors.grey[600],
          fontFamily: 'TT Fors',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
