import 'package:flutter/material.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
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
    return Column(
      children: [
        ProfileReferralCard(
          referralCode: referralCode,
          userName: userName,
        ),
        const SizedBox(height: 12),
        ProfilePointsCard(
          points: points,
          onTap: () => AppRouter.push(context, MainRoutes.loyaltyRedeem),
        ),
      ],
    );
  }
}
