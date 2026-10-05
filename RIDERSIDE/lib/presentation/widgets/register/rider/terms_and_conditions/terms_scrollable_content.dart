import 'package:flutter/material.dart';
import '../../../../../core/constants/affiliate_terms.dart';
import '../../../../../core/utils/utils.dart';

/// The scrollable terms and conditions text container with a purple accent line.
class TermsScrollableContent extends StatelessWidget {
  final String? content;
  const TermsScrollableContent({super.key, this.content});

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
              child: content != null
                  ? SelectableText(
                      content!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        height: 1.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          context,
                          'Rider Terms and Conditions',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        _buildSectionText(context, AffiliateTerms.rider),
                        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                        _buildSectionTitle(
                          context,
                          'Partner Terms and Conditions',
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        _buildSectionText(context, AffiliateTerms.partner),
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
