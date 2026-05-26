import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

/// Placeholder until loyalty redemption API is live.
class LoyaltyRedeemScreen extends StatelessWidget {
  const LoyaltyRedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Redeem Points',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 72,
              color: Colors.purple.shade200,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Text(
              'Coming soon',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 22),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5F2D82),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              'Loyalty redemption is on the way. Keep earning points from missions '
              'and referrals — you\'ll be able to redeem them for vouchers and '
              'LesPay credits here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 28)),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5F2D82),
                side: const BorderSide(color: Color(0xFF5F2D82)),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 32),
                  vertical: ResponsiveUtils.spacing(context, 12),
                ),
              ),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
