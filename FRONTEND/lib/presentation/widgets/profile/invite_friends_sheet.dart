import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/referral_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class InviteFriendsSheet extends StatelessWidget {
  const InviteFriendsSheet({
    super.key,
    required this.referralCode,
    this.userName,
  });

  final String referralCode;
  final String? userName;

  static Future<void> show(
    BuildContext context, {
    required String referralCode,
    String? userName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteFriendsSheet(
        referralCode: referralCode,
        userName: userName,
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    SnackBarUtils.showSuccess(context, 'Referral code copied!');
  }

  Future<void> _share() async {
    await Share.share(
      ReferralUtils.inviteMessage(
        referralCode: referralCode,
        userName: userName,
      ),
      subject: 'Join me on ${ReferralUtils.appName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 20),
        ResponsiveUtils.spacing(context, 12),
        ResponsiveUtils.spacing(context, 20),
        ResponsiveUtils.spacing(context, 24) + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            'Invite friends',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 20),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Share your code. When friends sign up and order, you both earn points.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 20)),
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            decoration: BoxDecoration(
              color: const Color(0xFF5F2D82).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5F2D82).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralCode,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 20),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy, color: Color(0xFF5F2D82)),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          FilledButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share invite link'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
