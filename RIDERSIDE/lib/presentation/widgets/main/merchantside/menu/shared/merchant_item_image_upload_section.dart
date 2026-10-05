import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../common/menu_image_widget.dart';

class MerchantItemImageUploadSection extends StatelessWidget {
  final VoidCallback onTap;
  final String? uploadedImagePath;

  const MerchantItemImageUploadSection({
    super.key,
    required this.onTap,
    this.uploadedImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        uploadedImagePath != null && uploadedImagePath!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: ResponsiveUtils.spacing(context, 160),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    MenuImageWidget(
                      source: uploadedImagePath,
                      fit: BoxFit.cover,
                      placeholder: _placeholder(context),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: ResponsiveUtils.fontSize(context, 32),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _placeholder(context),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Text(
                      'Tap to upload item photo',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      'JPG, PNG (Max 5MB)',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Icon(
      Icons.add_a_photo_outlined,
      size: ResponsiveUtils.fontSize(context, 48),
      color: const Color(0xFFBDBDBD),
    );
  }
}

