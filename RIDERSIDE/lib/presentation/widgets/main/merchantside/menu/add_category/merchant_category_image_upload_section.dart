import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantCategoryImageUploadSection extends StatelessWidget {
  final VoidCallback onTap;
  final String? uploadedImagePath;

  const MerchantCategoryImageUploadSection({
    super.key,
    required this.onTap,
    this.uploadedImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Image',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: ResponsiveUtils.spacing(context, 160),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: uploadedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPreview(uploadedImagePath!),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: ResponsiveUtils.spacing(context, 48),
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        Text(
                          'Tap to upload category photo',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                        Text(
                          'Recommended: 400x300px',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity);
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    }
    return Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
  }
}
