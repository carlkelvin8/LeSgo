import 'dart:io';
import 'package:flutter/material.dart';
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
    final hasImage = imagePath != null;
    final showRequiredError = showError && !hasImage;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display captured image or face outline placeholder
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath!),
                height: ResponsiveUtils.imageHeight(context, 300),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: ResponsiveUtils.imageHeight(context, 250),
              width: ResponsiveUtils.imageHeight(context, 200),
              decoration: BoxDecoration(
                color: showRequiredError
                    ? Colors.red.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: showRequiredError
                      ? Colors.red.shade400
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: ResponsiveUtils.fontSize(context, 64),
                    color: showRequiredError
                        ? Colors.red.shade300
                        : Colors.grey.shade400,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Text(
                    'Take a Live Selfie',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: showRequiredError
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    'Front camera required',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (showRequiredError) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      '⚠️ Required',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          GestureDetector(
            onTap: isLoading ? null : onUploadPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 24),
                vertical: ResponsiveUtils.spacing(context, 10),
              ),
              decoration: BoxDecoration(
                color: showRequiredError
                    ? Colors.red.shade400
                    : hasImage
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF5F2D82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasImage ? Icons.check_circle : Icons.camera_front,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasImage ? 'Retake' : buttonText,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
