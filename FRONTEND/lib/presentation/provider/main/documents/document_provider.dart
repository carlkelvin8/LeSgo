import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/document_remote_datasource.dart';

class DocumentState {
  final List<DocumentVerificationDto> documents;
  final List<DocumentTypeDto> types;
  final DocumentVerificationStatusDto? status;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const DocumentState({
    this.documents = const [],
    this.types = const [],
    this.status,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  DocumentState copyWith({
    List<DocumentVerificationDto>? documents,
    List<DocumentTypeDto>? types,
    DocumentVerificationStatusDto? status,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      types: types ?? this.types,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  DocumentNotifier() : super(const DocumentState(isLoading: true)) {
    loadAll();
  }

  final DocumentRemoteDataSource _dataSource = getIt<DocumentRemoteDataSource>();
  final FileUploadService _uploadService = getIt<FileUploadService>();

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _dataSource.getMyDocuments(),
        _dataSource.getDocumentTypes(),
        _dataSource.getVerificationStatus(),
      ]);
      state = state.copyWith(
        documents: results[0] as List<DocumentVerificationDto>,
        types: results[1] as List<DocumentTypeDto>,
        status: results[2] as DocumentVerificationStatusDto,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load documents.',
          fallbackTl: 'Hindi ma-load ang documents.',
        ),
      );
    }
  }

  Future<List<String>> uploadDocumentFiles(List<XFile> files) async {
    return _uploadService.uploadFiles(
      files,
      context: 'document',
      uploadPath: '/v1/documents/upload',
    );
  }

  Future<bool> submitDocument({
    required String documentType,
    required String documentNumber,
    required List<String> documentUrls,
    String? description,
    String? expiryDate,
  }) async {
    if (documentUrls.isEmpty) {
      state = state.copyWith(
        error: 'At least one document image is required.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _dataSource.submitDocument(
        documentType: documentType,
        documentNumber: documentNumber,
        documentUrls: documentUrls,
        description: description,
        expiryDate: expiryDate,
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not submit document.',
          fallbackTl: 'Hindi ma-submit ang document.',
        ),
      );
      return false;
    }
  }
}

final documentProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier();
});
