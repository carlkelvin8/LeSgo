import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/utils.dart';

class SelfieUploadBox extends StatelessWidget {
  final String buttonText;
  final VoidCallback onUploadPressed;
  final bool isLoading;
  final String? imagePath;
  final bool showError;

  const SelfieUploadBox({
    super.key,
    required this.buttonText,
    required this.onUploadPressed,
    this.isLoading = false,
    this.imagePath,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display captured image or SVG placeholder
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath!),
                height: ResponsiveUtils.imageHeight(context, 300),
                fit: BoxFit.cover,
              ),
            )
          else
            SvgPicture.asset(
              'assets/images/register/10.svg',
              height: ResponsiveUtils.imageHeight(context, 300),
              fit: BoxFit.contain,
            ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          GestureDetector(
            onTap: isLoading ? null : onUploadPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 24),
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: (showError && imagePath == null) ? Colors.red.shade400 : const Color(0xFF5F2D82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      buttonText,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
