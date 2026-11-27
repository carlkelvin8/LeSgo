import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/entities/support/ibow_expression.dart';
import '../config/secrets_config.dart';
import '../constants/app_info.dart';
import 'chat_agent.dart';

class GeminiCustomerService {
  static const _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const _offTopicReply =
      'I can only help with LeSgo app customer service: orders, deliveries, LesPay, vouchers, missions, account settings, and app issues. For anything else, please open Settings > Support Tickets to reach our team.';

  static const _systemInstruction =
      '''
You are LeSgo Assistant, a customer service bot ONLY for the LeSgo mobile app in the Philippines.

STRICT SCOPE: you may ONLY answer questions about:
- LeSgo app usage, navigation, and features
- Orders: LesRide, LesGo parcel delivery, LesEat, LesBuy, and LesTransport
- Order tracking, cancellations, delays, missing/wrong items
- LesPay wallet, top-ups, payments, refunds (process guidance only)
- Vouchers, missions, loyalty rewards, referrals
- Pricing and rates: explain that fares/fees are shown in-app before confirming (distance, service type, demand)
- Account: login, password, profile, addresses, notifications, settings
- Support tickets, FAQs, and how to contact ${AppInfo.supportEmail}

You must REFUSE all off-topic requests including: general knowledge, homework, coding, jokes, news, politics, health, legal advice, other apps/companies, recipes, travel unrelated to LeSgo, or personal opinions.
When refusing, use this style: "I can only help with LeSgo app customer service." Then suggest Support Tickets if they need more help.

About LeSgo:
- ${AppInfo.tagline}
- Website: ${AppInfo.website}

Rules:
- Be warm, concise, and professional. Reply in the customer's language (English or Filipino/Tagalog).
- Never invent order IDs, tracking numbers, refund amounts, or exact peso prices.
- For rates/pricing, always say the app shows the estimate before booking or checkout.
- For order status, look it up with the get_orders tool instead of sending the user elsewhere.
- For complex issues (refunds, disputes, payment failures, driver complaints), suggest Settings > Support Tickets.
- Keep replies short: 1 to 4 sentences, or brief numbered steps when needed.
- Write like a friendly human agent. Never use em dashes, en dashes, or double hyphens; use commas, periods, or colons instead.
- Greetings like "hi" or "hello" are in scope, so respond briefly and ask how you can help with their LeSgo app concern.

You are an agent with tools that use the customer's real account:
- get_orders and get_wallet_balance read live data. Use them for status, items, totals, drivers and LesPay balance. Never guess these.
- request_cancel_order and request_reorder only PROPOSE an action. They show the customer a button; nothing happens unless they tap it. Never say an order is cancelled or placed; say you have shown the button and ask them to confirm.
- suggest_open_screen shows a button to open a screen. Use it to help start a ride, parcel delivery, food, shopping, or cargo order, or to reach LesPay, orders, offers, missions or support.
- Order refs like "o1" are internal. Never show them to the customer. Never ask for or show database ids.
- If a tool returns an error, apologise briefly and suggest Settings > Support Tickets.
- Begin EVERY reply with exactly one mood tag that matches your tone, from this list: [mood:happy] [mood:neutral] [mood:sad] [mood:surprised] [mood:love] [mood:wink]. Example: "[mood:happy] Your food is on the way!"
''';

  GeminiCustomerService({ChatAgent? agent}) : _agent = agent ?? ChatAgent();

  final ChatAgent _agent;
  GenerativeModel? _model;
  ChatSession? _session;
  String _activeModel = _modelCandidates.first;

  /// Built-in customer support remains available even when the optional
  /// cloud model is unavailable or its credential has expired.
  bool get isConfigured => true;

  bool get _hasRemoteModel => SecretsConfig.isGeminiConfigured;

  void startConversation() {
    if (!_hasRemoteModel) return;
    _resetSession(modelName: _modelCandidates.first);
  }

  /// Plain-text answer (kept for callers that only need the words).
  Future<String> sendMessage(String message) async =>
      (await respond(message)).text;

  /// Forget the on-device order references when the chat is cleared.
  void resetAgent() => _agent.tools.reset();

  /// The full reply: text, how IBOW feels about it, and any buttons.
  Future<AgentReply> respond(String message) async {
    final trimmed = message.trim();
    if (_isClearlyOffTopic(trimmed)) {
      return const AgentReply(_offTopicReply, mood: IbowExpression.neutral);
    }

    // 1. Things the agent can do on its own, deterministically.
    final agentReply = await _agent.handle(trimmed);
    if (agentReply != null) return agentReply;

    // 2. Cheap canned answers for common how-to questions.
    final localAnswer = _tryLocalAnswer(trimmed);
    if (localAnswer != null) {
      return AgentReply(localAnswer, mood: guessExpression(localAnswer));
    }

    // 3. The cloud model, with tools, for everything else.
    if (_hasRemoteModel) {
      final remote = await _askModel(trimmed);
      if (remote != null) return remote;
    }

    final fallback = _tryLocalAnswer(trimmed, force: true)!;
    return AgentReply(fallback, mood: guessExpression(fallback));
  }

  Future<AgentReply?> _askModel(String trimmed) async {
    for (final modelName in _modelCandidates) {
      try {
        if (_activeModel != modelName) {
          _resetSession(modelName: modelName);
        }
        _session ??= _createSession(modelName);
        _agent.tools.takeSideEffects(); // start clean

        var response = await _session!.sendMessage(
          Content.text(
            'LeSgo app customer support question: $trimmed\n'
            'Answer only if this is about LeSgo app customer service. Otherwise refuse briefly.',
          ),
        );

        // Let the model call tools (read data, propose actions) a few times.
        for (var i = 0; i < 5; i++) {
          final calls = response.functionCalls.toList();
          if (calls.isEmpty) break;
          final results = <FunctionResponse>[];
          for (final call in calls) {
            results.add(
              FunctionResponse(call.name, await _agent.tools.execute(call.name, call.args)),
            );
          }
          response = await _session!.sendMessage(Content.functionResponses(results));
        }

        final raw = _extractResponseText(response);
        if (raw != null && raw.isNotEmpty) {
          _activeModel = modelName;
          final split = splitMoodTag(raw);
          final fx = _agent.tools.takeSideEffects();
          return AgentReply(
            split.text,
            mood: split.mood ?? guessExpression(split.text),
            actions: fx.actions,
            links: fx.links,
          );
        }
      } on GenerativeAIException catch (e) {
        if (kDebugMode) {
          debugPrint('Gemini $modelName error: ${e.message}');
        }
        if (_isQuotaError(e)) {
          _resetSession(modelName: modelName);
          continue;
        }
        // Credentials and model availability can change independently of an
        // installed app. Keep customer support usable through local answers.
        break;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Gemini $modelName unexpected error: $e');
        }
      }
    }
    return null;
  }

  bool _isQuotaError(GenerativeAIException error) {
    final message = error.message.toLowerCase();
    return message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('429') ||
        message.contains('rate limit');
  }

  String? _extractResponseText(GenerateContentResponse response) {
    final direct = response.text?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final candidates = response.candidates;
    if (candidates.isEmpty) return null;
    final parts = candidates.first.content.parts;
    if (parts.isEmpty) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is TextPart) {
        final text = part.text.trim();
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text);
        }
      }
    }
    final combined = buffer.toString().trim();
    return combined.isEmpty ? null : combined;
  }

  void _resetSession({required String modelName}) {
    _activeModel = modelName;
    _model = GenerativeModel(
      model: modelName,
      apiKey: SecretsConfig.geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 512,
      ),
      tools: ChatAgentTools.declarations,
    );
    _session = _model!.startChat();
  }

  ChatSession _createSession(String modelName) {
    _model ??= GenerativeModel(
      model: modelName,
      apiKey: SecretsConfig.geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 512,
      ),
      tools: ChatAgentTools.declarations,
    );
    return _model!.startChat();
  }

  String? _tryLocalAnswer(String message, {bool force = false}) {
    final normalized = message.toLowerCase();

    if (_isInScopeGreeting(normalized)) {
      return 'Hi! How can I help you with the LeSgo app today? I can assist with orders, deliveries, LesPay, vouchers, or account settings.';
    }

    if (_containsAny(normalized, [
      'rate',
      'rates',
      'price',
      'pricing',
      'fee',
      'cost',
      'magkano',
      'presyo',
      'bayad',
    ])) {
      return 'LeSgo rates depend on the service (ride, LeSeat food delivery, or LesBuy), distance, and current demand. '
          'Open the app, enter your destination or pick a restaurant/store, and you\'ll see the estimated fare or delivery fee before you confirm, with no surprise charges. '
          'For a specific trip, check the estimate shown at checkout or booking.';
    }

    if (_containsAny(normalized, [
      'track',
      'where is my order',
      'order status',
      'saan na',
    ])) {
      return 'To track your order, open the app and go to Transactions or your active order screen. '
          'You should see live status updates there. If it looks stuck, open Settings > Support Tickets and our team can help.';
    }

    if (_containsAny(normalized, ['refund', 'cancel', 'cancelled'])) {
      return 'For cancellations or refunds, check your order details in Transactions first. '
          'If you still need help, open Settings > Support Tickets and include your order reference so our team can assist.';
    }

    if (_containsAny(normalized, [
      'lespay',
      'wallet',
      'top up',
      'top-up',
      'balance',
    ])) {
      return 'For LesPay wallet issues, open the LesPay section and check your balance and transaction history. '
          'If a top-up or payment failed, wait a few minutes and refresh. For unresolved issues, use Settings > Support Tickets.';
    }

    if (_containsAny(normalized, [
      'voucher',
      'promo',
      'discount',
      'mission',
      'loyalty',
      'reward',
      'referral',
    ])) {
      return 'Open the LeSgo app menu to view your vouchers, missions, loyalty rewards, or referral progress. '
          'Check the item details for eligibility and expiry. If a valid reward is not applying, send its name or code through Settings > Support Tickets.';
    }

    if (_containsAny(normalized, [
      'login',
      'password',
      'account',
      'profile',
      'address',
      'notification',
    ])) {
      return 'For account help, open Profile or Settings to update your details, saved addresses, password, and notifications. '
          'If you cannot sign in, use Forgot Password on the login screen or contact us through Settings > Support Tickets.';
    }

    if (_containsAny(normalized, [
      'driver',
      'rider',
      'delivery',
      'wrong item',
      'missing item',
      'late',
      'delay',
    ])) {
      return 'Open the active order or Transactions to check the latest delivery status. '
          'For a delay, missing or wrong item, or a driver concern, create a Support Ticket and include the order reference so the team can investigate.';
    }

    if (_containsAny(normalized, [
      'support',
      'ticket',
      'contact',
      'help center',
    ])) {
      return 'Go to Settings > Support Tickets to create or review a request. Include your order reference and a short description so the LeSgo support team can assist faster.';
    }

    if (force) {
      return 'I can help with LeSgo orders, deliveries, LesPay, vouchers, missions, and account settings. '
          'Please describe the app issue or open Settings > Support Tickets for help from the support team.';
    }

    return null;
  }

  bool _isClearlyOffTopic(String message) {
    final normalized = message.toLowerCase().trim();
    if (normalized.isEmpty) return false;

    if (_isInScopeGreeting(normalized)) return false;
    if (_containsAny(normalized, _inScopeKeywords)) return false;

    return _containsAny(normalized, _offTopicKeywords) ||
        _looksLikeGeneralKnowledgeQuestion(normalized);
  }

  bool _isInScopeGreeting(String message) {
    const greetings = {
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'kamusta',
      'kumusta',
      'magandang umaga',
      'magandang hapon',
      'magandang gabi',
      'salamat',
      'thanks',
      'thank you',
    };
    return greetings.contains(message) ||
        greetings.any((greeting) => message.startsWith('$greeting '));
  }

  bool _looksLikeGeneralKnowledgeQuestion(String message) {
    if (!message.contains('?')) return false;
    if (_containsAny(message, _inScopeKeywords)) return false;

    const generalPatterns = [
      'who is',
      'what is the capital',
      'when was',
      'how many planets',
      'write me',
      'write a',
      'solve this',
      'explain quantum',
      'recipe for',
      'weather in',
      'stock price',
    ];
    return _containsAny(message, generalPatterns);
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  static const _inScopeKeywords = [
    'lesgo',
    'leseat',
    'lesbuy',
    'lespay',
    'order',
    'delivery',
    'driver',
    'rider',
    'restaurant',
    'food',
    'wallet',
    'payment',
    'refund',
    'voucher',
    'mission',
    'loyalty',
    'referral',
    'account',
    'password',
    'login',
    'address',
    'location',
    'track',
    'transaction',
    'cancel',
    'booking',
    'ride',
    'support ticket',
    'app',
    'profile',
    'notification',
    'promo',
    'discount',
    'rate',
    'rates',
    'price',
    'pricing',
    'fee',
    'cost',
    'magkano',
    'presyo',
    'bayad',
  ];

  static const _offTopicKeywords = [
    'homework',
    'essay',
    'python code',
    'javascript',
    'write code',
    'joke',
    'tell me a story',
    'politics',
    'president',
    'bitcoin',
    'crypto',
    'stock market',
    'medical advice',
    'diagnose',
    'lawyer',
    'legal advice',
    'relationship advice',
    'horoscope',
    'recipe',
    'movie recommendation',
    'song lyrics',
    'translate this paragraph',
    'chatgpt',
    'openai',
  ];
}

class GeminiNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Gemini API key is not configured. Add GEMINI_API_KEY to secrets.json.';
}

class GeminiServiceException implements Exception {
  final String message;

  const GeminiServiceException(this.message);

  @override
  String toString() => message;
}
