import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/services/affiliate_launcher.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../widgets/support/ibow_orbit_avatar.dart';

const _brand = Color(0xFF5F2D82);
const _border = Color(0xFFECE5F2);

/// About LeSgo: who we are, how to reach us, and the legal links. Everything
/// sits on plain white; no per-section colours.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri, String copyValue) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: copyValue));
      if (context.mounted) {
        SnackBarUtils.showInfo(context, 'Copied $copyValue');
      }
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) SnackBarUtils.showSuccess(context, '$label copied');
  }

  Future<void> _becomePartner(BuildContext context) async {
    final opened = await AffiliateLauncher().open();
    if (!opened && context.mounted) {
      SnackBarUtils.showError(
        context,
        'Could not open LeSgo Affiliate. Check that a browser is available and try again.',
      );
    }
  }

  Widget _divider(BuildContext context, {double indent = 56}) => Divider(
    height: 1,
    color: AppColors.border(context, _border),
    indent: indent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.white),
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
                    const _Hero(),
                    const SizedBox(height: 16),
                    _IbowCard(
                      onTap: () => AppRouter.push(
                        context,
                        MainRoutes.customerServiceChat,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('OUR STORY'),
                    const SizedBox(height: 10),
                    const _Story(),
                    const SizedBox(height: 24),
                    const _SectionLabel('CONTACT'),
                    const SizedBox(height: 10),
                    _Surface(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            _ContactRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Support email',
                              value: AppInfo.supportEmail,
                              onTap: () => _open(
                                context,
                                Uri(
                                  scheme: 'mailto',
                                  path: AppInfo.supportEmail,
                                ),
                                AppInfo.supportEmail,
                              ),
                              onCopy: () =>
                                  _copy(context, AppInfo.supportEmail, 'Email'),
                            ),
                            _divider(context),
                            _ContactRow(
                              icon: Icons.phone_outlined,
                              label: 'Call us',
                              value: AppInfo.supportPhone,
                              onTap: () => _open(
                                context,
                                Uri(scheme: 'tel', path: AppInfo.supportPhone),
                                AppInfo.supportPhone,
                              ),
                              onCopy: () => _copy(
                                context,
                                AppInfo.supportPhone,
                                'Number',
                              ),
                            ),
                            _divider(context),
                            _ContactRow(
                              icon: Icons.language_rounded,
                              label: 'Website',
                              value: AppInfo.website,
                              onTap: () => _open(
                                context,
                                Uri.parse(AppInfo.website),
                                AppInfo.website,
                              ),
                              onCopy: () =>
                                  _copy(context, AppInfo.website, 'Link'),
                            ),
                            _divider(context),
                            _ContactRow(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: AppInfo.companyAddress,
                              onTap: () => _open(
                                context,
                                Uri.https('www.google.com', '/maps/search/', {
                                  'api': '1',
                                  'query': AppInfo.companyAddress,
                                }),
                                AppInfo.companyAddress,
                              ),
                              onCopy: () => _copy(
                                context,
                                AppInfo.companyAddress,
                                'Address',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('MORE'),
                    const SizedBox(height: 10),
                    _Surface(
                      child: Column(
                        children: [
                          _LegalRow(
                            icon: Icons.handshake_outlined,
                            title: 'Earn with LeSgo',
                            subtitle:
                                'Become a rider, restaurant or store partner',
                            onTap: () => _becomePartner(context),
                          ),
                          _divider(context, indent: 62),
                          _LegalRow(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'How we protect your information',
                            onTap: () => AppRouter.push(
                              context,
                              MainRoutes.privacyPolicy,
                            ),
                          ),
                          _divider(context, indent: 62),
                          _LegalRow(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Guidelines for using LeSgo',
                            onTap: () => AppRouter.push(
                              context,
                              MainRoutes.termsOfService,
                            ),
                          ),
                          _divider(context, indent: 62),
                          _LegalRow(
                            icon: Icons.code_rounded,
                            title: 'Open-source licenses',
                            subtitle: 'Software that helps power LeSgo',
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: AppInfo.appName,
                              applicationVersion: AppInfo.versionLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Footer(
                      onCopyVersion: () =>
                          _copy(context, AppInfo.versionLabel, 'Version'),
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
}

// ------------------------------------------------------------------- hero --

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/images/Logo.svg',
              width: 210,
              height: 70,
              fit: BoxFit.contain,
              semanticsLabel: 'LeSgo Courier Service logo',
            ),
            const SizedBox(height: 18),
            Text(
              'Everyday life.\nA little easier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.accent(context, _brand),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppInfo.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.foreground(context, const Color(0xFF62576A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- IBOW --

class _IbowCard extends StatelessWidget {
  const _IbowCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // The one premium surface on this page: deep brand gradient.
          gradient: const LinearGradient(
            colors: [Color(0xFF2B1240), Color(0xFF5F2D82), Color(0xFFA42FC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Soft light shapes and a few stars for depth.
              Positioned(
                left: -40,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: -30,
                bottom: -60,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF9BEA).withValues(alpha: 0.12),
                  ),
                ),
              ),
              const Positioned(
                right: 70,
                top: 16,
                child: _Sparkle(size: 10, opacity: 0.8),
              ),
              const Positioned(
                right: 22,
                top: 44,
                child: _Sparkle(size: 6, opacity: 0.55),
              ),
              const Positioned(
                left: 120,
                bottom: 14,
                child: _Sparkle(size: 7, opacity: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD9A3FF,
                            ).withValues(alpha: 0.45),
                            blurRadius: 26,
                          ),
                        ],
                      ),
                      child: const IbowOrbitAvatar(size: 92),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meet IBOW',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Our AI helper. Ask about orders, cancel or reorder, check your LesPay. Tap to chat, or poke IBOW to say hi.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.auto_awesome_rounded,
    size: size * 1.6,
    color: Colors.white.withValues(alpha: opacity),
  );
}

// ------------------------------------------------------------------- story --

class _Story extends StatelessWidget {
  const _Story();

  @override
  Widget build(BuildContext context) => _Surface(
    child: Padding(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 12),
          Text(
            AppInfo.aboutDescription,
            style: TextStyle(
              fontSize: 13,
              height: 1.75,
              color: AppColors.foreground(context, const Color(0xFF62576A)),
            ),
          ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------ footer --

class _Footer extends StatelessWidget {
  const _Footer({required this.onCopyVersion});
  final VoidCallback onCopyVersion;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.foreground(context, const Color(0xFF95869F));
    return Column(
      children: [
        Semantics(
          button: true,
          label: '${AppInfo.versionLabel}. Tap to copy.',
          child: GestureDetector(
            onTap: onCopyVersion,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                AppInfo.versionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent(context, _brand),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} ${AppInfo.companyName}. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- shared --

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w700,
      color: AppColors.foreground(context, const Color(0xFF8B729C)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: child,
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onCopy,
  });
  final IconData icon;
  final String label, value;
  final VoidCallback onTap, onCopy;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label, $value',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface(context, const Color(0xFFF5F0F8)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: AppColors.accent(context, _brand),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.foreground(
                        context,
                        const Color(0xFF8B7A96),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.foreground(context, const Color(0xFFAC9AB7)),
              ),
            ),
          ],
        ),
      ),
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
      style: TextStyle(
        fontSize: 11,
        color: AppColors.foreground(context, const Color(0xFF8B7A96)),
        height: 1.5,
      ),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: AppColors.foreground(context, const Color(0xFFAC9AB7)),
    ),
    onTap: onTap,
  );
}
