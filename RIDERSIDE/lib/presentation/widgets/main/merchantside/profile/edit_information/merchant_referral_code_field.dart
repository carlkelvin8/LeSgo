import 'package:flutter/material.dart';
import '../../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantReferralCodeField extends StatelessWidget {
  const MerchantReferralCodeField({
    super.key,
    required this.controller,
    required this.onCopyTap,
  });

  final TextEditingController controller;
  final VoidCallback onCopyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('REFERRAL CODE'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 11),
            fontWeight: FontWeight.w700,
            color: context.acc(const Color(0xFF5A2E79)),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.surf(const Color(0xFFE9E4EC)),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 14),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w500,
                    color: context.txt(const Color(0xFF2B2530)),
                    letterSpacing: 1.8,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 14),
                      vertical: ResponsiveUtils.spacing(context, 16),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCopyTap,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: ResponsiveUtils.spacing(context, 14),
                  ),
                  child: Icon(
                    Icons.content_copy_rounded,
                    size: ResponsiveUtils.spacing(context, 20),
                    color: context.acc(const Color(0xFF5A1D8D)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}