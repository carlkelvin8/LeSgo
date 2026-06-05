import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/polling_intervals.dart';
import '../../../core/utils/order_service_labels.dart';
import '../../../data/data_source/chat_remote_datasource.dart';
import '../../../data/data_source/order_remote_datasource.dart';
import '../../../data/data_source/dto/chat/message_dto.dart';
import '../../../core/services/chat_realtime_service.dart';
import '../../../core/di/injection.dart';

// Chat state
class ChatState {
  final List<ConversationDto> conversations;
  final ConversationDto? currentConversation;
  final List<MessageDto> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final int unreadCount;

  const ChatState({
    this.conversations = const [],
    this.currentConversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.unreadCount = 0,
  });

  ChatState copyWith({
    List<ConversationDto>? conversations,
    ConversationDto? currentConversation,
    List<MessageDto>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    int? unreadCount,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Chat provider
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRemoteDataSource _chatDataSource;
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();
  final ChatRealtimeService _chatRealtime = getIt<ChatRealtimeService>();
  Timer? _pollTimer;
  late final ChatRefreshCallback _realtimeRefresh;

  ChatNotifier(this._chatDataSource) : super(const ChatState()) {
    _realtimeRefresh = () {
      if (state.currentConversation != null) {
        loadMessages(state.currentConversation!.id, silent: true);
      }
      loadUnreadCount();
      loadConversations();
    };
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatRealtime.removeListener(_realtimeRefresh);
    _chatRealtime.release();
    super.dispose();
  }

  // Load conversations
  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final conversations = await _chatDataSource.getConversations();
      final enriched = await _enrichConversations(conversations);
      final unreadCount = await _chatDataSource.getUnreadCount();
      
      state = state.copyWith(
        conversations: enriched,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<List<ConversationDto>> _enrichConversations(
    List<ConversationDto> conversations,
  ) async {
    final enriched = <ConversationDto>[];

    for (final conversation in conversations) {
      if (_hasServiceLabel(conversation)) {
        enriched.add(conversation);
        continue;
      }

      try {
        final orderResponse =
            await _orderDataSource.getOrder(conversation.orderId);
        if (orderResponse.success) {
          final order = orderResponse.data;
          enriched.add(
            conversation.copyWith(
              serviceId: order.serviceId,
              serviceType: order.serviceType ?? order.effectiveServiceType,
              serviceName: OrderServiceLabels.labelForOrder(order),
            ),
          );
          continue;
        }
      } catch (_) {}

      enriched.add(conversation);
    }

    return enriched;
  }

  bool _hasServiceLabel(ConversationDto conversation) {
    return (conversation.serviceName != null &&
            conversation.serviceName!.trim().isNotEmpty) ||
        conversation.serviceId != null ||
        (conversation.serviceType != null &&
            conversation.serviceType!.trim().isNotEmpty);
  }

  // Get or create conversation for order
  Future<ConversationDto?> getOrCreateConversation(int orderId) async {
    try {
      final conversation = await _chatDataSource.getOrCreateConversation(orderId);
      state = state.copyWith(currentConversation: conversation);
      await loadMessages(conversation.id);
      _startPolling();
      return conversation;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Load messages for conversation
  Future<void> loadMessages(int conversationId, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _chatDataSource.getMessages(conversationId);
      if (!mounted) return;
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
      
      // Mark as read
      await _chatDataSource.markAsRead(conversationId);
      await loadUnreadCount();
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        state = state.copyWith(
          error: e.toString(),
          isLoading: false,
        );
      }
    }
  }

  // Send message
  Future<bool> sendMessage(String message, {String messageType = 'text', Map<String, dynamic>? metadata}) async {
    if (state.currentConversation == null) return false;
    
    state = state.copyWith(isSending: true, error: null);
    
    try {
      final request = SendMessageRequestDto(
        message: message,
        messageType: messageType,
        metadata: metadata,
      );
      
      final newMessage = await _chatDataSource.sendMessage(
        state.currentConversation!.id,
        request,
      );
      if (!mounted) return false;
      
      // Reload messages to get server-side data (id, timestamps, etc.)
      await loadMessages(state.currentConversation!.id, silent: true);
      if (!mounted) return false;

      // If reload failed, at least add the returned message
      if (!state.messages.any((m) => m.id == newMessage.id)) {
        final updatedMessages = [newMessage, ...state.messages];
        state = state.copyWith(messages: updatedMessages);
      }

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: e.toString(),
        isSending: false,
      );
      return false;
    }
  }

  // Send location message
  Future<bool> sendLocation(double latitude, double longitude) async {
    final metadata = {"latitude": latitude, "longitude": longitude};
    return await sendMessage(
      'Shared location',
      messageType: 'location',
      metadata: metadata,
    );
  }

  // Add new message (for real-time updates)
  void addMessage(MessageDto message) {
    final updatedMessages = [...state.messages, message];
    state = state.copyWith(messages: updatedMessages);
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final unreadCount = await _chatDataSource.getUnreadCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      // Ignore error for unread count
    }
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _pollTimer?.cancel();
    _chatRealtime.removeListener(_realtimeRefresh);
    _chatRealtime.release();
    state = state.copyWith(
      currentConversation: null,
      messages: [],
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Realtime session + slower fallback poll for open chat.
  void _startPolling() {
    _pollTimer?.cancel();
    _chatRealtime.addListener(_realtimeRefresh);
    _chatRealtime.acquire(conversationId: state.currentConversation?.id);
    _pollTimer = Timer.periodic(PollingIntervals.chatMessages, (_) {
      if (mounted && state.currentConversation != null) {
        loadMessages(state.currentConversation!.id, silent: true);
      }
    });
  }
}

// Data source provider
final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return getIt<ChatRemoteDataSource>();
});

// Provider - per-order family so each order has its own chat state
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, orderId) {
  return ChatNotifier(ref.watch(chatDataSourceProvider));
});

// Keep a simple global provider for backward compat (uses orderId 0)
final chatProviderGlobal = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatDataSourceProvider));
});

// Unread count provider (for badge)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(chatProviderGlobal).unreadCount;
});