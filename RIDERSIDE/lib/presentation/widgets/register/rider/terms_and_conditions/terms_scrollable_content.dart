import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

/// The scrollable terms and conditions text container with a purple accent line.
class TermsScrollableContent extends StatelessWidget {
  const TermsScrollableContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Scrollable Text Content
          Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.spacing(context, 16),
              top: ResponsiveUtils.spacing(context, 16),
              right: ResponsiveUtils.spacing(context, 24),
              bottom: ResponsiveUtils.spacing(context, 16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Summary'),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  _buildSectionText(
                    context,
                    'Welcome to Lezgo Courier Service. By registering as a rider, you agree to provide delivery services on our platform. You will be responsible for timely and safe delivery of packages. All riders must maintain professional conduct and follow our guidelines.',
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                  _buildSectionTitle(context, 'Terms'),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  _buildSectionText(
                    context,
                    '1. RIDER RESPONSIBILITIES\n\n'
                    'You agree to accept delivery requests within your availability and complete them in a timely manner. You must have a valid vehicle registration, driver\'s license, and insurance.\n\n'
                    '2. PAYMENT AND EARNINGS\n\n'
                    'Riders earn per delivery based on distance and complexity. Payments are processed weekly. Lezgo charges a service fee of 15% per transaction.\n\n'
                    '3. CONDUCT AND BEHAVIOR\n\n'
                    'Professional conduct is mandatory. Harassment, discrimination, or misconduct will result in immediate account suspension. Always treat customers and merchants with respect.\n\n'
                    '4. INSURANCE AND LIABILITY\n\n'
                    'Riders are responsible for their own insurance. Lezgo is not liable for accidents or damages during delivery. You must maintain valid insurance coverage at all times.\n\n'
                    '5. ACCOUNT TERMINATION\n\n'
                    'Lezgo reserves the right to suspend or terminate accounts for violation of terms, poor performance, or fraudulent activity. Riders may deactivate their account at any time.\n\n'
                    '6. DATA PRIVACY\n\n'
                    'Your personal information is protected under our privacy policy. We collect location data, delivery history, and ratings to improve service quality.\n\n'
                    '7. MODIFICATIONS\n\n'
                    'Lezgo may update these terms at any time. Continued use of the platform constitutes acceptance of modified terms.',
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                ],
              ),
            ),
          ),

          // Purple Accent Line (Right Side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5F2D82).withValues(alpha: 0.3),
                    const Color(0xFF5F2D82),
                    const Color(0xFF5F2D82).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 16),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 12),
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }
}
