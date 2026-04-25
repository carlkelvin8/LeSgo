import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/data_source/chat_remote_datasource.dart';
import '../../../data/data_source/dto/chat/message_dto.dart';
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

  ChatNotifier(this._chatDataSource) : super(const ChatState());

  // Load conversations
  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final conversations = await _chatDataSource.getConversations();
      final unreadCount = await _chatDataSource.getUnreadCount();
      
      state = state.copyWith(
        conversations: conversations,
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

  // Get or create conversation for order
  Future<ConversationDto?> getOrCreateConversation(int orderId) async {
    try {
      final conversation = await _chatDataSource.getOrCreateConversation(orderId);
      state = state.copyWith(currentConversation: conversation);
      await loadMessages(conversation.id);
      return conversation;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Load messages for conversation
  Future<void> loadMessages(int conversationId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _chatDataSource.getMessages(conversationId);
      state = state.copyWith(
        messages: messages, // API sends descending (newest first), which matches reverse ListView
        isLoading: false,
      );
      
      // Mark as read
      await _chatDataSource.markAsRead(conversationId);
      await loadUnreadCount();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
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
      
      // Add message to current list
      final updatedMessages = [...state.messages, newMessage];
      state = state.copyWith(
        messages: updatedMessages,
        isSending: false,
      );
      
      return true;
    } catch (e) {
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
    state = state.copyWith(
      currentConversation: null,
      messages: [],
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider - per-order family so each order has its own chat state
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, orderId) {
  return ChatNotifier(getIt<ChatRemoteDataSource>());
});

// Keep a simple global provider for backward compat (uses orderId 0)
final chatProviderGlobal = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(getIt<ChatRemoteDataSource>());
});

// Unread count provider (for badge)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(chatProviderGlobal).unreadCount;
});