import '../config/secrets_config.dart';

class ApiConstants {
  /// Canonical production API (per the backend OpenAPI spec).
  static const String _prodBaseUrl = 'https://api.lesgo.ph/api';

  /// Default staging / feature-branch server, hardcoded so release builds
  /// still work when no `--dart-define-from-file=secrets.json` is passed.
  static const String _defaultBaseUrl =
      'https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api';

  /// Resolution order:
  /// 1. `API_BASE_URL` from `secrets.json` (always wins)
  /// 2. `API_ENV=prod|production` -> canonical production host
  /// 3. hardcoded staging host
  static String get baseUrl {
    final override = SecretsConfig.apiBaseUrl.trim();
    if (override.isNotEmpty) return _trimTrailingSlash(override);

    final env = SecretsConfig.apiEnv.trim().toLowerCase();
    if (env == 'prod' || env == 'production') return _prodBaseUrl;

    return _defaultBaseUrl;
  }

  static String _trimTrailingSlash(String url) => url.endsWith('/')
      ? url.substring(0, url.length - 1)
      : url;

  static const String loginEndpoint = '/v1/auth/login';
  static const String logoutEndpoint = '/v1/auth/logout';

  static const String authRefresh = '/v1/auth/refresh';
  static const String authChangePassword = '/v1/auth/change-password';
  static const String authDeactivateAccount = '/v1/auth/account/deactivate';
  static const String authDeleteAccount = '/v1/auth/account/delete';
  static const String authFcmToken = '/v1/auth/fcm-token';
  static const String deviceRegister = '/v1/devices/register';
  static const String configMobile = '/v1/config/mobile';
  static const String appRiderVersion = '/v1/app/rider-version';

  // Chat endpoints
  static const String chatConversations = '/v1/chat/conversations';
  static const String chatConversationByOrder =
      '/v1/chat/conversations/order/{order_id}';
  static const String chatMessages = '/v1/chat/conversations/{id}/messages';
  static const String chatSendMessage = '/v1/chat/conversations/{id}/messages';
  static const String chatTyping = '/v1/chat/conversations/{id}/typing';
  static const String chatSendSystemMessage =
      '/v1/chat/conversations/{id}/system-message';
  static const String chatEndConversation = '/v1/chat/conversations/{id}/end';
  static const String chatUnreadCount = '/v1/chat/unread-count';
  static const String chatMarkAsRead = '/v1/chat/conversations/{id}/read';

  // FAQ
  static const String faqArticles = '/v1/faq/articles';
  static const String faqCategories = '/v1/faq/categories';
  static String faqCategoryArticles(int categoryId) =>
      '/v1/faq/categories/$categoryId';
  static const String faqSearch = '/v1/faq/search';
  static const String faqFeatured = '/v1/faq/featured';
  static const String faqPopular = '/v1/faq/popular';
  static String faqMarkHelpful(int articleId) =>
      '/v1/faq/articles/$articleId/helpful';
  static String faqMarkNotHelpful(int articleId) =>
      '/v1/faq/articles/$articleId/not-helpful';
  static const String vouchersAvailable = '/v1/vouchers/available';
  static const String vouchersClaim = '/v1/vouchers/claim';
  static const String loyaltyRewards = '/v1/loyalty/rewards';
  static const String referralDashboard = '/v1/referrals/dashboard';
  static const String securityDashboard = '/v1/security/dashboard';
  static const String security2faSetup = '/v1/security/2fa/setup';
  static const String security2faVerify = '/v1/security/2fa/verify';
  static const String security2faDisable = '/v1/security/2fa/disable';
  static const String security2faRegenerateCodes =
      '/v1/security/2fa/backup-codes/regenerate';
  static const String securityBiometrics = '/v1/security/biometric/list';
  static const String securityBiometricEnroll = '/v1/security/biometric/enroll';
  static const String securityBiometricDeactivate =
      '/v1/security/biometric/deactivate';
  static const String securityAuditLogs = '/v1/security/audit/logs';
  static const String analyticsTrackEvent = '/v1/analytics/events/track';

  // Notifications
  static const String notifications = '/v1/notifications';
  static const String notificationsUnreadCount = '/v1/notifications/unread-count';
  static const String notificationsReadAll = '/v1/notifications/read-all';
  static String notificationMarkRead(int id) => '/v1/notifications/$id/read';

  // Document verification
  static const String documentsSubmit = '/v1/documents/submit';
  static const String documentsUpload = '/v1/documents/upload';
  static const String documentsMy = '/v1/documents/my-documents';
  static const String documentsTypes = '/v1/documents/types';
  static const String documentsVerificationStatus =
      '/v1/documents/verification-status';
  static String documentById(int id) => '/v1/documents/$id';
  static String documentResubmit(int id) => '/v1/documents/$id/resubmit';
  static const String mediaUpload = '/v1/media/upload';

  // Driver earnings
  static const String driverMyEarnings = '/v1/drivers/me/earnings';
  static const String driverPackageTiers = '/v1/drivers/me/package-tiers';
  static const String driverPackageUpgrade = '/v1/drivers/me/package-upgrade';

  // Registration fee (rider & merchant)
  static const String registrationFeeStatus = '/v1/registration-fee/status';
  static const String registrationFeeCheckout = '/v1/registration-fee/checkout';
  static const String registrationFeeVerify = '/v1/registration-fee/verify';
  static const String registrationFeeConfig = '/v1/registration-fee/config';

  static const String walletTransferToRider = '/v1/wallets/my/transfer';

  // Support tickets
  static const String supportTickets = '/v1/support/tickets';
  static const String supportTicketStatistics = '/v1/support/tickets/statistics';
  static String supportTicketById(int id) => '/v1/support/tickets/$id';
  static String supportTicketMessages(int id) => '/v1/support/tickets/$id/messages';
  static String supportTicketSatisfaction(int id) =>
      '/v1/support/tickets/$id/satisfaction';
  static String supportTicketClose(int id) => '/v1/support/tickets/$id/close';
  static const String supportUpload = '/v1/support/upload';

  // Realtime / WebSocket
  static const String realtimeConfig = '/v1/realtime/config';
  static const String realtimeConnect = '/v1/realtime/connect';
  static const String realtimePing = '/v1/realtime/ping';
  static const String realtimeDisconnect = '/v1/realtime/disconnect';
  static const String realtimeNotifications = '/v1/realtime/notifications';
  static String realtimeNotificationRead(int id) =>
      '/v1/realtime/notifications/$id/read';
  static const String broadcastingAuth = '/v1/broadcasting/auth';
  static const String authMe = '/v1/auth/me';

  ApiConstants._();
}
