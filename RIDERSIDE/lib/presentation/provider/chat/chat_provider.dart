import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/chat_realtime_service.dart';
import '../../../core/services/chat_websocket_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../data/data_source/chat_remote_datasource.dart';
import '../../../data/data_source/dto/chat/chat_dto.dart';

final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(getIt<DioClient>());
});

class ChatState {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final ConversationDto? currentConversation;
  final List<MessageDto> messages;
  final int unreadCount;

  ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.currentConversation,
    this.messages = const [],
    this.unreadCount = 0,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
    ConversationDto? currentConversation,
    List<MessageDto>? messages,
    int? unreadCount,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRemoteDataSource _chatDataSource;
  Timer? _pollTimer;
  Timer? _typingDebounce;
  void Function()? _realtimeListener;

  ChatNotifier(this._chatDataSource) : super(ChatState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
    }
    unawaited(ChatRealtimeService.instance.release());
    super.dispose();
  }

  Future<void> getOrCreateConversation(int orderId) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversation =
          await _chatDataSource.getOrCreateConversation(orderId);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        currentConversation: conversation,
      );

      await loadMessages();
      if (mounted) await _startRealtime(conversation.id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load chat: ${e.toString()}',
      );
    }
  }

  Future<void> _startRealtime(int conversationId) async {
    _pollTimer?.cancel();
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
    }

    _realtimeListener = () {
      if (mounted) loadMessages(silent: true);
    };
    ChatRealtimeService.instance.addListener(_realtimeListener!);
    await ChatRealtimeService.instance.acquire(conversationId: conversationId);

    final interval = FcmService.instance.isReady
        ? const Duration(seconds: 30)
        : const Duration(seconds: 8);
    _pollTimer = Timer.periodic(interval, (_) {
      if (mounted && !ChatWebSocketService.instance.isConnected) {
        loadMessages(silent: true);
      }
    });
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!mounted || state.currentConversation == null) return;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final messages = await _chatDataSource.getMessages(
        state.currentConversation!.id,
      );
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        messages: messages,
      );
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<bool> sendMessage(String message) async {
    if (!mounted ||
        state.currentConversation == null ||
        message.trim().isEmpty) {
      return false;
    }

    state = state.copyWith(isSending: true);

    try {
      final request = SendMessageDto(
        conversationId: state.currentConversation!.id,
        message: message.trim(),
      );

      await _chatDataSource.sendMessage(request);
      if (!mounted) return false;

      await loadMessages(silent: true);
      if (!mounted) return false;
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadUnreadCount() async {
    if (!mounted) return;
    try {
      final count = await _chatDataSource.getUnreadCount();
      if (!mounted) return;
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> markAsRead() async {
    if (!mounted || state.currentConversation == null) return;
    try {
      await _chatDataSource.markAsRead(state.currentConversation!.id);
      await loadUnreadCount();
    } catch (_) {}
  }

  void notifyTyping() {
    if (!mounted || state.currentConversation == null) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted || state.currentConversation == null) return;
      try {
        await _chatDataSource.sendTypingIndicator(
          state.currentConversation!.id,
        );
      } catch (_) {}
    });
  }

  Future<bool> endConversation() async {
    if (!mounted || state.currentConversation == null) return false;
    try {
      await _chatDataSource.endConversation(state.currentConversation!.id);
      clearConversation();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return false;
    }
  }

  Future<bool> report({
    required String reason,
    String? details,
    int? messageId,
    bool block = false,
  }) async {
    final conversation = state.currentConversation;
    if (!mounted || conversation == null) return false;
    try {
      await _chatDataSource.reportConversation(
        conversation.id,
        reason: reason,
        details: details,
        messageId: messageId,
        block: block,
      );
      if (block && mounted) {
        state = state.copyWith(
          currentConversation: conversation.copyWithBlockState(
            blockedByMe: true,
            canMessage: false,
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setBlocked(bool blocked) async {
    final conversation = state.currentConversation;
    if (!mounted || conversation == null) return false;
    try {
      final canMessage = blocked
          ? await _chatDataSource.blockUser(conversation.id)
          : await _chatDataSource.unblockUser(conversation.id);
      if (!mounted) return false;
      state = state.copyWith(
        currentConversation: conversation.copyWithBlockState(
          blockedByMe: blocked,
          canMessage: canMessage,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearConversation() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
      _realtimeListener = null;
    }
    unawaited(ChatRealtimeService.instance.release());
    state = ChatState();
  }
}

final chatProviderFamily =
    StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, orderId) {
  final dataSource = ref.watch(chatDataSourceProvider);
  return ChatNotifier(dataSource);
});

class ChatUnreadCountNotifier extends StateNotifier<int> {
  ChatUnreadCountNotifier(this._chatDataSource) : super(0) {
    refresh();
  }

  final ChatRemoteDataSource _chatDataSource;

  Future<void> refresh() async {
    try {
      final count = await _chatDataSource.getUnreadCount();
      if (mounted) state = count;
    } catch (_) {}
  }
}

final unreadCountProvider =
    StateNotifierProvider<ChatUnreadCountNotifier, int>((ref) {
  return ChatUnreadCountNotifier(ref.watch(chatDataSourceProvider));
});
