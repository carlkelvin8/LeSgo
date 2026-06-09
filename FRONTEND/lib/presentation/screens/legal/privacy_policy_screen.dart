import 'package:flutter/material.dart';
import '../../../core/constants/app_info.dart';

/// Privacy Policy Screen
/// Displays the app's privacy policy
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Last Updated',
              'April 18, 2026',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, including:\n\n'
              '• Personal information (name, email, phone number)\n'
              '• Location data for delivery services\n'
              '• Payment information\n'
              '• Order history and preferences\n'
              '• Device information and usage data',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Process and deliver your orders\n'
              '• Communicate with you about your orders\n'
              '• Improve our services\n'
              '• Send promotional offers (with your consent)\n'
              '• Ensure security and prevent fraud',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. Location Data',
              'We collect and use your location data to:\n\n'
              '• Show nearby restaurants and stores\n'
              '• Calculate delivery fees and ETAs\n'
              '• Track delivery progress\n'
              '• Improve service quality\n\n'
              'You can disable location services in your device settings, but this may limit app functionality.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Data Sharing',
              'We may share your information with:\n\n'
              '• Delivery drivers (only information necessary for delivery)\n'
              '• Partner restaurants and stores\n'
              '• Payment processors\n'
              '• Service providers who assist our operations\n\n'
              'We do not sell your personal information to third parties.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Data Security',
              'We implement security measures to protect your information:\n\n'
              '• Encryption of sensitive data\n'
              '• Secure payment processing\n'
              '• Regular security audits\n'
              '• Access controls and authentication',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Request deletion of your data\n'
              '• Opt-out of marketing communications\n'
              '• Export your data\n\n'
              'Contact us at ${AppInfo.privacyEmail} to exercise these rights.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '7. Data Retention',
              'We retain your information for as long as necessary to:\n\n'
              '• Provide our services\n'
              '• Comply with legal obligations\n'
              '• Resolve disputes\n'
              '• Enforce our agreements',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '8. Children\'s Privacy',
              'Our services are not intended for children under 13. We do not knowingly collect information from children under 13.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '9. Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '10. Contact Us',
              'If you have questions about this privacy policy, please contact us:\n\n'
              'Email: ${AppInfo.privacyEmail}\n'
              'Phone: ${AppInfo.supportPhone}\n'
              'Address: ${AppInfo.companyAddress}\n\n'
              '${AppInfo.companyName}',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF333333),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
