import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/gemini_customer_service.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/rider_live_support_service.dart';
import '../../../../core/services/support_api.dart';

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
  final bool isLiveAgent;

  const RiderCustomerServiceChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.isConfigured = false,
    this.isLiveAgent = false,
  });

  RiderCustomerServiceChatState copyWith({
    List<CustomerServiceMessage>? messages,
    bool? isSending,
    String? error,
    bool? isConfigured,
    bool? isLiveAgent,
    bool clearError = false,
  }) {
    return RiderCustomerServiceChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      isConfigured: isConfigured ?? this.isConfigured,
      isLiveAgent: isLiveAgent ?? this.isLiveAgent,
    );
  }
}

const _welcomeMessage =
    'Hi! I am the LeSgo AI assistant. Use the menu to message our support team.';
const _liveWelcome =
    'Message our support team here. An agent will reply in this conversation when available.';

class RiderCustomerServiceChatNotifier
    extends StateNotifier<RiderCustomerServiceChatState> {
  RiderCustomerServiceChatNotifier(
    this._service, {
    RiderLiveSupportService? liveSupport,
  }) : _liveSupport = liveSupport ?? RiderLiveSupportService(),
       super(const RiderCustomerServiceChatState()) {
    _bootstrap();
  }

  final GeminiCustomerService _service;
  final RiderLiveSupportService _liveSupport;
  final _uuid = const Uuid();
  Timer? _poll;
  Future<void>? _connecting;
  bool _refreshing = false;
  int? _ticketId;
  int _revision = 0;

  void _bootstrap() {
    final configured = _service.isConfigured;
    if (configured) _service.startConversation();
    state = state.copyWith(
      isConfigured: configured,
      isLiveAgent: !configured,
      messages: [
        CustomerServiceMessage(
          id: 'welcome',
          text: configured ? _welcomeMessage : _liveWelcome,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      clearError: true,
    );
    if (!configured) unawaited(_connect().catchError((_) {}));
  }

  Future<void> _connect() {
    return _connecting ??= _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final detail = await _liveSupport.findConversation();
      if (!mounted) return;
      if (detail != null) {
        _ticketId = detail.ticket.id;
        _applyMessages(detail);
      }
      _poll ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => refreshMessages(),
      );
    } catch (_) {
      // A send retries discovery; never create a duplicate thread when discovery fails.
      _connecting = null;
      rethrow;
    }
  }

  void _applyMessages(RiderSupportTicketDetail detail) {
    if (!mounted) return;
    final messages = detail.messages
        .map(
          (message) => CustomerServiceMessage(
            id: 'support-${message.id}',
            text: message.message,
            isUser: !message.isStaff,
            timestamp: DateTime.tryParse(message.createdAt) ?? DateTime.now(),
          ),
        )
        .toList();
    final sameMessages =
        state.messages.length == messages.length + 1 &&
        state.messages
            .skip(1)
            .toList()
            .asMap()
            .entries
            .every(
              (entry) =>
                  entry.value.id == messages[entry.key].id &&
                  entry.value.text == messages[entry.key].text,
            );
    if (!sameMessages) {
      state = state.copyWith(
        messages: [
          CustomerServiceMessage(
            id: 'live-welcome',
            text: _liveWelcome,
            isUser: false,
            timestamp: DateTime.now(),
          ),
          ...messages,
        ],
      );
    }
    if (detail.ticket.status == 'closed' ||
        detail.ticket.status == 'cancelled') {
      _ticketId = null;
      _connecting = null;
    }
  }

  Future<void> refreshMessages() async {
    final ticketId = _ticketId;
    if (!mounted ||
        !state.isLiveAgent ||
        state.isSending ||
        _refreshing ||
        ticketId == null) {
      return;
    }
    _refreshing = true;
    final revision = _revision;
    try {
      final detail = await _liveSupport.load(ticketId);
      if (mounted && !state.isSending && revision == _revision) {
        _applyMessages(detail);
      }
    } catch (_) {
      // Keep the last confirmed history on temporary polling errors.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _sendToAgent(String text) async {
    await _connect();
    if (!mounted) return;
    final ticketId = _ticketId;
    CustomerServiceMessage sent;
    if (ticketId == null) {
      final ticket = await _liveSupport.create(text);
      if (!mounted) return;
      _ticketId = ticket.id;
      sent = CustomerServiceMessage(
        id: 'ticket-${ticket.id}',
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
    } else {
      final message = await _liveSupport.send(ticketId, text);
      if (!mounted) return;
      sent = CustomerServiceMessage(
        id: 'support-${message.id}',
        text: message.message,
        isUser: true,
        timestamp: DateTime.tryParse(message.createdAt) ?? DateTime.now(),
      );
    }
    if (mounted) {
      state = state.copyWith(
        messages: [...state.messages, sent],
        isSending: false,
        clearError: true,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;
    if (trimmed.length > 5000) {
      state = state.copyWith(
        error: 'Please keep your message within 5,000 characters.',
      );
      return;
    }
    _revision++;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      if (state.isLiveAgent || !state.isConfigured) {
        await _sendToAgent(trimmed);
        return;
      }
      try {
        final reply = await _service.sendMessage(trimmed);
        if (!mounted) return;
        state = state.copyWith(
          messages: [
            ...state.messages,
            CustomerServiceMessage(
              id: _uuid.v4(),
              text: trimmed,
              isUser: true,
              timestamp: DateTime.now(),
            ),
            CustomerServiceMessage(
              id: _uuid.v4(),
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
          isSending: false,
        );
      } catch (_) {
        if (!mounted) return;
        state = state.copyWith(isLiveAgent: true);
        await _sendToAgent(trimmed);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isSending: false,
          error:
              'Your message was not sent. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> requestAdminCallback() async {
    if (state.isSending) return;
    state = state.copyWith(isLiveAgent: true, clearError: true);
    await sendMessage(
      'I would like to speak with a support agent. Please contact me about my support issue.',
    );
  }

  void clearChat() {
    // Clear local AI history; confirmed live support history stays on the server.
    if (state.isSending) return;
    if (state.isLiveAgent) {
      refreshMessages();
    } else {
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}

final riderCustomerServiceChatProvider =
    StateNotifierProvider.autoDispose<
      RiderCustomerServiceChatNotifier,
      RiderCustomerServiceChatState
    >((ref) {
      final notifier = RiderCustomerServiceChatNotifier(
        getIt<GeminiCustomerService>(),
      );
      // Auto-dispose stops polling when this screen closes.
      return notifier;
    });
