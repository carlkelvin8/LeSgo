class RiderDocuments {
  final String? selfieImagePath;
  final String? selfieWithMotorcycleImagePath;
  final String? resumeFilePath;
  final String? barangayClearanceFilePath;
  final String? driversLicenseFilePath;
  final String? motorcycleORCRImagePath;
  final String? scannedORCRFilePath;
  final String? digitalSignatureFilePath;

  const RiderDocuments({
    this.selfieImagePath,
    this.selfieWithMotorcycleImagePath,
    this.resumeFilePath,
    this.barangayClearanceFilePath,
    this.driversLicenseFilePath,
    this.motorcycleORCRImagePath,
    this.scannedORCRFilePath,
    this.digitalSignatureFilePath,
  });

  RiderDocuments copyWith({
    String? selfieImagePath,
    String? selfieWithMotorcycleImagePath,
    String? resumeFilePath,
    String? barangayClearanceFilePath,
    String? driversLicenseFilePath,
    String? motorcycleORCRImagePath,
    String? scannedORCRFilePath,
    String? digitalSignatureFilePath,
  }) {
    return RiderDocuments(
      selfieImagePath: selfieImagePath ?? this.selfieImagePath,
      selfieWithMotorcycleImagePath:
          selfieWithMotorcycleImagePath ?? this.selfieWithMotorcycleImagePath,
      resumeFilePath: resumeFilePath ?? this.resumeFilePath,
      barangayClearanceFilePath:
          barangayClearanceFilePath ?? this.barangayClearanceFilePath,
      driversLicenseFilePath:
          driversLicenseFilePath ?? this.driversLicenseFilePath,
      motorcycleORCRImagePath:
          motorcycleORCRImagePath ?? this.motorcycleORCRImagePath,
      scannedORCRFilePath: scannedORCRFilePath ?? this.scannedORCRFilePath,
      digitalSignatureFilePath:
          digitalSignatureFilePath ?? this.digitalSignatureFilePath,
    );
  }

  bool get isComplete {
    return selfieImagePath != null &&
        selfieWithMotorcycleImagePath != null &&
        resumeFilePath != null &&
        barangayClearanceFilePath != null &&
        driversLicenseFilePath != null &&
        motorcycleORCRImagePath != null &&
        scannedORCRFilePath != null &&
        digitalSignatureFilePath != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'selfieImagePath': selfieImagePath,
      'selfieWithMotorcycleImagePath': selfieWithMotorcycleImagePath,
      'resumeFilePath': resumeFilePath,
      'barangayClearanceFilePath': barangayClearanceFilePath,
      'driversLicenseFilePath': driversLicenseFilePath,
      'motorcycleORCRImagePath': motorcycleORCRImagePath,
      'scannedORCRFilePath': scannedORCRFilePath,
      'digitalSignatureFilePath': digitalSignatureFilePath,
    };
  }

  factory RiderDocuments.fromJson(Map<String, dynamic> json) {
    return RiderDocuments(
      selfieImagePath: json['selfieImagePath'] as String?,
      selfieWithMotorcycleImagePath:
          json['selfieWithMotorcycleImagePath'] as String?,
      resumeFilePath: json['resumeFilePath'] as String?,
      barangayClearanceFilePath: json['barangayClearanceFilePath'] as String?,
      driversLicenseFilePath: json['driversLicenseFilePath'] as String?,
      motorcycleORCRImagePath: json['motorcycleORCRImagePath'] as String?,
      scannedORCRFilePath: json['scannedORCRFilePath'] as String?,
      digitalSignatureFilePath: json['digitalSignatureFilePath'] as String?,
    );
  }

  factory RiderDocuments.empty() {
    return const RiderDocuments();
  }
}
