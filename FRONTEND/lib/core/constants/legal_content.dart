/// Shared legal copy aligned with lesgo.ph Terms & Conditions and Privacy Policy.
class LegalContent {
  LegalContent._();

  static const String lastUpdated = 'June 11, 2026';

  static const String aboutUsDescription =
      'LeSgo Philippines is your all-in-one super app for rides, food delivery, '
      'shopping, parcel delivery, and digital payments. We connect customers, '
      'riders, and partner merchants so everyday errands are faster, safer, and '
      'more convenient — proudly serving communities across the Philippines.';

  static const String termsIntro =
      'These User Terms and Conditions ("Terms") govern the relationship between LeSgo Courier Services '
      '("Company," "we," "us," or "our") and the individual user (referred to as the "User," "Customer," or "you") '
      'accessing or using the LeSgo mobile application, website, and on-demand delivery platform (collectively, the "Platform").\n\n'
      'By creating an account, accessing, or using our services, you explicitly acknowledge that you have read, '
      'understood, and agree to be bound by these Terms.';

  static List<({String title, String body})> get termsSections => [
        (title: 'Terms and Conditions', body: termsIntro),
        (
          title: '1. The Service and Account Integrity',
          body:
              'Platform Provision: LeSgo provides an on-demand marketplace platform connecting Users with independent '
              'third-party delivery providers ("Riders") and merchant establishments ("Partners").\n\n'
              'Single Account Policy: Users are strictly permitted to maintain only one (1) active account on the Platform. '
              'Creating duplicate accounts to exploit promotions, bypass restrictions, or manipulate system data is prohibited.\n\n'
              'Accuracy of Information: You agree to provide truthful, precise, and up-to-date information when registering, '
              'creating orders, or inputting delivery addresses. You must present valid proof of identity upon reasonable request by the Company.',
        ),
        (
          title: '2. User Conduct and Prohibited Activities',
          body:
              'System Integrity: You shall not engage in any activity designed to exploit, harass, undermine, or damage the Platform, '
              'its Riders, or its Partners. Any known bugs, glitches, or system exploits must be reported to management immediately.\n\n'
              'Prohibited Items: Users may not request the delivery of items that are illegal, dangerous, hazardous, or restricted '
              'under the laws of the Republic of the Philippines.\n\n'
              'Professional Conduct: Users are expected to treat Riders and Partners with courtesy and respect. Verbal abuse, '
              'harassment, or physical threats will result in immediate and permanent account termination.',
        ),
        (
          title: '3. Orders, Pricing, and Payments',
          body:
              'Delivery Rates: Delivery rates are dynamic and calculated based on distance, time, and volume. You acknowledge that '
              'delivery rates may change without prior notice, and it is your responsibility to review the final cost displayed before confirming an order.\n\n'
              'Payment Methods: Payments may be made via cash, electronic wallets (such as GCash), or other methods integrated into the Platform.',
        ),
        (
          title: '4. Fake Bookings and No-Show Policies',
          body:
              'Definition of Fake Booking: Placing an order with no intent to receive or pay for it, providing a deliberately false '
              'delivery address, or failing to appear/respond to the Rider during a delivery attempt constitutes a "Fake Booking."\n\n'
              'Legal and Financial Accountability: LeSgo takes fake bookings seriously. While the Company provides a safety mechanism '
              'to reimburse its Riders for the value of products/earnings lost to fake bookings, the Company reserves all rights to '
              'pursue strict legal and criminal action against the offending User.\n\n'
              'Partner Responsibilities: If a fake booking is traced back to being intentionally generated, manipulated, or falsified '
              'by a Partner establishment, the Partner shall directly reimburse the Rider or Company.',
        ),
        (
          title: '5. Cancellations and Refunds',
          body:
              'Cancellation Window: Orders cannot be canceled once a Rider has purchased the items from the Partner or is already en route to the delivery location.\n\n'
              'Refusal of Delivery: If a User refuses to accept an order without valid justification (e.g., severe item damage prior to handover), '
              'the User remains fully liable for the full cost of the items and delivery fees.',
        ),
        (
          title: '6. Cargo, Liabilities, and Disclaimers',
          body:
              'Independent Contractors: You acknowledge that Riders are independent contractors and not employees of LeSgo.\n\n'
              'Rider Liability ("Your Delivery, Your Cargo"): Riders operate under a strict cargo policy. If an item is damaged, '
              'mishandled, or if food/beverages are spilled during transit due to Rider negligence, the Rider is mandated to replace or financially compensate for the damaged goods.\n\n'
              'Limitation of Liability: LeSgo serves as the platform provider and holds no direct liability for traffic violations, accidents, '
              'or breaches of local road laws committed by the Rider during the fulfillment of a delivery.\n\n'
              'GCash Disbursements: Where applicable, GCash payments processed through the system will be disbursed directly via the system/clerk protocols to ensure transaction transparency.\n\n'
              'Rider Upfront Payment: For Partner orders, the assigned Rider pays for your product/service upfront at the merchant\'s establishment. '
              'Upon delivery, you are strictly obligated to reimburse the Rider for the full value of the item plus the designated delivery fee.',
        ),
        (
          title: '7. Termination of Use',
          body:
              'LeSgo reserves the right to suspend, restrict, or permanently terminate your access to the Platform at any time, with or without cause, '
              'and without prior notice, particularly for violations concerning fake bookings, account duplication, or abusive behavior.',
        ),
        (
          title: '8. Modifications to Terms',
          body:
              'The Company reserves the right to modify these Terms and its service agreements at any time without prior notice. '
              'Users have the ongoing responsibility to regularly review these terms. Continued use of the Platform following any modifications constitutes full acceptance of the revised Terms.',
        ),
        (
          title: '9. Governing Law and Dispute Resolution',
          body:
              'These Terms shall be governed by, construed, and enforced in accordance with the laws of the Republic of the Philippines.\n\n'
              'Any disputes, controversies, or claims arising out of or relating to these Terms, including the validity or breach thereof, '
              'shall be settled through binding arbitration in accordance with the rules of Philippine arbitration bodies.\n\n'
              'By clicking "Accept," creating an account, or continuing to use LeSgo Courier Services, you affirm that you have read, '
              'understood, and agreed to be legally bound by this agreement.',
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
