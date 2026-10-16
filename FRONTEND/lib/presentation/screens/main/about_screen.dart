import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';

const _brand = Color(0xFF5F2D82);
const _border = Color(0xFFECE5F2);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface(context, Color(0xFFF8F7FB)),
    appBar: AppBar(
      backgroundColor: AppColors.surface(context, Color(0xFFF8F7FB)),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'About LeSgo',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF773F9B), Color(0xFF452063)],
                      ),
                    ),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/images/Logo.svg',
                          width: 230,
                          height: 78,
                          fit: BoxFit.contain,
                          semanticsLabel: 'LeSgo Courier Service logo',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Everyday life.\nA little easier.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                         Text(
                          AppInfo.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.foreground(context, Color(0xFFE6D8EF)),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: Text(
                            AppInfo.versionLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('OUR STORY'),
                  const SizedBox(height: 10),
                   _Surface(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfo.companyName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent(context, _brand),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            AppInfo.aboutDescription,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.75,
                              color: AppColors.foreground(context, Color(0xFF62576A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel('CONTACT'),
                  const SizedBox(height: 6),
                  const Text(
                    'We’re here to help.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                   _Surface(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _ContactRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Support email',
                            value: AppInfo.supportEmail,
                          ),
                          Divider(height: 1, color: AppColors.border(context, _border), indent: 44),
                          _ContactRow(
                            icon: Icons.shield_outlined,
                            label: 'Privacy inquiries',
                            value: AppInfo.privacyEmail,
                          ),
                          Divider(height: 1, color: AppColors.border(context, _border), indent: 44),
                          _ContactRow(
                            icon: Icons.language_rounded,
                            label: 'Website',
                            value: AppInfo.website,
                          ),
                          Divider(height: 1, color: AppColors.border(context, _border), indent: 44),
                          _ContactRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: AppInfo.companyAddress,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel('PRIVACY & TERMS'),
                  const SizedBox(height: 12),
                  _Surface(
                    child: Column(
                      children: [
                        _LegalRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we protect your information',
                          onTap: () =>
                              AppRouter.push(context, MainRoutes.privacyPolicy),
                        ),
                         Divider(height: 1, color: AppColors.border(context, _border), indent: 62),
                        _LegalRow(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'Guidelines for using LeSgo',
                          onTap: () => AppRouter.push(
                            context,
                            MainRoutes.termsOfService,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                   Text(
                    'Made for your everyday.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.foreground(context, Color(0xFF95869F)), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style:  TextStyle(
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w700,
      color: AppColors.foreground(context, Color(0xFF8B729C)),
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface(context, Colors.white),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side:  BorderSide(color: AppColors.border(context, _border)),
    ),
    child: child,
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Color(0xFFF5F0F8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: AppColors.accent(context, _brand)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:  TextStyle(fontSize: 10, color: AppColors.foreground(context, Color(0xFF8B7A96))),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    leading: Icon(icon, color: AppColors.accent(context, _brand), size: 22),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      subtitle,
      style:  TextStyle(
        fontSize: 11,
        color: AppColors.foreground(context, Color(0xFF8B7A96)),
        height: 1.5,
      ),
    ),
    trailing:  Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: AppColors.foreground(context, Color(0xFFAC9AB7)),
    ),
    onTap: onTap,
  );
}
