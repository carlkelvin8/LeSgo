import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../common/menu_image_widget.dart';

class MerchantFoodCategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final String? imageUrl;
  final bool isSelected;

  const MerchantFoodCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.imageUrl,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? const Color(0xFFE6E6E6)
        : const Color(0xFFF0F0F0);
    final avatarSize = ResponsiveUtils.spacing(context, 42);

    return Container(
      width: ResponsiveUtils.spacing(context, 74),
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 10),
        horizontal: ResponsiveUtils.spacing(context, 8),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl!.trim().isNotEmpty
                ? MenuImageWidget(
                    source: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: _emojiIcon(context),
                  )
                : _emojiIcon(context),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 10),
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiIcon(BuildContext context) {
    return Center(
      child: Text(
        icon,
        style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 22)),
      ),
    );
  }
}
