import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/inbox/message.dart';

class InboxState {
  final List<Message> messages;
  final bool isLoading;
  final String searchQuery;

  InboxState({
    required this.messages,
    this.isLoading = false,
    this.searchQuery = '',
  });

  InboxState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? searchQuery,
  }) {
    return InboxState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Message> get filteredMessages {
    if (searchQuery.isEmpty) {
      return messages;
    }
    return messages
        .where((message) =>
            message.senderName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            message.messagePreview.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  InboxNotifier()
      : super(InboxState(
          messages: _getDummyMessages(),
        ));

  static List<Message> _getDummyMessages() {
    return [
      Message(
        id: '1',
        senderName: 'Maria Santos',
        avatarUrl: '',
        messagePreview: 'Thank you for the delivery! Everything was perfect.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
      ),
      Message(
        id: '2',
        senderName: 'Juan Dela Cruz',
        avatarUrl: '',
        messagePreview: 'Where are you now? I\'ve been waiting for 10 minutes.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 1,
      ),
      Message(
        id: '3',
        senderName: 'LezGo Support',
        avatarUrl: '',
        messagePreview: 'Your account has been verified successfully!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 0,
      ),
      Message(
        id: '4',
        senderName: 'Anna Reyes',
        avatarUrl: '',
        messagePreview: 'Can you pick up the package at the lobby?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
      Message(
        id: '5',
        senderName: 'Mark Johnson',
        avatarUrl: '',
        messagePreview: 'Great service! Will use again.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
      ),
    ];
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshMessages() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      messages: _getDummyMessages(),
      isLoading: false,
    );
  }

  void markAsRead(String messageId) {
    final updatedMessages = state.messages.map((message) {
      if (message.id == messageId) {
        return Message(
          id: message.id,
          senderName: message.senderName,
          avatarUrl: message.avatarUrl,
          messagePreview: message.messagePreview,
          timestamp: message.timestamp,
          unreadCount: 0,
        );
      }
      return message;
    }).toList();
    
    state = state.copyWith(messages: updatedMessages);
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier();
});
