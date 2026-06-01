import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String googleMapsApiKey =
      'AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA';

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

  // Chat endpoints
  static const String chatConversations = '/v1/chat/conversations';
  static const String chatConversationByOrder = '/v1/chat/conversations/order/{order_id}';
  static const String chatMessages = '/v1/chat/conversations/{id}/messages';
  static const String chatSendMessage = '/v1/chat/conversations/{id}/messages';
  static const String chatSendSystemMessage = '/v1/chat/conversations/{id}/system-message';
  static const String chatEndConversation = '/v1/chat/conversations/{id}/end';
  static const String chatUnreadCount = '/v1/chat/unread-count';
  static const String chatMarkAsRead = '/v1/chat/conversations/{id}/read';

  // Missions, vouchers, FAQ, loyalty
  static const String missions = '/v1/missions';
  static String missionClaim(int missionId) => '/v1/missions/$missionId/claim';
  static const String vouchersAvailable = '/v1/vouchers/available';
  static const String faqArticles = '/v1/faq/articles';
  static const String loyaltyRewards = '/v1/loyalty/rewards';
  static String loyaltyRedeem(int rewardId) => '/v1/loyalty/rewards/$rewardId/redeem';

  // Referrals, surveys, devices, security
  static const String referralDashboard = '/v1/referrals/dashboard';
  static const String customerSurvey = '/v1/feedback/customer-satisfaction';
  static const String deviceRegister = '/v1/devices/register';
  static const String securityDashboard = '/v1/security/dashboard';
  static const String security2faSetup = '/v1/security/2fa/setup';
  static const String securityBiometrics = '/v1/security/biometrics';
  static const String securityAuditLogs = '/v1/security/audit-logs';

  ApiConstants._();
}
