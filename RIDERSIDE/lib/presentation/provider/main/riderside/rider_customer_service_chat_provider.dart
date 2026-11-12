import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/gemini_customer_service.dart';
import '../../../../core/services/support_api.dart';
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

/// Files [text] as a support ticket for the admin team; returns a reference
/// the rider can quote (ticket number, else `#id`, else empty).
typedef SupportTicketSender = Future<String> Function(String text);

Future<String> _defaultTicketSender(String text) async {
  final ticket = await SupportApi.createTicket(
    subject: 'Rider support chat',
    description: text.length > 5000 ? text.substring(0, 5000) : text,
  );
  final number = ticket.ticketNumber;
  if (number != null && number.isNotEmpty) return number;
  return ticket.id > 0 ? '#${ticket.id}' : '';
}

const _welcomeMessage =
    'Hi! This is LeSgo Support. Message our admin team here for help with safety, orders, earnings, LesPay, and account issues.';

class RiderCustomerServiceChatNotifier
    extends StateNotifier<RiderCustomerServiceChatState> {
  RiderCustomerServiceChatNotifier(
    this._service, {
    SupportTicketSender? ticketSender,
  })  : _ticketSender = ticketSender ?? _defaultTicketSender,
        super(const RiderCustomerServiceChatState()) {
    _bootstrap();
  }

  final GeminiCustomerService _service;
  final SupportTicketSender _ticketSender;
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
              : 'Tell us what you need help with. Your message is sent to LeSgo admin support as a support ticket and our team will follow up.',
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
      await _escalateToAdmin(userMessage);
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

  /// Really files the message as a support ticket (no AI involved) and only
  /// confirms once the server accepted it.
  Future<void> _escalateToAdmin(CustomerServiceMessage userMessage) async {
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );
    try {
      final ticketRef = await _ticketSender(userMessage.text);
      state = state.copyWith(
        isSending: false,
        messages: [
          ...state.messages,
          CustomerServiceMessage(
            id: _uuid.v4(),
            text: ticketRef.isNotEmpty
                ? 'Your message was sent to LeSgo admin support (ticket $ticketRef). Our team will follow up.'
                : 'Your message was sent to LeSgo admin support. Our team will follow up.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: "Couldn't send your message to support. ${ApiService.extractError(e)}",
      );
    }
  }

  Future<void> requestAdminCallback() async {
    if (state.isSending) return;
    await _escalateToAdmin(
      CustomerServiceMessage(
        id: _uuid.v4(),
        text: 'I need an admin to call me back regarding a safety or support issue.',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
  }

  void clearChat() {
    _bootstrap();
  }
}

final riderCustomerServiceChatProvider = StateNotifierProvider.autoDispose<
    RiderCustomerServiceChatNotifier, RiderCustomerServiceChatState>((ref) {
  final notifier =
      RiderCustomerServiceChatNotifier(getIt<GeminiCustomerService>());
  final keepAliveLink = ref.keepAlive();
  final removeListener = notifier.addListener(
    (state) {
      if (state.messages.length <= 1) {
        keepAliveLink.close();
      }
    },
    fireImmediately: false,
  );
  ref.onDispose(removeListener);
  return notifier;
});
