import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/secrets_config.dart';
import '../constants/app_info.dart';

class GeminiCustomerService {
  static const _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const _offTopicReply =
      'I can only help with LeSGo Rider & Merchant app support — deliveries, earnings, LesPay wallet, missions, documents, account settings, and app issues. For anything else, open Support Tickets to reach our team.';

  static const _systemInstruction = '''
You are LeSGo Partner Assistant, a customer service bot ONLY for the LeSGo Rider & Merchant mobile apps in the Philippines (drivers/riders and restaurant merchants).

STRICT SCOPE — you may ONLY answer questions about:
- LeSGo Rider app: accepting orders, navigation, duty/on-duty status, proof of delivery, earnings, wallet balance, top-ups, withdrawals
- LeSGo Merchant app: menu management, incoming orders, order preparation, merchant earnings, LesPay e-wallet
- Order handling: pickup, drop-off, cancellations, COD confirmation, customer chat, delays
- LesPay wallet: top-ups, withdrawals, linked GCash/Maya accounts, transaction history
- Missions, vouchers, loyalty rewards, referrals for drivers and merchants
- Document verification: driver's license, vehicle docs, merchant business permits
- Account: login, password, profile, notifications, security (2FA, biometrics)
- Support tickets, FAQs, safety/SOS, and how to contact ${AppInfo.supportEmail}

You must REFUSE all off-topic requests including: general knowledge, homework, coding, jokes, news, politics, health, legal advice, other apps/companies, or personal opinions.
When refusing, use this style: "I can only help with LeSGo Rider & Merchant app support." Then suggest Support Tickets if they need more help.

About LeSGo:
- ${AppInfo.tagline}
- Website: ${AppInfo.website}

Rules:
- Be warm, concise, and professional. Reply in the user's language (English or Filipino/Tagalog).
- Never invent order IDs, earnings amounts, refund amounts, or exact peso prices.
- For earnings/rates, say amounts are shown in-app under Earnings or Wallet.
- For order issues (disputes, payment failures, unsafe customers), suggest Support Tickets or Safety & SOS.
- Keep replies short: 1–4 sentences, or brief numbered steps when needed.
- Greetings like "hi" or "hello" are in scope — respond briefly and ask how you can help with their LeSGo partner app concern.
''';

  GenerativeModel? _model;
  ChatSession? _session;
  String _activeModel = _modelCandidates.first;

  bool get isConfigured => SecretsConfig.isGeminiConfigured;

  void startConversation() {
    if (!isConfigured) return;
    _resetSession(modelName: _modelCandidates.first);
  }

  Future<String> sendMessage(String message) async {
    if (!isConfigured) {
      throw GeminiNotConfiguredException();
    }

    final trimmed = message.trim();
    if (_isClearlyOffTopic(trimmed)) {
      return _offTopicReply;
    }

    final localAnswer = _tryLocalAnswer(trimmed);
    if (localAnswer != null) {
      return localAnswer;
    }

    Object? lastError;
    for (final modelName in _modelCandidates) {
      try {
        if (_activeModel != modelName) {
          _resetSession(modelName: modelName);
        }
        _session ??= _createSession(modelName);

        final response = await _session!.sendMessage(
          Content.text(
            'LeSGo Rider/Merchant partner support question: $trimmed\n'
            'Answer only if this is about LeSGo partner app support. Otherwise refuse briefly.',
          ),
        );

        final text = _extractResponseText(response);
        if (text != null && text.isNotEmpty) {
          _activeModel = modelName;
          return text;
        }

        lastError = 'Empty response from $modelName';
      } on GenerativeAIException catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('Gemini $modelName error: ${e.message}');
        }
        if (_isQuotaError(e)) {
          _resetSession(modelName: modelName);
          continue;
        }
        throw GeminiServiceException(_mapGenerativeError(e));
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('Gemini $modelName unexpected error: $e');
        }
      }
    }

    final fallback = _tryLocalAnswer(trimmed, force: true);
    if (fallback != null) return fallback;

    if (lastError is GenerativeAIException) {
      throw GeminiServiceException(_mapGenerativeError(lastError));
    }
    throw const GeminiServiceException(
      'Sorry, I had trouble responding. Please try again in a moment.',
    );
  }

  String _mapGenerativeError(GenerativeAIException error) {
    final message = error.message.toLowerCase();
    if (_isQuotaError(error)) {
      return 'AI is temporarily busy. Please wait a minute and try again, or open Support Tickets.';
    }
    if (message.contains('api key') ||
        message.contains('permission') ||
        message.contains('401') ||
        message.contains('403')) {
      return 'AI assistant is misconfigured. Check GEMINI_API_KEY in secrets.json.';
    }
    if (message.contains('not found') || message.contains('404')) {
      return 'AI model unavailable. Please try again shortly.';
    }
    return 'Sorry, I had trouble responding. Please try again.';
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
    );
    return _model!.startChat();
  }

  String? _tryLocalAnswer(String message, {bool force = false}) {
    final normalized = message.toLowerCase();

    if (_containsAny(normalized, [
      'earning',
      'earnings',
      'kita',
      'sahod',
      'commission',
    ])) {
      return 'Open the Earnings section in the app to see today\'s trips, weekly totals, and payout breakdown. '
          'If an amount looks wrong, open Support Tickets with your order reference.';
    }

    if (_containsAny(normalized, [
      'wallet',
      'top up',
      'top-up',
      'withdraw',
      'gcash',
      'maya',
      'lespay',
    ])) {
      return 'For LesPay wallet, open Wallet in the app to check balance, top up via GCash/Maya/card, or withdraw to a linked account. '
          'If a transaction failed, wait a few minutes and refresh. For unresolved issues, use Support Tickets.';
    }

    if (_containsAny(normalized, [
      'document',
      'verification',
      'license',
      'permit',
    ])) {
      return 'Go to Profile > Document verification to upload or check status of your driver or merchant documents. '
          'Rejected documents can be resubmitted from the same screen.';
    }

    if (_containsAny(normalized, ['accept order', 'duty', 'online', 'offline'])) {
      return 'Toggle your duty status on the map/bookings screen to go online and receive orders. '
          'Make sure your LesPay balance meets the minimum required to accept bookings.';
    }

    if (force && _isInScopeGreeting(normalized)) {
      return 'Hi! How can I help with the LeSGo Rider or Merchant app — orders, earnings, LesPay, documents, or account settings?';
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
      'write me',
      'write a',
      'solve this',
      'recipe for',
      'weather in',
    ];
    return _containsAny(message, generalPatterns);
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  static const _inScopeKeywords = [
    'lesgo',
    'rider',
    'driver',
    'merchant',
    'order',
    'delivery',
    'pickup',
    'drop',
    'earning',
    'wallet',
    'lespay',
    'top up',
    'withdraw',
    'mission',
    'voucher',
    'document',
    'verification',
    'support ticket',
    'account',
    'password',
    'duty',
    'booking',
    'customer',
    'menu',
    'restaurant',
    'safety',
    'sos',
    'notification',
    '2fa',
    'security',
  ];

  static const _offTopicKeywords = [
    'homework',
    'essay',
    'python code',
    'javascript',
    'joke',
    'politics',
    'bitcoin',
    'medical advice',
    'legal advice',
    'recipe',
    'movie recommendation',
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
