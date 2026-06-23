import '../config/secrets_config.dart';

class ApiConstants {
  /// Restricted Google Maps key from `--dart-define-from-file=secrets.json`.
  static String get googleMapsApiKey => SecretsConfig.googleMapsApiKey;

  static bool get isGoogleMapsConfigured => SecretsConfig.isGoogleMapsConfigured;

  // API Base URL - Force Production for testing
  static String get baseUrl {
    // Force production API for testing
    return 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';
    
    // Original logic (commented out)
    // if (kDebugMode) {
    //   // Development - Local server
    //   return 'http://10.0.2.2:8000/api'; // Android emulator localhost
    // } else {
    //   // Production - Laravel Cloud server
    //   return 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';
    // }
  }

  static const String loginEndpoint = '/v1/auth/login';
  static const String logoutEndpoint = '/v1/auth/logout';
  static const String authRefresh = '/v1/auth/refresh';
  static const String authChangePassword = '/v1/auth/change-password';
  static const String authDeactivateAccount = '/v1/auth/account/deactivate';
  static const String authDeleteAccount = '/v1/auth/account/delete';
  
  // Auth endpoints
  static const String authMe = '/v1/auth/me';
  static const String googleSignIn = '/v1/auth/google';
  
  // User endpoints
  static String userById(int userId) => '/v1/users/$userId';
  
  // Order endpoints
  static const String orders = '/v1/orders';
  static const String orderEstimate = '/v1/orders/estimate';
  static String orderById(int orderId) => '/v1/orders/$orderId';
  static String orderStatus(int orderId) => '/v1/orders/$orderId/status';
  static String orderReceipt(int orderId) => '/v1/orders/$orderId/receipt';
  
  // Partner endpoints
  static const String partners = '/v1/partners';
  static String partnerById(int id) => '/v1/partners/$id';
  static String partnerMenu(int partnerId) => '/v1/partners/$partnerId/menu';
  static String partnerBranches(int partnerId) => '/v1/partners/$partnerId/branches';
  static String branchById(int branchId) => '/v1/branches/$branchId';
  
  // Legacy partner endpoints (for backward compatibility)
  static const String partnersEndpoint = '/v1/partners';
  static String partnerByIdEndpoint(int id) => '/v1/partners/$id';
  static String partnerBranchesEndpoint(int partnerId) => '/v1/partners/$partnerId/branches';
  static String branchByIdEndpoint(int branchId) => '/v1/branches/$branchId';
  
  // Service endpoints
  static const String servicesEndpoint = '/v1/services';
  static String serviceByIdEndpoint(int id) => '/v1/services/$id';

  // Chat endpoints - using functions for type safety
  static const String chatConversations = '/v1/chat/conversations';
  static String chatConversationByOrder(int orderId) => '/v1/chat/conversations/order/$orderId';
  static String chatMessages(int conversationId) => '/v1/chat/conversations/$conversationId/messages';
  static String chatSendMessage(int conversationId) => '/v1/chat/conversations/$conversationId/messages';
  static String chatSendSystemMessage(int conversationId) => '/v1/chat/conversations/$conversationId/system-message';
  static String chatEndConversation(int conversationId) => '/v1/chat/conversations/$conversationId/end';
  static const String chatUnreadCount = '/v1/chat/unread-count';
  static String chatMarkAsRead(int conversationId) => '/v1/chat/conversations/$conversationId/read';

  // Missions, vouchers, FAQ, loyalty
  static const String missions = '/v1/missions';
  static String missionClaim(int missionId) => '/v1/missions/$missionId/claim';
  static const String vouchersAvailable = '/v1/vouchers/available';
  static const String faqArticles = '/v1/faq/articles';
  static const String loyaltyRewards = '/v1/loyalty/rewards';
  static String loyaltyRedeem(int rewardId) => '/v1/loyalty/rewards/$rewardId/redeem';

  // Referrals, surveys, devices, security, tracking, distance, payments
  static const String referralDashboard = '/v1/referrals/dashboard';
  static const String customerSurvey = '/v1/feedback/customer-satisfaction';
  static const String deviceRegister = '/v1/devices/register';
  static const String authFcmToken = '/v1/auth/fcm-token';
  static const String securityDashboard = '/v1/security/dashboard';
  static const String security2faSetup = '/v1/security/2fa/setup';
  static const String securityBiometrics = '/v1/security/biometric/list';
  static const String securityAuditLogs = '/v1/security/audit/logs';
  static String orderTracking(int orderId) => '/v1/orders/$orderId/tracking';
  static String orderDriverLocation(int orderId) => '/v1/orders/$orderId/driver-location';
  static String orderReorder(int orderId) => '/v1/orders/$orderId/reorder';
  static String partnerReviews(int partnerId) => '/v1/partners/$partnerId/reviews';
  static const String distanceCalculate = '/v1/distance/calculate';
  static const String distanceOverall = '/v1/distance/overall';
  static const String paymentGatewayRefunds = '/v1/payment-gateway/refunds';
  static const String geofenceCheck = '/v1/geofences/location/check';
  static const String geofences = '/v1/geofences';

  // Support tickets
  static const String supportTickets = '/v1/support/tickets';
  static const String supportTicketStatistics = '/v1/support/tickets/statistics';
  static String supportTicketById(int id) => '/v1/support/tickets/$id';
  static String supportTicketMessages(int id) => '/v1/support/tickets/$id/messages';
  static String supportTicketClose(int id) => '/v1/support/tickets/$id/close';
  static String supportTicketSatisfaction(int id) =>
      '/v1/support/tickets/$id/satisfaction';
  static const String supportUpload = '/v1/support/upload';
  static const String mediaUpload = '/v1/media/upload';

  // Document verification
  static const String documentsSubmit = '/v1/documents/submit';
  static const String documentsUpload = '/v1/documents/upload';
  static const String documentsMy = '/v1/documents/my-documents';
  static const String documentsTypes = '/v1/documents/types';
  static const String documentsVerificationStatus = '/v1/documents/verification-status';
  static String documentById(int id) => '/v1/documents/$id';
  static String documentResubmit(int id) => '/v1/documents/$id/resubmit';

  // Analytics
  static const String analyticsTrackEvent = '/v1/analytics/events/track';

  // Realtime / tracking (canonical paths)
  static const String realtimeConnect = '/v1/realtime/connect';
  static const String realtimeConfig = '/v1/realtime/config';
  static const String realtimeDisconnect = '/v1/realtime/disconnect';
  static const String realtimePing = '/v1/realtime/ping';
  static const String broadcastingAuth = '/v1/broadcasting/auth';
  static const String realtimeNotifications = '/v1/realtime/notifications';
  static String realtimeNotificationRead(int id) =>
      '/v1/realtime/notifications/$id/read';
  static const String realtimeNotificationsReadAll =
      '/v1/realtime/notifications/read-all';
  static String trackingLive(int orderId) => '/v1/tracking/order/$orderId/live';
  static String trackingEta(int orderId) => '/v1/tracking/order/$orderId/eta';
  static const String trackingRoute = '/v1/tracking/route';
  static String trackingOrder(int orderId) => '/v1/tracking/orders/$orderId';
  static String trackingOrderLocation(int orderId) =>
      '/v1/tracking/orders/$orderId/location';

  // Notifications
  static const String notifications = '/v1/notifications';
  static const String notificationsUnreadCount = '/v1/notifications/unread-count';
  static const String notificationsReadAll = '/v1/notifications/read-all';
  static String notificationMarkRead(int id) => '/v1/notifications/$id/read';

  // Security (full)
  static const String security2faVerify = '/v1/security/2fa/verify';
  static const String security2faDisable = '/v1/security/2fa/disable';
  static const String security2faRegenerateCodes =
      '/v1/security/2fa/backup-codes/regenerate';
  static const String securityBiometricEnroll = '/v1/security/biometric/enroll';
  static const String securityBiometricDeactivate =
      '/v1/security/biometric/deactivate';

  // Vouchers, missions, social, wallet linking
  static const String vouchersClaim = '/v1/vouchers/claim';
  static String missionProgress(int missionId) => '/v1/missions/$missionId/progress';
  static const String socialFollowConfirm = '/v1/social/follow/confirm';
  static const String socialReferralShare = '/v1/social/referral/share';
  static const String walletLinkedAccounts = '/v1/wallets/my/linked-accounts';
  static String walletLinkedAccountVerify(String provider) =>
      '/v1/wallets/my/linked-accounts/$provider/verify';
  static String walletUnlinkAccount(String provider) =>
      '/v1/wallets/my/linked-accounts/$provider';

  ApiConstants._();
}
