import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantLiveOnMenuToggleSection extends StatelessWidget {
  final bool isLive;
  final ValueChanged<bool> onChanged;

  const MerchantLiveOnMenuToggleSection({
    super.key,
    required this.isLive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFEAD3F7).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.brd(const Color(0xFFEAD3F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Live on Menu'),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w700,
                    color: context.acc(const Color(0xFF5F2D82)),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  context.tr('Make this item visible to customers'),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: context.txt(Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isLive,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF5F2D82),
            activeTrackColor: const Color(0xFFEAD3F7),
          ),
        ],
      ),
    );
  }
}
