import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../data/data_source/chat_remote_datasource.dart';
import '../../../../data/data_source/dto/chat/chat_dto.dart';

class RiderInboxState {
  const RiderInboxState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  final List<ConversationDto> conversations;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  RiderInboxState copyWith({
    List<ConversationDto>? conversations,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return RiderInboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class RiderInboxNotifier extends StateNotifier<RiderInboxState> {
  RiderInboxNotifier() : super(const RiderInboxState());

  final Map<int, String> _lastMessageByConversation = {};

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final dataSource = ChatRemoteDataSource(getIt<DioClient>());
      final conversations = await dataSource.getConversations();
      final unread = await dataSource.getUnreadCount();

      if (silent) {
        for (final conv in conversations) {
          final latest = conv.latestMessage?.content ?? '';
          final previous = _lastMessageByConversation[conv.id];
          if (previous != null &&
              previous != latest &&
              latest.isNotEmpty) {
            PushNotificationService.show(
              title: conv.customer?.name ?? 'New message',
              body: latest,
              payload: conv.orderId != null && conv.orderId! > 0
                  ? 'chat_order_${conv.orderId}'
                  : 'chat_${conv.id}',
              channelId: 'lezgo_chat',
              channelName: 'Chat Messages',
            );
          }
          _lastMessageByConversation[conv.id] = latest;
        }
      } else {
        for (final conv in conversations) {
          _lastMessageByConversation[conv.id] =
              conv.latestMessage?.content ?? '';
        }
      }

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        unreadCount: unread,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }
}

final riderInboxProvider =
    StateNotifierProvider<RiderInboxNotifier, RiderInboxState>(
  (ref) => RiderInboxNotifier(),
);
