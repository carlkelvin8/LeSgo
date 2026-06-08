import 'package:dio/dio.dart';
import '../../../core/utils/multipart_file_utils.dart';
import '../dto/auth/register_merchant_request_dto.dart';

/// File field names for `/v1/auth/register` multipart uploads.
abstract final class RegisterMerchantDocumentFileFields {
  static const selfie = 'selfie';
  static const validId = 'valid_id';
  static const digitalSignature = 'digital_signature';
  static const barangayPermit = 'barangay_permit';
  static const mayorsPermit = 'mayors_permit';
  static const dtiPermit = 'dti_permit';
}

/// Server path field names paired with [RegisterMerchantDocumentFileFields].
abstract final class RegisterMerchantDocumentPathFields {
  static const selfie = 'selfie_path';
  static const validId = 'valid_id_path';
  static const digitalSignature = 'digital_signature_path';
  static const barangayPermit = 'barangay_permit_path';
  static const mayorsPermit = 'mayors_permit_path';
  static const dtiPermit = 'dti_permit_path';
}

const _pathFieldKeys = {
  RegisterMerchantDocumentFileFields.selfie:
      RegisterMerchantDocumentPathFields.selfie,
  RegisterMerchantDocumentFileFields.validId:
      RegisterMerchantDocumentPathFields.validId,
  RegisterMerchantDocumentFileFields.digitalSignature:
      RegisterMerchantDocumentPathFields.digitalSignature,
  RegisterMerchantDocumentFileFields.barangayPermit:
      RegisterMerchantDocumentPathFields.barangayPermit,
  RegisterMerchantDocumentFileFields.mayorsPermit:
      RegisterMerchantDocumentPathFields.mayorsPermit,
  RegisterMerchantDocumentFileFields.dtiPermit:
      RegisterMerchantDocumentPathFields.dtiPermit,
};

Future<FormData> buildRegisterMerchantFormData(
  RegisterMerchantRequestDto request,
  Map<String, String> documents,
) async {
  final formData = FormData();
  final fields = Map<String, dynamic>.from(request.toJson())
    ..removeWhere((_, value) => value == null)
    ..remove(RegisterMerchantDocumentPathFields.selfie)
    ..remove(RegisterMerchantDocumentPathFields.validId)
    ..remove(RegisterMerchantDocumentPathFields.digitalSignature)
    ..remove(RegisterMerchantDocumentPathFields.barangayPermit)
    ..remove(RegisterMerchantDocumentPathFields.mayorsPermit)
    ..remove(RegisterMerchantDocumentPathFields.dtiPermit);

  for (final entry in fields.entries) {
    formData.fields.add(MapEntry(entry.key, _formFieldValue(entry.value)));
  }

  for (final entry in documents.entries) {
    await appendDocumentFile(formData, entry.key, entry.value);
  }

  return formData;
}

String _fileExtension(String path) {
  final parts = path.split('.');
  if (parts.length > 1) {
    return parts.last.toLowerCase();
  }
  return 'bin';
}

String? validateRegisterMerchantDocuments(Map<String, String> documents) {
  final missing = <String>[];

  if (!documents.containsKey(RegisterMerchantDocumentFileFields.selfie)) {
    missing.add('Selfie');
  }
  if (!documents.containsKey(RegisterMerchantDocumentFileFields.validId)) {
    missing.add('Valid ID');
  }
  if (!documents.containsKey(RegisterMerchantDocumentFileFields.digitalSignature)) {
    missing.add('Digital signature');
  }
  if (!documents.containsKey(RegisterMerchantDocumentFileFields.barangayPermit)) {
    missing.add('Barangay permit');
  }
  if (!documents.containsKey(RegisterMerchantDocumentFileFields.mayorsPermit)) {
    missing.add("Mayor's permit");
  }
  if (!documents.containsKey(RegisterMerchantDocumentFileFields.dtiPermit)) {
    missing.add('DTI permit');
  }

  if (missing.isEmpty) return null;
  return 'Missing required documents: ${missing.join(', ')}';
}

String _formFieldValue(dynamic value) {
  if (value is bool) return value ? '1' : '0';
  return value.toString();
}

Map<String, String> registerMerchantDocumentsFromPaths({
  required String selfiePath,
  required String validIdPath,
  required String digitalSignaturePath,
  required String barangayPermitPath,
  required String mayorsPermitPath,
  required String dtiPermitPath,
}) {
  return {
    RegisterMerchantDocumentFileFields.selfie: selfiePath,
    RegisterMerchantDocumentFileFields.validId: validIdPath,
    RegisterMerchantDocumentFileFields.digitalSignature: digitalSignaturePath,
    RegisterMerchantDocumentFileFields.barangayPermit: barangayPermitPath,
    RegisterMerchantDocumentFileFields.mayorsPermit: mayorsPermitPath,
    RegisterMerchantDocumentFileFields.dtiPermit: dtiPermitPath,
  };
}
