import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';

class MerchantDocumentUploadList extends StatelessWidget {
  final VoidCallback onUploadSelfie;
  final VoidCallback onUploadValidId;
  final VoidCallback onUploadDigitalSignature;
  final VoidCallback onUploadBarangayPermit;
  final VoidCallback onUploadMayorsPermit;
  final VoidCallback onUploadDtiPermit;

  final bool isSelfieLoading;
  final bool isValidIdLoading;
  final bool isSignatureLoading;
  final bool isBarangayPermitLoading;
  final bool isMayorsPermitLoading;
  final bool isDtiPermitLoading;

  final String? selfiePath;
  final String? validIdPath;
  final String? digitalSignaturePath;
  final String? barangayPermitPath;
  final String? mayorsPermitPath;
  final String? dtiPermitPath;

  final bool showError;

  const MerchantDocumentUploadList({
    super.key,
    required this.onUploadSelfie,
    required this.onUploadValidId,
    required this.onUploadDigitalSignature,
    required this.onUploadBarangayPermit,
    required this.onUploadMayorsPermit,
    required this.onUploadDtiPermit,
    required this.isSelfieLoading,
    required this.isValidIdLoading,
    required this.isSignatureLoading,
    required this.isBarangayPermitLoading,
    required this.isMayorsPermitLoading,
    required this.isDtiPermitLoading,
    this.selfiePath,
    this.validIdPath,
    this.digitalSignaturePath,
    this.barangayPermitPath,
    this.mayorsPermitPath,
    this.dtiPermitPath,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildUploadSection(
          context,
          'Selfie of owner in front of the establishment',
          onUploadSelfie,
          isSelfieLoading,
          selfiePath,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _buildUploadSection(
          context,
          'Picture of Owner\'s Valid ID',
          onUploadValidId,
          isValidIdLoading,
          validIdPath,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _buildUploadSection(
          context,
          'Digital Signature of the Owner',
          onUploadDigitalSignature,
          isSignatureLoading,
          digitalSignaturePath,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _buildUploadSection(
          context,
          'Scanned Copy of Barangay Permit',
          onUploadBarangayPermit,
          isBarangayPermitLoading,
          barangayPermitPath,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _buildUploadSection(
          context,
          'Scanned Copy of Mayor\'s Permit',
          onUploadMayorsPermit,
          isMayorsPermitLoading,
          mayorsPermitPath,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _buildUploadSection(
          context,
          'Scanned Copy of DTI Permit',
          onUploadDtiPermit,
          isDtiPermitLoading,
          dtiPermitPath,
        ),
      ],
    );
  }

  Widget _buildUploadSection(
    BuildContext context,
    String label,
    VoidCallback onUpload,
    bool isLoading,
    String? filePath,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        MerchantFileUploadBox(
          filePath: filePath,
          onTap: onUpload,
          isLoading: isLoading,
          hasError: showError && filePath == null,
        ),
      ],
    );
  }
}
