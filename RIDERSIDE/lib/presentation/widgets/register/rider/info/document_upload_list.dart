import 'package:flutter/material.dart';
import 'document_upload_section.dart';

/// Groups all document upload fields together.
/// Reads upload state and delegates actions to callbacks.
class DocumentUploadList extends StatelessWidget {
  final VoidCallback onUploadResume;
  final VoidCallback onUploadBarangayClearance;
  final VoidCallback onUploadDriversLicense;
  final VoidCallback onUploadMotorcycleORCRImage;
  final VoidCallback onUploadScannedORCR;
  final VoidCallback onUploadDigitalSignature;
  final bool isResumeLoading;
  final bool isClearanceLoading;
  final bool isLicenseLoading;
  final bool isMotorcycleImageLoading;
  final bool isScannedORCRLoading;
  final bool isSignatureLoading;
  final String? resumeFilePath;
  final String? barangayClearanceFilePath;
  final String? driversLicenseFilePath;
  final String? motorcycleORCRImagePath;
  final String? scannedORCRFilePath;
  final String? digitalSignatureFilePath;
  final bool showError;

  const DocumentUploadList({
    super.key,
    required this.onUploadResume,
    required this.onUploadBarangayClearance,
    required this.onUploadDriversLicense,
    required this.onUploadMotorcycleORCRImage,
    required this.onUploadScannedORCR,
    required this.onUploadDigitalSignature,
    this.isResumeLoading = false,
    this.isClearanceLoading = false,
    this.isLicenseLoading = false,
    this.isMotorcycleImageLoading = false,
    this.isScannedORCRLoading = false,
    this.isSignatureLoading = false,
    this.resumeFilePath,
    this.barangayClearanceFilePath,
    this.driversLicenseFilePath,
    this.motorcycleORCRImagePath,
    this.scannedORCRFilePath,
    this.digitalSignatureFilePath,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentUploadSection(
          label: 'Resume/Biodata',
          buttonText: 'upload',
          onUploadPressed: onUploadResume,
          isLoading: isResumeLoading,
          filePath: resumeFilePath,
          showError: showError,
        ),
        DocumentUploadSection(
          label: 'Scanned barangay clearance',
          buttonText: 'upload',
          onUploadPressed: onUploadBarangayClearance,
          isLoading: isClearanceLoading,
          filePath: barangayClearanceFilePath,
          showError: showError,
        ),
        DocumentUploadSection(
          label: 'Scanned drivers license',
          buttonText: 'upload',
          onUploadPressed: onUploadDriversLicense,
          isLoading: isLicenseLoading,
          filePath: driversLicenseFilePath,
          showError: showError,
        ),
        DocumentUploadSection(
          label: 'Picture of motorcycle OR/CR',
          buttonText: 'upload',
          onUploadPressed: onUploadMotorcycleORCRImage,
          isLoading: isMotorcycleImageLoading,
          filePath: motorcycleORCRImagePath,
          showError: showError,
        ),
        DocumentUploadSection(
          label: 'Scanned copy of motorcycle OR/CR',
          buttonText: 'upload',
          onUploadPressed: onUploadScannedORCR,
          isLoading: isScannedORCRLoading,
          filePath: scannedORCRFilePath,
          showError: showError,
        ),
        DocumentUploadSection(
          label: 'Digital Signature',
          buttonText: 'upload',
          onUploadPressed: onUploadDigitalSignature,
          isLoading: isSignatureLoading,
          filePath: digitalSignatureFilePath,
          showError: showError,
        ),
      ],
    );
  }
}
