import 'package:flutter/material.dart';
import '../../../core/constants/legal_content.dart';
import '_legal_screen_base.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (title: 'Last Updated', body: LegalContent.lastUpdated),
      ...LegalContent.termsSections,
    ];

    return LegalScreenBase(
      title: 'Terms of Service',
      subtitle: 'Last updated ${LegalContent.lastUpdated}',
      accentColor: const Color(0xFF5F2D82),
      sections: sections,
    );
  }
}
