import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'profile_referral_card.dart';
import 'profile_points_card.dart';

class ProfileRewardsSection extends StatelessWidget {
  final String referralCode;
  final int points;
  final String? userName;

  const ProfileRewardsSection({
    super.key,
    required this.referralCode,
    required this.points,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ProfileReferralCard(
            referralCode: referralCode,
            userName: userName,
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ProfilePointsCard(
            points: points,
          ),
        ),
      ],
    );
  }
}
