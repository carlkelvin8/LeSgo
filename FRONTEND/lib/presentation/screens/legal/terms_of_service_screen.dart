import 'package:flutter/material.dart';
import '../../../core/constants/app_info.dart';

/// Terms of Service Screen
/// Displays the app's terms of service
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using the Lesgo app, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. Services Provided',
              'Lesgo provides on-demand delivery services including:\n\n'
              '• Food delivery (LesEat)\n'
              '• Shopping delivery (LesBuy)\n'
              '• Transportation services (LesRide)\n'
              '• Package delivery (LesGo)\n'
              '• Digital wallet services (LesPay)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. User Accounts',
              'To use our services, you must:\n\n'
              '• Be at least 18 years old\n'
              '• Provide accurate and complete information\n'
              '• Maintain the security of your account\n'
              '• Notify us immediately of any unauthorized access\n'
              '• Be responsible for all activities under your account',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Orders and Payments',
              '• All orders are subject to acceptance and availability\n'
              '• Prices are subject to change without notice\n'
              '• Payment must be made at the time of order\n'
              '• Delivery fees and service charges apply\n'
              '• Refunds are processed according to our refund policy',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Cancellations and Refunds',
              '• You may cancel orders before driver assignment\n'
              '• Cancellation fees may apply after driver assignment\n'
              '• Refunds are processed within 5-7 business days\n'
              '• Refund eligibility is determined on a case-by-case basis',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '6. User Conduct',
              'You agree not to:\n\n'
              '• Use the service for illegal purposes\n'
              '• Harass or abuse drivers or support staff\n'
              '• Provide false or misleading information\n'
              '• Attempt to manipulate prices or promotions\n'
              '• Reverse engineer or copy the app\n'
              '• Use automated systems to access the service',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '7. Delivery',
              '• Delivery times are estimates and not guaranteed\n'
              '• You must be available to receive deliveries\n'
              '• Provide accurate delivery addresses\n'
              '• We are not responsible for delays beyond our control\n'
              '• Undeliverable orders may incur additional fees',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '8. Intellectual Property',
              'All content, trademarks, and intellectual property in the app are owned by Lesgo or our licensors. You may not use, copy, or distribute any content without permission.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '9. Limitation of Liability',
              'Lesgo is not liable for:\n\n'
              '• Indirect, incidental, or consequential damages\n'
              '• Loss of profits or data\n'
              '• Service interruptions or errors\n'
              '• Third-party actions or content\n'
              '• Food quality issues (contact restaurant directly)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '10. Promotions and Discounts',
              '• Promotions are subject to terms and conditions\n'
              '• Promo codes cannot be combined unless stated\n'
              '• We reserve the right to modify or cancel promotions\n'
              '• Abuse of promotions may result in account suspension',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '11. Privacy',
              'Your use of the service is also governed by our Privacy Policy. Please review our Privacy Policy to understand our data practices.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '12. Termination',
              'We may suspend or terminate your account if you:\n\n'
              '• Violate these terms\n'
              '• Engage in fraudulent activity\n'
              '• Abuse the service or staff\n'
              '• Fail to pay for services',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '13. Changes to Terms',
              'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '14. Governing Law',
              'These terms are governed by the laws of the Republic of the Philippines. Any disputes shall be resolved in the courts of [Your City/Province], Philippines.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '15. Contact Information',
              'For questions about these terms, contact us:\n\n'
              'Email: ${AppInfo.supportEmail}\n'
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
