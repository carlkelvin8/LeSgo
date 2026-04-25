import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';
import '../../../widgets.dart';

class DocumentUploadSection extends StatelessWidget {
  final String label;
  final String buttonText;
  final VoidCallback onUploadPressed;
  final bool isLoading;
  final String? filePath;
  final bool showError;

  const DocumentUploadSection({
    super.key,
    required this.label,
    required this.buttonText,
    required this.onUploadPressed,
    this.isLoading = false,
    this.filePath,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSectionLabel(label: label),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        RiderFileUploadBox(
          buttonText: buttonText,
          onUploadPressed: onUploadPressed,
          isLoading: isLoading,
          filePath: filePath,
          showError: showError,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 20)),
      ],
    );
  }
}
