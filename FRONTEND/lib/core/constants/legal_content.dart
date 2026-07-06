import 'app_info.dart';

/// Shared legal copy aligned with lesgo.ph Terms & Conditions and Privacy Policy.
class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'June 11, 2026';

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
          title: 'Introduction',
          body:
              'LeSgo Courier Services ("we," "our," or "us") values your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, store, and protect information when you use any LesGo platform services, including:\n\n'
              '• LeSgo Customer App\n'
              '• LeSgo Rider App\n'
              '• LeSgo Merchant App\n'
              '• LeSgo Motor Taxi Service\n'
              '• LeSgo Padala Service\n'
              '• LeSgo Delivery Services\n'
              '• LeSgo Website and Related Platforms\n\n'
              'By accessing or using any LeSgo service, you agree to the collection and use of information described in this Privacy Policy.',
        ),
        (
          title: 'A. Personal Information',
          body:
              'We may collect information that identifies you directly or indirectly, including:\n\n'
              '• Full name\n'
              '• Mobile phone number\n'
              '• Email address\n'
              '• Profile picture\n'
              '• Date of birth\n'
              '• Gender (optional)\n'
              '• Residential address\n'
              '• Pickup and drop-off addresses\n'
              '• Emergency contact details\n'
              '• Government-issued identification\n'
              '• Business registration documents (for merchants)\n'
              '• Driver\'s license (for riders)\n'
              '• Vehicle registration documents\n'
              '• Vehicle details',
        ),
        (
          title: 'B. Location Information',
          body:
              'To provide transportation, delivery, and logistics services, LeSgo may collect:\n\n'
              '• Real-time GPS location\n'
              '• Current location\n'
              '• Background location during active services\n'
              '• Pickup locations\n'
              '• Drop-off locations\n'
              '• Delivery destinations\n'
              '• Route history\n'
              '• Travel patterns related to service fulfillment\n\n'
              'Location data may be collected even when the application is running in the background if necessary to support active rides, deliveries, or tracking features.',
        ),
        (
          title: 'C. Transaction Information',
          body:
              'We may collect:\n\n'
              '• Booking information\n'
              '• Ride history\n'
              '• Delivery history\n'
              '• Order history\n'
              '• Payment transactions\n'
              '• Merchant sales records\n'
              '• Rider earnings records\n'
              '• Refund requests\n'
              '• Wallet balances and transactions',
        ),
        (
          title: 'D. Merchant Information',
          body:
              'For merchants using the LeSgo Merchant App, we may collect:\n\n'
              '• Business name\n'
              '• Business address\n'
              '• Store location\n'
              '• Contact information\n'
              '• Business permits\n'
              '• Tax information\n'
              '• Product listings\n'
              '• Pricing information\n'
              '• Operating hours\n'
              '• Sales reports',
        ),
        (
          title: 'E. Rider Information',
          body:
              'For riders using the LeSgo Rider App, we may collect:\n\n'
              '• Driver\'s license information\n'
              '• Vehicle details\n'
              '• Vehicle registration\n'
              '• Insurance information\n'
              '• Profile photo\n'
              '• Background verification documents\n'
              '• Performance metrics\n'
              '• Delivery and trip records',
        ),
        (
          title: 'F. Device Information',
          body:
              'We may automatically collect:\n\n'
              '• Device model\n'
              '• Operating system version\n'
              '• Device identifiers\n'
              '• Mobile network information\n'
              '• IP address\n'
              '• Browser type\n'
              '• Application version\n'
              '• Crash logs\n'
              '• Diagnostic information',
        ),
        (
          title: 'How We Use Your Information',
          body:
              'We use the collected information to create and manage user accounts, verify identities, and process bookings and deliveries. This data allows us to match customers with riders, facilitate merchant operations, process payments and settlements, and provide customer support. Additionally, we utilize it to improve service quality, monitor platform performance, detect fraud and suspicious activities, and enforce our terms and policies. Finally, your information helps us send notifications and updates, conduct analytics and research, and ensure compliance with our legal obligations.',
        ),
        (
          title: 'Location Services',
          body:
              'LeSgo uses location services to identify nearby riders, enable real-time tracking, and calculate routes and fares. This data also helps improve navigation, verify trip and delivery completion, and enhance both rider and customer safety while preventing fraudulent activity. For riders, location data may continue to be collected in the background while they are actively accepting, completing, or managing rides and deliveries.',
        ),
        (
          title: 'Camera Access',
          body:
              'LeSgo may request camera access for profile photo uploads, identity verification, driver\'s license verification, and vehicle documentation. Additionally, it is used for merchant document submission and delivery proof photos. Camera access is utilized only when necessary and strictly with user permission.',
        ),
        (
          title: 'Photo and Media Access',
          body:
              'LeSgo may request access to device photos, media files, and documents. This allows users to upload profile photos, identification documents, business permits, vehicle documents, and delivery confirmation photos.',
        ),
        (
          title: 'Notifications',
          body:
              'LeSgo may send notifications regarding booking updates, ride status, delivery status, merchant orders, and rider assignments. These alerts also cover promotional offers, security alerts, and account updates. Users retain full control and may manage their notification preferences directly through their device settings.',
        ),
        (
          title: 'Payment Information',
          body:
              'LeSgo may process payments through third-party payment providers, which involves collecting payment transaction records, digital wallet information, payout information, and settlement information. To ensure security, sensitive payment information is handled by authorized payment processors and is not stored directly by LeSgo.',
        ),
        (
          title: 'Information Sharing',
          body:
              'We may share necessary information across our platform ecosystem to facilitate seamless services. Customers can view a rider\'s name, profile photo, vehicle information, and contact details when necessary, while riders can view a customer\'s name, pickup location, drop-off location, and relevant contact information. Similarly, merchants are provided with customer order details, delivery information, and contact info required for order fulfillment.\n\n'
              'Beyond platform users, information may be shared with trusted service providers supporting our cloud hosting, payment processing, analytics, customer support, and mapping services. Finally, we may disclose information to legal authorities when required by applicable laws, court orders, government agencies, regulatory authorities, or law enforcement requests.',
        ),
        (
          title: 'Data Retention',
          body:
              'We retain personal information only as long as necessary to provide services, maintain records, resolve disputes, and detect fraud. This retention period also ensures we can enforce agreements and comply with legal obligations. Ultimately, information is deleted, anonymized, or archived once it is no longer required.',
        ),
        (
          title: 'Data Security',
          body:
              'LeSgo implements appropriate security measures designed to protect personal information against unauthorized access, loss, theft, misuse, alteration, and disclosure. These safety measures include encrypted communications, secure databases, access controls, authentication mechanisms, and continuous security monitoring. However, users should note that no electronic transmission or storage method can be guaranteed to be completely secure.',
        ),
        (
          title: 'Your Rights',
          body:
              'Depending on applicable laws, users may have the right to access their personal information, request corrections, or request deletion. They may also withdraw consent, restrict processing, request a copy of their data, and submit privacy-related complaints. All such requests may be formally submitted through our designated support channels.',
        ),
        (
          title: 'Children\'s Privacy',
          body:
              'LeSgo services are intended only for individuals who are at least eighteen (18) years old or the minimum legal age required under applicable laws. Consequently, we do not knowingly collect personal information from children. If we learn that a child has provided personal information, we will take reasonable steps to remove such information immediately.',
        ),
        (
          title: 'Third-Party Services',
          body:
              'LeSgo may integrate with various third-party services, including Google Play Services, Google Maps Platform, Firebase Analytics, and Firebase Crashlytics. It also integrates with payment gateways, SMS and communication providers, and cloud hosting providers. These third parties may collect information according to their own independent privacy policies.',
        ),
        (
          title: 'International Data Processing',
          body:
              'Information may be processed, stored, or transferred through secure servers operated by LeSgo or its service providers, strictly in accordance with applicable data protection laws.',
        ),
        (
          title: 'Compliance with Philippine Data Privacy Act',
          body:
              'LeSgo is committed to complying with Republic Act No. 10173, also known as the Data Privacy Act of 2012, alongside all applicable regulations issued by the National Privacy Commission (NPC) of the Philippines. Under this commitment, all personal information is processed lawfully, fairly, securely, and transparently.',
        ),
        (
          title: 'Changes to This Privacy Policy',
          body:
              'We may update this Privacy Policy from time to time. Any changes will be posted within the application, website, or other official communication channels. Your continued use of LeSgo services after these updates are posted constitutes acceptance of the revised Privacy Policy.',
        ),
        (
          title: 'Contact Us',
          body:
              'If you have questions, concerns, or requests regarding this Privacy Policy, please contact the LeSgo Support Team via email at lesgoclaveria@gmail.com or visit our website at https://lesgo.ph.\n\n'
              'By downloading, registering, accessing, or using any LeSgo application or service — including the Customer App, Rider App, Merchant App, Motor Taxi Service, and Padala Service — you acknowledge that you have read, understood, and agreed to this Privacy Policy.\n\n'
              '© 2026 LeSgo. All Rights Reserved.',
        ),
      ];
}
