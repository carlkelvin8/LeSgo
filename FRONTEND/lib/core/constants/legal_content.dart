import 'app_info.dart';

/// Shared legal copy aligned with lesgo.ph Terms & Conditions and Privacy Policy.
class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'April 18, 2026';

  static const String aboutUsDescription =
      'LeSgo Philippines is your all-in-one super app for rides, food delivery, '
      'shopping, parcel delivery, and digital payments. We connect customers, '
      'riders, and partner merchants so everyday errands are faster, safer, and '
      'more convenient — proudly serving communities across the Philippines from '
      'our home base in Kilkiling, Claveria, Cagayan.';

  static const String termsIntro =
      'By accessing and using the LeSgo app, you accept and agree to be bound by '
      'these Terms and Conditions. If you do not agree, please do not use our services.';

  static List<({String title, String body})> get termsSections => [
        (title: '1. Acceptance of Terms', body: termsIntro),
        (
          title: '2. Services Provided',
          body:
              'LeSgo provides on-demand services including:\n\n'
              '• Food delivery (LesEat)\n'
              '• Shopping delivery (LesBuy)\n'
              '• Transportation services (LesRide)\n'
              '• Package delivery (LesGo)\n'
              '• Logistics (LesTransport)\n'
              '• Digital wallet services (LesPay)',
        ),
        (
          title: '3. User Accounts',
          body:
              'To use our services, you must:\n\n'
              '• Be at least 18 years old\n'
              '• Provide accurate and complete information\n'
              '• Maintain the security of your account\n'
              '• Notify us immediately of any unauthorized access\n'
              '• Be responsible for all activities under your account',
        ),
        (
          title: '4. Orders and Payments',
          body:
              '• All orders are subject to acceptance and availability\n'
              '• Prices are subject to change without notice\n'
              '• Payment must be made at the time of order unless otherwise stated\n'
              '• Delivery fees and service charges apply\n'
              '• Refunds are processed according to our refund policy',
        ),
        (
          title: '5. Cancellations and Refunds',
          body:
              '• You may cancel orders before driver assignment\n'
              '• Cancellation fees may apply after driver assignment\n'
              '• Refunds are processed within 5–7 business days\n'
              '• Refund eligibility is determined on a case-by-case basis',
        ),
        (
          title: '6. User Conduct',
          body:
              'You agree not to:\n\n'
              '• Use the service for illegal purposes\n'
              '• Harass or abuse drivers, merchants, or support staff\n'
              '• Provide false or misleading information\n'
              '• Attempt to manipulate prices or promotions\n'
              '• Reverse engineer or copy the app\n'
              '• Use automated systems to access the service',
        ),
        (
          title: '7. Delivery',
          body:
              '• Delivery times are estimates and not guaranteed\n'
              '• You must be available to receive deliveries\n'
              '• Provide accurate delivery addresses\n'
              '• We are not responsible for delays beyond our control\n'
              '• Undeliverable orders may incur additional fees',
        ),
        (
          title: '8. Intellectual Property',
          body:
              'All content, trademarks, and intellectual property in the app are owned '
              'by LeSgo Philippines or our licensors. You may not use, copy, or distribute '
              'any content without permission.',
        ),
        (
          title: '9. Limitation of Liability',
          body:
              'LeSgo is not liable for:\n\n'
              '• Indirect, incidental, or consequential damages\n'
              '• Loss of profits or data\n'
              '• Service interruptions or errors\n'
              '• Third-party actions or content\n'
              '• Food quality issues (contact the restaurant directly)',
        ),
        (
          title: '10. Promotions and Discounts',
          body:
              '• Promotions are subject to these terms\n'
              '• Promo codes cannot be combined unless stated\n'
              '• We reserve the right to modify or cancel promotions\n'
              '• Abuse of promotions may result in account suspension',
        ),
        (
          title: '11. Privacy',
          body:
              'Your use of the service is also governed by our Privacy Policy. '
              'Please review it to understand our data practices.',
        ),
        (
          title: '12. Termination',
          body:
              'We may suspend or terminate your account if you:\n\n'
              '• Violate these terms\n'
              '• Engage in fraudulent activity\n'
              '• Abuse the service or staff\n'
              '• Fail to pay for services',
        ),
        (
          title: '13. Changes to Terms',
          body:
              'We reserve the right to modify these terms at any time. Continued use '
              'of the service after changes constitutes acceptance of the new terms.',
        ),
        (
          title: '14. Governing Law',
          body:
              'These terms are governed by the laws of the Republic of the Philippines. '
              'Any disputes shall be resolved in the courts of Cagayan, Philippines.',
        ),
        (
          title: '15. Contact Information',
          body:
              'For questions about these terms, contact us:\n\n'
              'Email: ${AppInfo.supportEmail}\n'
              'Phone: ${AppInfo.supportPhone}\n'
              'Address: ${AppInfo.companyAddress}\n\n'
              '${AppInfo.companyName}',
        ),
      ];

  static String get fullTermsText {
    final buffer = StringBuffer();
    for (final section in termsSections) {
      buffer.writeln(section.title);
      buffer.writeln(section.body);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  static List<({String title, String body})> get privacySections => [
        (
          title: '1. Information We Collect',
          body:
              'We collect information you provide directly to us, including:\n\n'
              '• Personal information (name, email, phone number)\n'
              '• Location data for delivery services\n'
              '• Payment information\n'
              '• Order history and preferences\n'
              '• Device information and usage data',
        ),
        (
          title: '2. How We Use Your Information',
          body:
              'We use the information we collect to:\n\n'
              '• Process and deliver your orders\n'
              '• Communicate with you about your orders\n'
              '• Improve our services\n'
              '• Send promotional offers (with your consent)\n'
              '• Ensure security and prevent fraud',
        ),
        (
          title: '3. Location Data',
          body:
              'We collect and use your location data to:\n\n'
              '• Show nearby restaurants and stores\n'
              '• Calculate delivery fees and ETAs\n'
              '• Track delivery progress\n'
              '• Improve service quality\n\n'
              'You can disable location services in your device settings, but this may '
              'limit app functionality.',
        ),
        (
          title: '4. Data Sharing',
          body:
              'We may share your information with:\n\n'
              '• Delivery drivers (only information necessary for delivery)\n'
              '• Partner restaurants and stores\n'
              '• Payment processors such as Xendit\n'
              '• Service providers who assist our operations\n\n'
              'We do not sell your personal information to third parties.',
        ),
        (
          title: '5. Data Security',
          body:
              'We implement appropriate technical and organizational measures to protect '
              'your personal information. However, no method of transmission over the '
              'Internet is 100% secure.',
        ),
        (
          title: '6. Your Rights',
          body:
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Correct inaccurate data\n'
              '• Request deletion of your data\n'
              '• Opt out of marketing communications\n'
              '• Withdraw consent where applicable',
        ),
        (
          title: '7. Data Retention',
          body:
              'We retain your information for as long as necessary to provide services '
              'and comply with legal obligations.',
        ),
        (
          title: '8. Children\'s Privacy',
          body:
              'Our services are not intended for users under 18. We do not knowingly '
              'collect information from children.',
        ),
        (
          title: '9. Changes to This Policy',
          body:
              'We may update this privacy policy from time to time. We will notify you of '
              'any changes by posting the new policy on this page and updating the '
              '"Last Updated" date.',
        ),
        (
          title: '10. Contact Us',
          body:
              'If you have questions about this privacy policy, please contact us:\n\n'
              'Email: ${AppInfo.privacyEmail}\n'
              'Address: ${AppInfo.companyAddress}\n\n'
              '${AppInfo.companyName}',
        ),
      ];
}
