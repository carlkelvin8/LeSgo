import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/data_source/chat_remote_datasource.dart';
import '../../../data/data_source/dto/chat/chat_dto.dart';

// Chat data source provider (singleton)
final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(DioClient());
});

// Chat state
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

// Chat notifier - per order instance
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRemoteDataSource _chatDataSource;
  Timer? _pollTimer;

  ChatNotifier(this._chatDataSource) : super(ChatState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Get or create conversation for order
  Future<void> getOrCreateConversation(int orderId) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversation = await _chatDataSource.getOrCreateConversation(orderId);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        currentConversation: conversation,
      );

      // Load messages for this conversation
      await loadMessages();

      // Start polling for new messages
      if (mounted) _startPolling();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load chat: ${e.toString()}',
      );
    }
  }

  // Load messages for current conversation
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

      // Show newest first (descending) for reverse ListView
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

  // Send message
  Future<bool> sendMessage(String message) async {
    if (!mounted || state.currentConversation == null || message.trim().isEmpty) {
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

      // Reload messages to get the new message
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

  // Load unread count
  Future<void> loadUnreadCount() async {
    if (!mounted) return;
    try {
      final count = await _chatDataSource.getUnreadCount();
      if (!mounted) return;
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Silently fail
    }
  }

  // Mark messages as read
  Future<void> markAsRead() async {
    if (!mounted || state.currentConversation == null) return;
    try {
      await _chatDataSource.markAsRead(state.currentConversation!.id);
      await loadUnreadCount();
    } catch (_) {}
  }

  // Start polling for new messages every 5 seconds
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) loadMessages(silent: true);
    });
  }

  // Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
  }

  // Clear current conversation
  void clearConversation() {
    _pollTimer?.cancel();
    state = ChatState();
  }
}

// Per-order chat provider family - each order gets its own chat state
final chatProviderFamily =
    StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, orderId) {
  final dataSource = ref.watch(chatDataSourceProvider);
  return ChatNotifier(dataSource);
});

// Global unread count provider
final unreadCountProvider = Provider<int>((ref) => 0);
