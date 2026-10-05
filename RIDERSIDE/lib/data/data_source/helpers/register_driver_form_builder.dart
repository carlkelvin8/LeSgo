import 'package:dio/dio.dart';
import '../../../core/utils/multipart_file_utils.dart';
import '../dto/auth/register_driver_request_dto.dart';

/// API field names for `/v1/drivers/register` multipart uploads.
abstract final class RegisterDriverDocumentFields {
  static const selfie = 'selfie';
  static const selfieWithMotorcycle = 'selfie_with_motorcycle';
  static const resume = 'resume';
  static const barangayClearance = 'barangay_clearance';
  static const driversLicense = 'drivers_license';
  static const motorcycleOrcr = 'motorcycle_orcr';
  static const scannedOrcr = 'scanned_orcr';
  static const digitalSignature = 'digital_signature';
}

Future<FormData> buildRegisterDriverFormData(
  RegisterDriverRequestDto request,
  Map<String, String> documents,
) async {
  final formData = FormData();
  final fields = Map<String, dynamic>.from(request.toJson())
    ..removeWhere(
      (_, value) => value == null || (value is String && value.trim().isEmpty),
    );

  for (final entry in fields.entries) {
    formData.fields.add(MapEntry(entry.key, entry.value is bool ? (entry.value == true ? '1' : '0') : entry.value.toString()));
  }

  for (final entry in documents.entries) {
    await appendDocumentFile(formData, entry.key, entry.value);
  }

  return formData;
}

Map<String, String> registerDriverDocumentsFromPaths({
  required String selfiePath,
  required String selfieWithMotorcyclePath,
  required String resumePath,
  required String barangayClearancePath,
  required String driversLicensePath,
  required String motorcycleOrcrPath,
  required String scannedOrcrPath,
  required String digitalSignaturePath,
}) {
  return {
    RegisterDriverDocumentFields.selfie: selfiePath,
    RegisterDriverDocumentFields.selfieWithMotorcycle: selfieWithMotorcyclePath,
    RegisterDriverDocumentFields.resume: resumePath,
    RegisterDriverDocumentFields.barangayClearance: barangayClearancePath,
    RegisterDriverDocumentFields.driversLicense: driversLicensePath,
    RegisterDriverDocumentFields.motorcycleOrcr: motorcycleOrcrPath,
    RegisterDriverDocumentFields.scannedOrcr: scannedOrcrPath,
    RegisterDriverDocumentFields.digitalSignature: digitalSignaturePath,
  };
}

String? validateRegisterDriverDocuments(Map<String, String> documents) {
  final signaturePath =
      documents[RegisterDriverDocumentFields.digitalSignature];
  if (signaturePath == null) {
    return 'Digital signature is required.';
  }

  final extension = signaturePath.split('.').last.toLowerCase();
  if (extension != 'pdf') {
    return 'Digital signature must be uploaded as a PDF file.';
  }

  return null;
}
