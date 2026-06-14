import 'package:flutter/foundation.dart';

import '../config/secrets_config.dart';

class ApiConstants {
  static const String stagingBaseUrl =
      'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';
  static const String productionBaseUrl = 'https://api.lesgo.com/api';

  static String get baseUrl => ApiEnvironment.resolveBaseUrl();

  static const String authRefresh = '/v1/auth/refresh';
  static const String authChangePassword = '/v1/auth/change-password';
  static const String authDeactivateAccount = '/v1/auth/account/deactivate';
  static const String authFcmToken = '/v1/auth/fcm-token';
  static const String deviceRegister = '/v1/devices/register';

  // Chat endpoints
  static const String chatConversations = '/v1/chat/conversations';
  static const String chatConversationByOrder =
      '/v1/chat/conversations/order/{order_id}';
  static const String chatMessages = '/v1/chat/conversations/{id}/messages';
  static const String chatSendMessage = '/v1/chat/conversations/{id}/messages';
  static const String chatSendSystemMessage =
      '/v1/chat/conversations/{id}/system-message';
  static const String chatEndConversation = '/v1/chat/conversations/{id}/end';
  static const String chatUnreadCount = '/v1/chat/unread-count';
  static const String chatMarkAsRead = '/v1/chat/conversations/{id}/read';

  // Parity endpoints (shared with customer app)
  static const String faqArticles = '/v1/faq/articles';
  static const String vouchersAvailable = '/v1/vouchers/available';
  static const String vouchersClaim = '/v1/vouchers/claim';
  static const String loyaltyRewards = '/v1/loyalty/rewards';
  static String loyaltyRedeem(int rewardId) =>
      '/v1/loyalty/rewards/$rewardId/redeem';
  static const String referralDashboard = '/v1/referrals/dashboard';
  static const String securityDashboard = '/v1/security/dashboard';
  static const String security2faSetup = '/v1/security/2fa/setup';
  static const String security2faVerify = '/v1/security/2fa/verify';
  static const String security2faDisable = '/v1/security/2fa/disable';
  static const String analyticsTrackEvent = '/v1/analytics/events/track';

  // Document verification
  static const String documentsSubmit = '/v1/documents/submit';
  static const String documentsUpload = '/v1/documents/upload';
  static const String documentsMy = '/v1/documents/my-documents';
  static const String documentsTypes = '/v1/documents/types';
  static const String documentsVerificationStatus =
      '/v1/documents/verification-status';
  static const String mediaUpload = '/v1/media/upload';

  ApiConstants._();
}

/// Resolves API host from compile-time defines (`secrets.json`) with safe defaults.
class ApiEnvironment {
  ApiEnvironment._();

  static String resolveBaseUrl() {
    final explicit = SecretsConfig.apiBaseUrl.trim();
    if (explicit.isNotEmpty && !_isPlaceholder(explicit)) {
      return normalizeBaseUrl(explicit);
    }

    switch (_normalizedEnv(SecretsConfig.apiEnv)) {
      case 'prod':
      case 'production':
        return ApiConstants.productionBaseUrl;
      case 'staging':
        return ApiConstants.stagingBaseUrl;
      case 'dev':
      case 'development':
        return _developmentBaseUrl;
      default:
        return kReleaseMode
            ? ApiConstants.productionBaseUrl
            : ApiConstants.stagingBaseUrl;
    }
  }

  static String get _developmentBaseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _normalizedEnv(String value) =>
      value.trim().toLowerCase().replaceAll('_', '-');

  static bool _isPlaceholder(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('your-') ||
        lower.startsWith('your_') ||
        lower.startsWith('http://your-') ||
        lower.contains('example.com');
  }
}
