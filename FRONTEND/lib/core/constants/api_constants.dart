import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String googleMapsApiKey =
      'AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4';

  // API Base
  // - Web browser: 127.0.0.1 (localhost)
  // - Android emulator: 10.0.2.2 (routes to host machine)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
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

  ApiConstants._();
}
