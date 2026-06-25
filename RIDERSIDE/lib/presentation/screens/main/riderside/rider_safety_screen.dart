import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/services/mobile_config_service.dart';
import '../../../../core/utils/app_localization.dart';
import 'rider_customer_service_chat_screen.dart';
import '../../../../core/utils/responsive_utils.dart';

class RiderSafetyScreen extends ConsumerStatefulWidget {
  const RiderSafetyScreen({super.key});

  @override
  ConsumerState<RiderSafetyScreen> createState() => _RiderSafetyScreenState();
}

class _RiderSafetyScreenState extends ConsumerState<RiderSafetyScreen> {
  String _emergencyNumber = '911';
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await MobileConfigService.instance.load();
    if (!mounted) return;
    setState(() {
      _emergencyNumber = MobileConfigService.instance.emergencyNumber;
      _loadingConfig = false;
    });
  }

  Widget _buildSOSSection(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade400.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                AppLocalization.translate('sos_emergency_alert', lang),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w800,
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            AppLocalization.translate('panic_button_desc', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade700,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () => _triggerSOS(context),
              icon: const Icon(Icons.warning_amber_rounded, size: 32),
              label: Text(
                AppLocalization.translate('panic_button_sos', lang),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w800,
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS(BuildContext context) async {
    final lang = ref.read(appLanguageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalization.translate('send_sos_alert', lang),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalization.translate('your_location_sent', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'TT Fors'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalization.translate('send_sos', lang),
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.translate('could_not_get_location_gps', lang)),
        ),
      );
      return;
    }

    final locString =
        '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
    final mapsUrl = 'https://maps.google.com/?q=$locString';
    final message =
        'SOS! I need help! My location: $mapsUrl';

    final smsUri = Uri.parse('sms:$_emergencyNumber?body=$message');
    try {
      await launchUrl(smsUri);
    } catch (_) {
      try {
        await launchUrl(Uri.parse(mapsUrl));
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalization.translate('sos_sent', lang)
            .replaceAll('{{lat}}', position.latitude.toStringAsFixed(6))
            .replaceAll('{{lng}}', position.longitude.toStringAsFixed(6))),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSafetyTips(BuildContext context) {
    final lang = ref.read(appLanguageProvider);
    final tips = [
      ('verified_user', 'tip_verify_order'),
      ('map', 'tip_avoid_unsafe'),
      ('pedal_bike', 'tip_wear_helmet'),
      ('lock', 'tip_lock_vehicle'),
      ('phone_in_talk', 'tip_keep_phone_charged'),
      ('group', 'tip_share_location'),
      ('warning', 'tip_report_suspicious'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Text(
                AppLocalization.translate('safety_tips', lang),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F2D82),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              ...tips.map(
                (t) => Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconFromString(t.$1),
                        color: const Color(0xFF5F2D82),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalization.translate(t.$2, lang),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'verified_user':
        return Icons.verified_user;
      case 'map':
        return Icons.map;
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'lock':
        return Icons.lock;
      case 'phone_in_talk':
        return Icons.phone_in_talk;
      case 'group':
        return Icons.group;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          AppLocalization.translate('safety_sos', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingConfig
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
              : ListView(
              padding: EdgeInsets.all(hp),
              children: [
                _buildSOSSection(context),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalization.translate('emergency', lang),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w800,
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        AppLocalization.translate('if_immediate_danger', lang),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.red.shade900,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.spacing(context, 14),
                            ),
                          ),
                          onPressed: () => _callNumber(_emergencyNumber),
                          icon: const Icon(Icons.phone),
                          label: Text(
                            AppLocalization.translate('call_support', lang).replaceAll('{{number}}', _emergencyNumber),
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                _ActionTile(
                  icon: Icons.chat_bubble_outline,
                  title: AppLocalization.translate('chat_admin_support', lang),
                  subtitle:
                      AppLocalization.translate('admin_support_chat_subtitle', lang),
                  onTap: () =>
                      AppRouter.push(context, MainRoutes.riderCustomerServiceChat),
                ),
                _ActionTile(
                  icon: Icons.call_outlined,
                  title: AppLocalization.translate('call_admin_support', lang),
                  subtitle: AppLocalization.translate(
                    'admin_call_request_subtitle',
                    lang,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RiderCustomerServiceChatScreen(
                        requestAdminCallbackOnOpen: true,
                      ),
                    ),
                  ),
                ),
                _ActionTile(
                  icon: Icons.share_location_outlined,
                  title: AppLocalization.translate('share_live_location', lang),
                  subtitle:
                      'Share your current location via maps',
                  onTap: () async {
                    try {
                      final pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      final uri = Uri.parse(
                        'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalization.translate('could_not_get_location', lang)),
                          ),
                        );
                      }
                    }
                  },
                ),
                _ActionTile(
                  icon: Icons.info_outline,
                  title: AppLocalization.translate('safety_tips', lang),
                  subtitle: AppLocalization.translate('safety_tips_list', lang),
                  onTap: () => _showSafetyTips(context),
                ),
              ],
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF5F2D82)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
