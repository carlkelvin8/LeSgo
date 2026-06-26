import 'package:flutter/material.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/legal_content.dart';

/// Privacy Policy Screen
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
            _buildSection('Last Updated', LegalContent.lastUpdated),
            const SizedBox(height: 24),
            for (final section in LegalContent.privacySections) ...[
              _buildSection(section.title, section.body),
              const SizedBox(height: 24),
            ],
            _buildSection(
              'Contact',
              'Email: ${AppInfo.privacyEmail}\n'
              'Website: ${AppInfo.website}\n'
              'Address: ${AppInfo.companyAddress}',
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
