import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/chat_agent.dart';
import '../../../../core/services/gemini_customer_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../domain/entities/support/ibow_expression.dart';

class CustomerServiceMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// How IBOW feels about this reply (null on user messages).
  final IbowExpression? mood;

  /// Buttons for things IBOW can do after the customer confirms.
  final List<AgentAction> actions;

  /// Buttons that open screens in the app.
  final List<AgentLink> links;

  const CustomerServiceMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.mood,
    this.actions = const [],
    this.links = const [],
  });
}

/// Where an action button is in its life.
enum AgentActionStatus { ready, running, done, dismissed }

class CustomerServiceChatState {
  final List<CustomerServiceMessage> messages;
  final bool isSending;
  final String? error;
  final bool isConfigured;

  /// Status of each action button, keyed "<messageId>:<actionId>".
  final Map<String, AgentActionStatus> actionStatus;

  const CustomerServiceChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.isConfigured = false,
    this.actionStatus = const {},
  });

  AgentActionStatus statusOf(String messageId, String actionId) =>
      actionStatus['$messageId:$actionId'] ?? AgentActionStatus.ready;

  CustomerServiceChatState copyWith({
    List<CustomerServiceMessage>? messages,
    bool? isSending,
    String? error,
    bool? isConfigured,
    Map<String, AgentActionStatus>? actionStatus,
    bool clearError = false,
  }) {
    return CustomerServiceChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      isConfigured: isConfigured ?? this.isConfigured,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }
}

const _welcomeMessage =
    'Hi! I’m IBOW, your LeSgo AI assistant. I can help with orders, deliveries, LesPay, vouchers, missions, and account questions. What can I help you with?';

class CustomerServiceChatNotifier
    extends StateNotifier<CustomerServiceChatState> {
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
          mood: IbowExpression.happy,
        ),
      ],
      actionStatus: const {},
      clearError: true,
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    if (!state.isConfigured) {
      state = state.copyWith(
        error: 'Support chat is currently unavailable. Please try again later.',
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
      final reply = await _service.respond(trimmed);
      final botMessage = CustomerServiceMessage(
        id: _uuid.v4(),
        text: reply.text,
        isUser: false,
        timestamp: DateTime.now(),
        mood: reply.mood,
        actions: reply.actions,
        links: reply.links,
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
      state = state.copyWith(isSending: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Sorry, I had trouble responding. Please try again.',
      );
    }
  }

  void clearChat() {
    _service.resetAgent();
    _bootstrap();
  }

  void _setStatus(String messageId, String actionId, AgentActionStatus status) {
    state = state.copyWith(
      actionStatus: {...state.actionStatus, '$messageId:$actionId': status},
    );
  }

  void _say(String text, IbowExpression mood, {List<AgentLink> links = const []}) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        CustomerServiceMessage(
          id: _uuid.v4(),
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          mood: mood,
          links: links,
        ),
      ],
    );
  }

  /// Runs an action the customer confirmed by tapping its button.
  Future<void> runAction(String messageId, AgentAction action) async {
    if (state.statusOf(messageId, action.id) != AgentActionStatus.ready) return;
    _setStatus(messageId, action.id, AgentActionStatus.running);
    try {
      final done = await action.execute();
      _setStatus(messageId, action.id, AgentActionStatus.done);
      _say(done, IbowExpression.love);
    } catch (e) {
      _setStatus(messageId, action.id, AgentActionStatus.ready);
      _say(
        'Sorry, that did not work: ${ApiErrorMapper.message(e, fallbackEn: 'please try again in a moment.')}',
        IbowExpression.sad,
      );
    }
  }

  /// The customer chose not to go ahead.
  void dismissActions(String messageId) {
    final msg = state.messages.where((m) => m.id == messageId);
    if (msg.isEmpty) return;
    final updated = {...state.actionStatus};
    for (final a in msg.first.actions) {
      if ((updated['$messageId:${a.id}'] ?? AgentActionStatus.ready) ==
          AgentActionStatus.ready) {
        updated['$messageId:${a.id}'] = AgentActionStatus.dismissed;
      }
    }
    state = state.copyWith(actionStatus: updated);
    _say('No problem, I left everything as it is.', IbowExpression.happy);
  }
}

final customerServiceChatProvider =
    StateNotifierProvider.autoDispose<
      CustomerServiceChatNotifier,
      CustomerServiceChatState
    >((ref) {
      ref.watch(userSessionEpochProvider);
      return CustomerServiceChatNotifier(getIt<GeminiCustomerService>());
    });
