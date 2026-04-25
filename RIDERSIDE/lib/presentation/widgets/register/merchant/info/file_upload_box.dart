import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class MerchantFileUploadBox extends StatelessWidget {
  final String? filePath;
  final VoidCallback onTap;
  final bool isLoading;
  final bool hasError;

  const MerchantFileUploadBox({
    super.key,
    this.filePath,
    required this.onTap,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.spacing(context, 16),
          horizontal: ResponsiveUtils.spacing(context, 16),
        ),
        decoration: BoxDecoration(
          color: hasError
              ? Colors.red.withValues(alpha: 0.05)
              : (filePath != null
                    ? const Color(0xFF9B6BB8).withValues(alpha: 0.05)
                    : Colors.white),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 12),
          ),
          border: Border.all(
            color: hasError
                ? Colors.red
                : (filePath != null
                      ? const Color(0xFF9B6BB8)
                      : Colors.grey.shade400),
            width: 1.5,
            style: BorderStyle
                .solid, // Fallback to solid border to avoid dependency issues
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF9B6BB8),
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filePath != null
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    color: hasError
                        ? Colors.red
                        : (filePath != null
                              ? const Color(0xFF9B6BB8)
                              : Colors.grey.shade600),
                    size: 24,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Expanded(
                    child: Text(
                      filePath != null
                          ? 'File selected: ${filePath!.split('/').last}'
                          : 'Click to upload document',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: hasError
                            ? Colors.red
                            : (filePath != null
                                  ? const Color(0xFF9B6BB8)
                                  : Colors.grey.shade600),
                        fontWeight: filePath != null
                            ? FontWeight.w600
                            : FontWeight.w400,
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
