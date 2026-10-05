import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import 'dto/chat/chat_dto.dart';

class ChatRemoteDataSource {
  final DioClient _dioClient;

  ChatRemoteDataSource(this._dioClient);

  // Get conversations list
  Future<List<ConversationDto>> getConversations() async {
    final response = await _dioClient.dio.get(ApiConstants.chatConversations);
    
    if (response.data['success'] == true && response.data['data'] != null) {
      final dynamic rawData = response.data['data'];
      final List<dynamic> dataList = rawData is List ? rawData : (rawData['data'] ?? []);
      return dataList.map((json) => ConversationDto.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to get conversations');
  }

  // Get or create conversation for order
  Future<ConversationDto> getOrCreateConversation(int orderId) async {
    final response = await _dioClient.dio.get(
      ApiConstants.chatConversationByOrder.replaceAll('{order_id}', orderId.toString()),
    );
    
    if (response.data['success'] == true && response.data['data'] != null) {
      return ConversationDto.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to get conversation');
  }

  // Get messages for conversation
  Future<List<MessageDto>> getMessages(int conversationId, {int page = 1, int limit = 50}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.chatMessages.replaceAll('{id}', conversationId.toString()),
      queryParameters: {
        'page': page,
        'per_page': limit,
      },
    );
    
    if (response.data['success'] == true && response.data['data'] != null) {
      final dynamic rawData = response.data['data'];
      final List<dynamic> dataList = rawData is List ? rawData : (rawData['data'] ?? []);
      return dataList.map((json) => MessageDto.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to get messages');
  }

  // Send message
  Future<MessageDto> sendMessage(SendMessageDto request) async {
    final response = await _dioClient.dio.post(
      ApiConstants.chatSendMessage.replaceAll('{id}', request.conversationId.toString()),
      data: {'message': request.message},
    );
    
    if (response.data['success'] == true && response.data['data'] != null) {
      return MessageDto.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to send message');
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final response = await _dioClient.dio.get(ApiConstants.chatUnreadCount);
    
    if (response.data['success'] == true && response.data['data'] != null) {
      return response.data['data']['unread_count'] ?? 0;
    }
    throw Exception(response.data['message'] ?? 'Failed to get unread count');
  }

  // Mark messages as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.chatMarkAsRead.replaceAll('{id}', conversationId.toString()),
      );
    } catch (_) {
      // Silently ignore — not critical if mark-as-read fails
    }
  }

  Future<void> sendTypingIndicator(int conversationId) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.chatTyping.replaceAll('{id}', conversationId.toString()),
      );
    } catch (_) {}
  }

  Future<void> endConversation(int conversationId) async {
    await _dioClient.dio.post(
      ApiConstants.chatEndConversation.replaceAll('{id}', conversationId.toString()),
    );
  }
}