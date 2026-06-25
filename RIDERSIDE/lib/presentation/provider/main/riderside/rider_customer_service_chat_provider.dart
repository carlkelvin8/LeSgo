import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/gemini_customer_service.dart';
import 'package:uuid/uuid.dart';

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

class RiderCustomerServiceChatState {
  final List<CustomerServiceMessage> messages;
  final bool isSending;
  final String? error;
  final bool isConfigured;

  const RiderCustomerServiceChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.isConfigured = false,
  });

  RiderCustomerServiceChatState copyWith({
    List<CustomerServiceMessage>? messages,
    bool? isSending,
    String? error,
    bool? isConfigured,
    bool clearError = false,
  }) {
    return RiderCustomerServiceChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

const _welcomeMessage =
    'Hi! This is LeSgo Rider Support. Message our admin team here for help with safety, orders, earnings, LesPay, and account issues.';

class RiderCustomerServiceChatNotifier
    extends StateNotifier<RiderCustomerServiceChatState> {
  RiderCustomerServiceChatNotifier(this._service)
      : super(const RiderCustomerServiceChatState()) {
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
              : 'Message LeSgo admin support here. Our team will respond in this chat.',
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

    final userMessage = CustomerServiceMessage(
      id: _uuid.v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    if (!state.isConfigured) {
      final adminAck = CustomerServiceMessage(
        id: _uuid.v4(),
        text:
            'Your message was sent to LeSgo admin support. Our team will respond in this chat.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, userMessage, adminAck],
        clearError: true,
      );
      return;
    }

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
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'Sorry, I had trouble responding. Please try again.',
      );
    }
  }

  Future<void> requestAdminCallback() {
    return sendMessage(
      'I need an admin to call me back regarding a safety or support issue.',
    );
  }

  void clearChat() {
    _bootstrap();
  }
}

final riderCustomerServiceChatProvider = StateNotifierProvider.autoDispose<
    RiderCustomerServiceChatNotifier, RiderCustomerServiceChatState>((ref) {
  return RiderCustomerServiceChatNotifier(getIt<GeminiCustomerService>());
});
