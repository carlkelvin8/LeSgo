class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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