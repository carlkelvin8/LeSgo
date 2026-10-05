import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/dto/support/support_dto.dart';
import '../../../../data/data_source/support_remote_datasource.dart';

class SupportState {
  final List<SupportTicketDto> tickets;
  final bool isLoading;
  final String? error;

  const SupportState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  SupportState copyWith({
    List<SupportTicketDto>? tickets,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SupportNotifier extends StateNotifier<SupportState> {
  SupportNotifier() : super(const SupportState(isLoading: true)) {
    loadTickets();
  }

  final SupportRemoteDataSource _dataSource = getIt<SupportRemoteDataSource>();
  final FileUploadService _uploadService = getIt<FileUploadService>();

  Future<void> loadTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _dataSource.getTickets();
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load support tickets.',
          fallbackTl: 'Hindi ma-load ang support tickets.',
        ),
      );
    }
  }

  Future<List<String>> uploadAttachments(List<XFile> files) {
    return _uploadService.uploadFiles(
      files,
      context: 'support',
      uploadPath: ApiConstants.supportUpload,
    );
  }

  Future<bool> createTicket(
    CreateTicketDto request, {
    List<XFile>? attachments,
  }) async {
    try {
      List<String>? attachmentUrls;
      if (attachments != null && attachments.isNotEmpty) {
        attachmentUrls = await uploadAttachments(attachments);
      }
      await _dataSource.createTicket(request, attachments: attachmentUrls);
      await loadTickets();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not create ticket.',
          fallbackTl: 'Hindi makagawa ng ticket.',
        ),
      );
      return false;
    }
  }
}

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((
  ref,
) {
  ref.watch(userSessionEpochProvider);
  return SupportNotifier();
});
