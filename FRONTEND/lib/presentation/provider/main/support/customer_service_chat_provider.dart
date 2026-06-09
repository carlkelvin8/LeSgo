import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/gemini_customer_service.dart';

class CustomerServiceMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const CustomerServiceMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class CustomerServiceChatState {
  final List<CustomerServiceMessage> messages;
  final bool isSending;
  final String? error;
  final bool isConfigured;

  const CustomerServiceChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.isConfigured = false,
  });

  CustomerServiceChatState copyWith({
    List<CustomerServiceMessage>? messages,
    bool? isSending,
    String? error,
    bool? isConfigured,
    bool clearError = false,
  }) {
    return CustomerServiceChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

const _welcomeMessage =
    'Hi! I\'m LeSGo Assistant. I only handle LeSGo app customer service — orders, deliveries, LesPay, vouchers, missions, and account help. What can I help you with?';

class CustomerServiceChatNotifier extends StateNotifier<CustomerServiceChatState> {
  CustomerServiceChatNotifier(this._service)
      : super(const CustomerServiceChatState()) {
    _bootstrap();
  }

  final GeminiCustomerService _service;
  final _uuid = const Uuid();

  void _bootstrap() {
    final configured = _service.isConfigured;
    if (configured) {
      _service.startConversation();
    }

    state = state.copyWith(
      isConfigured: configured,
      messages: [
        CustomerServiceMessage(
          id: _uuid.v4(),
          text: configured
              ? _welcomeMessage
              : 'AI assistant is not configured yet. You can still contact our team through Support Tickets in Settings.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      clearError: true,
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    if (!state.isConfigured) {
      state = state.copyWith(
        error: 'Add GEMINI_API_KEY to secrets.json to enable the AI assistant.',
      );
      return;
    }

    final userMessage = CustomerServiceMessage(
      id: _uuid.v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    try {
      final reply = await _service.sendMessage(trimmed);
      final botMessage = CustomerServiceMessage(
        id: _uuid.v4(),
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isSending: false,
      );
    } on GeminiNotConfiguredException catch (e) {
      state = state.copyWith(
        isSending: false,
        isConfigured: false,
        error: e.toString(),
      );
    } on GeminiServiceException catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Sorry, I had trouble responding. Please try again.',
      );
    }
  }

  void clearChat() {
    _bootstrap();
  }
}

final customerServiceChatProvider = StateNotifierProvider.autoDispose<
    CustomerServiceChatNotifier, CustomerServiceChatState>((ref) {
  return CustomerServiceChatNotifier(getIt<GeminiCustomerService>());
});
