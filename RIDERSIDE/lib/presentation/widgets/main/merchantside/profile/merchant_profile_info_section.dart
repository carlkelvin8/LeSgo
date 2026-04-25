import 'package:flutter/material.dart';
import '../../../../../../core/utils/helpers/fakedata.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantProfileInfoSection extends StatelessWidget {
  const MerchantProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info(context, 'Restaurant:', merchantProfileInfoData['restaurant']!),
        _info(context, 'Contact:', merchantProfileInfoData['contact']!),
        _info(context, 'Address:', merchantProfileInfoData['address']!),
        _info(
          context,
          'Referral Code:',
          merchantProfileInfoData['referralCode']!,
          valueColor: const Color(0xFFC320D6),
        ),
      ],
    );
  }

  Widget _info(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
