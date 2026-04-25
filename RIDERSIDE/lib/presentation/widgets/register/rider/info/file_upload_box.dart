import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class RiderFileUploadBox extends StatelessWidget {
  final String buttonText;
  final VoidCallback onUploadPressed;
  final bool isLoading;
  final String? filePath;
  final bool showError;

  const RiderFileUploadBox({
    super.key,
    required this.buttonText,
    required this.onUploadPressed,
    this.isLoading = false,
    this.filePath,
    this.showError = false,
  });

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onUploadPressed,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 12),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: (showError && filePath == null)
                ? Colors.red.shade300
                : Colors.black26,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF5F2D82),
                  ),
                ),
              )
            else
              Icon(
                filePath != null
                    ? Icons.insert_drive_file
                    : Icons.file_upload_outlined,
                size: 20,
                color: filePath != null
                    ? const Color(0xFF5F2D82)
                    : Colors.black54,
              ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            Expanded(
              child: Text(
                filePath != null ? _getFileName(filePath!) : buttonText,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w400,
                  color: filePath != null
                      ? const Color(0xFF5F2D82)
                      : Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
