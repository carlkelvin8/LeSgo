import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/legal_content.dart';
import '../../../../core/utils/google_auth_helper.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class TermsContent extends ConsumerWidget {
  const TermsContent({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'SIGN UP'),
          SizedBox(height: ResponsiveUtils.spacing(context, 40)),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 3,
              radius: const Radius.circular(0),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  right: ResponsiveUtils.spacing(context, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground(context, Colors.black87),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      'Last updated: ${LegalContent.lastUpdated}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    ...LegalContent.termsSections.map(
                      (section) => Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveUtils.spacing(context, 16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 15),
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground(context, Colors.black87),
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 8),
                            ),
                            Text(
                              section.body,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: AppColors.foreground(context, Colors.grey[700]!),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          SocialLoginButton(
            text: 'Sign up with Google',
            iconUrl: 'https://www.google.com/favicon.ico',
            iconData: Icons.g_mobiledata,
            onPressed: () => GoogleAuthHelper.signIn(
              context,
              ref,
              mode: GoogleAuthMode.signup,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          DualActionButtons(
            primaryText: 'Accept',
            secondaryText: 'Decline',
            primaryIcon: Icons.check,
            secondaryIcon: Icons.close,
            onPrimaryPressed: onAccept,
            onSecondaryPressed: onDecline,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
      ),
    );
  }
}
