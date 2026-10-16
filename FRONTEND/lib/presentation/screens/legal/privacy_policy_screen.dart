import 'package:flutter/material.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/legal_content.dart';
import '_legal_screen_base.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (title: 'Effective Date', body: LegalContent.lastUpdated),
      ...LegalContent.privacySections,
      (
        title: 'Contact Us',
        body: 'Email: ${AppInfo.privacyEmail}\n'
            'Website: ${AppInfo.website}\n'
            'Address: ${AppInfo.companyAddress}',
      ),
    ];

    return LegalScreenBase(
      title: 'Privacy Policy',
      subtitle: 'Last updated ${LegalContent.lastUpdated}',
      accentColor: const Color(0xFF5F2D82),
      sections: sections,
    );
  }
}
