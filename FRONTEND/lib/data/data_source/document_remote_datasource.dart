import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

@lazySingleton
class DocumentRemoteDataSource {
  final DioClient _dioClient;

  DocumentRemoteDataSource(this._dioClient);

  Future<List<DocumentVerificationDto>> getMyDocuments({
    int perPage = 30,
  }) async {
    final response = await _dioClient.dio.get(
      ApiConstants.documentsMy,
      queryParameters: {'per_page': perPage},
    );
    return _parseList(response.data);
  }

  Future<List<DocumentTypeDto>> getDocumentTypes() async {
    final response = await _dioClient.dio.get(ApiConstants.documentsTypes);
    final raw = response.data['data'] as List? ?? [];
    return raw
        .map((e) => DocumentTypeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentVerificationStatusDto> getVerificationStatus() async {
    final response = await _dioClient.dio.get(
      ApiConstants.documentsVerificationStatus,
    );
    return DocumentVerificationStatusDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<DocumentVerificationDto> submitDocument({
    required String documentType,
    required String documentNumber,
    required List<String> documentUrls,
    String? description,
    String? expiryDate,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.documentsSubmit,
      data: {
        'document_type': documentType,
        'document_number': documentNumber,
        'document_urls': documentUrls,
        if (description != null) 'description': description,
        if (expiryDate != null) 'expiry_date': expiryDate,
      },
    );
    return DocumentVerificationDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<DocumentVerificationDto> submitIdentityOnboarding({
    required XFile selfie,
    required String idType,
    required String idNumber,
    required XFile validIdFront,
    required XFile validIdBack,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.documentsIdentityOnboarding,
      data: FormData.fromMap({
        'selfie': await _multipartFile(selfie),
        'id_type': idType,
        'id_number': idNumber,
        'valid_id_front': await _multipartFile(validIdFront),
        'valid_id_back': await _multipartFile(validIdBack),
      }),
    );
    return DocumentVerificationDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MultipartFile> _multipartFile(XFile file) async {
    return MultipartFile.fromBytes(
      await file.readAsBytes(),
      filename: file.name.isEmpty ? 'capture.jpg' : file.name,
    );
  }

  List<DocumentVerificationDto> _parseList(dynamic body) {
    if (body is! Map<String, dynamic>) return [];
    final raw = body['data'];
    if (raw is List) {
      return raw
          .map(
            (e) => DocumentVerificationDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .map(
            (e) => DocumentVerificationDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}

class DocumentVerificationDto {
  final int id;
  final String documentType;
  final String documentNumber;
  final String status;
  final List<String> documentUrls;
  final String? description;
  final String? submittedAt;
  final String? expiresAt;

  DocumentVerificationDto({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.documentUrls,
    this.description,
    this.submittedAt,
    this.expiresAt,
  });

  factory DocumentVerificationDto.fromJson(Map<String, dynamic> json) {
    return DocumentVerificationDto(
      id: (json['id'] as num).toInt(),
      documentType: json['document_type']?.toString() ?? '',
      documentNumber: json['document_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      documentUrls:
          (json['document_urls'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      description: json['description']?.toString(),
      submittedAt: json['submitted_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}

class DocumentTypeDto {
  final String type;
  final String label;
  final String description;
  final bool required;
  final bool acceptsExpiryDate;

  DocumentTypeDto({
    required this.type,
    required this.label,
    required this.description,
    required this.required,
    required this.acceptsExpiryDate,
  });

  factory DocumentTypeDto.fromJson(Map<String, dynamic> json) {
    return DocumentTypeDto(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      required: json['required'] == true,
      acceptsExpiryDate: json['accepts_expiry_date'] == true,
    );
  }
}

class DocumentVerificationStatusDto {
  final String overallStatus;
  final int verifiedCount;
  final int pendingCount;
  final int rejectedCount;
  final int totalCount;

  DocumentVerificationStatusDto({
    required this.overallStatus,
    required this.verifiedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.totalCount,
  });

  factory DocumentVerificationStatusDto.fromJson(Map<String, dynamic> json) {
    return DocumentVerificationStatusDto(
      overallStatus: json['overall_status']?.toString() ?? 'not_started',
      verifiedCount:
          ((json['verified_count'] ?? json['verified_documents']) as num?)
              ?.toInt() ??
          0,
      pendingCount:
          ((json['pending_count'] ?? json['pending_documents']) as num?)
              ?.toInt() ??
          0,
      rejectedCount:
          ((json['rejected_count'] ?? json['rejected_documents']) as num?)
              ?.toInt() ??
          0,
      totalCount:
          ((json['total_count'] ?? json['total_documents']) as num?)?.toInt() ??
          0,
    );
  }
}
