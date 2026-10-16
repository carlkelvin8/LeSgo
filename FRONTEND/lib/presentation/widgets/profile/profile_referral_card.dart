import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'invite_friends_sheet.dart';

class ProfileReferralCard extends StatelessWidget {
  final String referralCode;
  final String? userName;
  final VoidCallback? onCopy;

  const ProfileReferralCard({
    super.key,
    required this.referralCode,
    this.userName,
    this.onCopy,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    SnackBarUtils.showSuccess(context, 'Referral code copied!');
    onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Color(0xFFEFE8F8)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Expanded(
                child: Text(
                  'Good things\nare better shared.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.7,
                    color: Color(0xFF422759),
                  ),
                ),
              ),
              SizedBox(width: 10),
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.surface(context, Colors.white),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF8052A6),
                  size: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
           Text(
            'Invite your friends and earn points\nwhen they join LeSgo.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              height: 1.6,
              color: AppColors.foreground(context, Color(0xFF786387)),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: referralCode.isEmpty ? null : () => _copy(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'YOUR INVITE CODE',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 8,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground(context, Color(0xFF92819F)),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            referralCode.isEmpty
                                ? 'Not available yet'
                                : referralCode,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF422759),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: Color(0xFF8052A6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: referralCode.isEmpty
                  ? null
                  : () => InviteFriendsSheet.show(
                      context,
                      referralCode: referralCode,
                      userName: userName,
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF603A80),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Invite a friend',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () =>
                  AppRouter.push(context, MainRoutes.referralDashboard),
              child:  Text(
                'View referral rewards',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: AppColors.foreground(context, Color(0xFF786387)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
