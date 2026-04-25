import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';
import 'info_section_label.dart';
import 'selfie_upload_box.dart';

class SelfieUploadSection extends StatelessWidget {
  final String label;
  final String buttonText;
  final VoidCallback onUploadPressed;
  final bool isLoading;
  final String? imagePath;
  final bool showError;

  const SelfieUploadSection({
    super.key,
    required this.label,
    required this.buttonText,
    required this.onUploadPressed,
    this.isLoading = false,
    this.imagePath,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSectionLabel(label: label),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        SelfieUploadBox(
          buttonText: buttonText,
          onUploadPressed: onUploadPressed,
          isLoading: isLoading,
          imagePath: imagePath,
          showError: showError,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
      ],
    );
  }
}
