import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/chat_realtime_service.dart';
import '../../../core/services/chat_websocket_service.dart';
import '../../../core/services/api_service.dart';
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
  bool _realtimeAcquired = false;

  ChatNotifier(this._chatDataSource) : super(ChatState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
    }
    _releaseRealtime();
    super.dispose();
  }

  /// Releases the shared realtime service exactly once per acquire, so a chat
  /// that never loaded (or was already stopped) cannot drop another chat's hold.
  void _releaseRealtime() {
    if (!_realtimeAcquired) return;
    _realtimeAcquired = false;
    unawaited(ChatRealtimeService.instance.release());
  }

  /// Stops polling/realtime without touching state (safe to call from a
  /// screen's dispose). The provider is not auto-disposed, so without this the
  /// poll timer and websocket subscription outlive the chat screen.
  void stopRealtime() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _typingDebounce?.cancel();
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
      _realtimeListener = null;
    }
    _releaseRealtime();
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
        error: 'Could not load chat: ${ApiService.extractError(e)}',
      );
    }
  }

  Future<void> _startRealtime(int conversationId) async {
    _pollTimer?.cancel();
    _releaseRealtime(); // never hold two acquires for one notifier
    if (_realtimeListener != null) {
      ChatRealtimeService.instance.removeListener(_realtimeListener!);
    }

    _realtimeListener = () {
      if (mounted) loadMessages(silent: true);
    };
    ChatRealtimeService.instance.addListener(_realtimeListener!);
    _realtimeAcquired = true;
    await ChatRealtimeService.instance.acquire(conversationId: conversationId);
    // Screen may have been closed (stopRealtime) while connecting.
    if (!mounted || !_realtimeAcquired) return;

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
          error: ApiService.extractError(e),
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
      state = state.copyWith(isSending: false, error: ApiService.extractError(e));
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
    stopRealtime();
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
