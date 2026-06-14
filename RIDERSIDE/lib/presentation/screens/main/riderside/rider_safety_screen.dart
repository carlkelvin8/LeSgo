import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/mobile_config_service.dart';
import '../../../../core/utils/responsive_utils.dart';

class RiderSafetyScreen extends StatefulWidget {
  const RiderSafetyScreen({super.key});

  @override
  State<RiderSafetyScreen> createState() => _RiderSafetyScreenState();
}

class _RiderSafetyScreenState extends State<RiderSafetyScreen> {
  String _supportPhone = '+639171234567';
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
      _supportPhone = MobileConfigService.instance.supportPhone;
      _emergencyNumber = MobileConfigService.instance.emergencyNumber;
      _loadingConfig = false;
    });
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'Safety & SOS',
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
                            'Emergency',
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
                        'If you are in immediate danger, call emergency services right away.',
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
                            'Call $_emergencyNumber',
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
                  icon: Icons.support_agent,
                  title: 'LeSGo Rider Support',
                  subtitle: 'Report incidents, accidents, or unsafe customers',
                  onTap: () => _callNumber(_supportPhone),
                ),
                _ActionTile(
                  icon: Icons.share_location_outlined,
                  title: 'Share live location',
                  subtitle:
                      'Use your phone share feature while on an active delivery',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Open your active order map and use your device share options.',
                        ),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.info_outline,
                  title: 'Safety tips',
                  subtitle:
                      'Verify order details, avoid unsafe areas at night, wear helmet',
                  onTap: () {},
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
