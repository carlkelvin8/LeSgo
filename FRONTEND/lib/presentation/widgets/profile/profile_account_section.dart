import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';

class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
         Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Account settings',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, Color(0xFF82788D)),
              letterSpacing: -0.3,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: .03),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            children: [
              _AccountTile(
                icon: Icons.person_off_outlined,
                title: 'Deactivate account',
                subtitle: 'Temporarily disable your account',
                iconBg: const Color(0xFFF0E8FF),
                iconColor: const Color(0xFF7B3FAA),
                onTap: () =>
                    AppRouter.push(context, MainRoutes.deactivateAccount),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: AppColors.surface(context, Color(0xFFF3EDF9)),
              ),
              _AccountTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete account',
                subtitle: 'Permanently remove your data from LeSgo',
                iconBg: const Color(0xFFFFF0F0),
                iconColor: Colors.red.shade600,
                titleColor: Colors.red.shade700,
                isDestructive: true,
                onTap: () => AppRouter.push(context, MainRoutes.deleteAccount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.titleColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.foreground(context, Color(0xFF1A0A2E)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:  TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11.5,
                        color: AppColors.foreground(context, Color(0xFF82788D)),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDestructive
                    ? Colors.red.shade300
                    : const Color(0xFFCCB0E0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
