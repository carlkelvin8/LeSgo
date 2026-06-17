import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Rider chat provider for managing conversations
final riderChatProvider = StateNotifierProvider.autoDispose.family<
    RiderChatNotifier,
    RiderChatState,
    String>((ref, orderId) => RiderChatNotifier(orderId));

/// Quick replies provider
final quickRepliesProvider = FutureProvider.autoDispose<List<QuickReply>>((ref) async {
  try {
    final response = await ApiService.dio.get('/v1/drivers/me/quick-replies');
    final data = response.data['data'] ?? response.data;
    
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => QuickReply.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  } catch (e) {
    AppLogger.error('Failed to load quick replies', e);
    return [];
  }
});

class RiderChatNotifier extends StateNotifier<RiderChatState> {
  final String orderId;

  RiderChatNotifier(this.orderId) : super(const RiderChatState());

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.dio.get('/v1/orders/$orderId/messages');
      final data = response.data['data'] ?? response.data;

      final messageList = (data is List)
          ? data
              .whereType<Map>()
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <ChatMessage>[];

      state = state.copyWith(
        messages: messageList,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load messages', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages',
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add optimistic message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      imageUrl: null,
      type: 'text',
      senderType: 'rider',
      timestamp: DateTime.now(),
      isRead: false,
      deliveryStatus: 'sending',
    );

    state = state.copyWith(
      messages: [tempMessage, ...state.messages],
    );

    try {
      final response = await ApiService.dio.post(
        '/v1/orders/$orderId/messages',
        data: {
          'text': text,
          'type': 'text',
        },
      );

      final responseData = response.data['data'] ?? response.data;
      final sentMessage = ChatMessage.fromJson(Map<String, dynamic>.from(responseData));

      // Replace optimistic message with real one
      state = state.copyWith(
        messages: state.messages.map((msg) {
          if (msg.id == tempMessage.id) return sentMessage;
          return msg;
        }).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to send message', e);
      // Update message status to failed
      state = state.copyWith(
        messages: state.messages.map((msg) {
          if (msg.id == tempMessage.id) {
            return msg.copyWith(deliveryStatus: 'failed');
          }
          return msg;
        }).toList(),
        error: 'Failed to send message',
      );
    }
  }

  Future<void> sendImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'type': 'image',
      });

      // Add optimistic image message
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Image',
        imageUrl: imagePath,
        type: 'image',
        senderType: 'rider',
        timestamp: DateTime.now(),
        isRead: false,
        deliveryStatus: 'sending',
      );

      state = state.copyWith(
        messages: [tempMessage, ...state.messages],
      );

      final response = await ApiService.dio.post(
        '/v1/orders/$orderId/messages',
        data: formData,
      );

      final responseData = response.data['data'] ?? response.data;
      final sentMessage = ChatMessage.fromJson(Map<String, dynamic>.from(responseData));

      state = state.copyWith(
        messages: state.messages.map((msg) {
          if (msg.id == tempMessage.id) return sentMessage;
          return msg;
        }).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to send image', e);
      state = state.copyWith(error: 'Failed to send image');
    }
  }

  Future<void> sendDeliveryProof(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'type': 'delivery_proof',
      });

      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Delivery Proof',
        imageUrl: imagePath,
        type: 'delivery_proof',
        senderType: 'rider',
        timestamp: DateTime.now(),
        isRead: false,
        deliveryStatus: 'sending',
      );

      state = state.copyWith(
        messages: [tempMessage, ...state.messages],
      );

      final response = await ApiService.dio.post(
        '/v1/orders/$orderId/messages',
        data: formData,
      );

      final responseData = response.data['data'] ?? response.data;
      final sentMessage = ChatMessage.fromJson(Map<String, dynamic>.from(responseData));

      state = state.copyWith(
        messages: state.messages.map((msg) {
          if (msg.id == tempMessage.id) return sentMessage;
          return msg;
        }).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to send delivery proof', e);
      state = state.copyWith(error: 'Failed to send delivery proof');
    }
  }

  Future<void> sendQuickReply(String replyText) async {
    await sendMessage(replyText);
  }

  Future<void> markAsRead() async {
    try {
      await ApiService.dio.post(
        '/v1/orders/$orderId/messages/read',
      );
    } catch (e) {
      AppLogger.error('Failed to mark messages as read', e);
    }
  }

  Future<void> refreshMessages() async {
    await loadMessages();
  }
}

class RiderChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const RiderChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => messages.where((m) => !m.isRead && m.senderType != 'rider').length;
  bool get hasErrors => messages.any((m) => m.deliveryStatus == 'failed');

  RiderChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final String type; // 'text', 'image', 'delivery_proof'
  final String senderType; // 'rider', 'customer'
  final DateTime timestamp;
  final bool isRead;
  final String deliveryStatus; // 'sending', 'sent', 'read', 'failed'

  const ChatMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.type,
    required this.senderType,
    required this.timestamp,
    required this.isRead,
    required this.deliveryStatus,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      type: json['type']?.toString() ?? 'text',
      senderType: json['sender_type']?.toString() ?? 'rider',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString()).toLocal()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      deliveryStatus: json['delivery_status']?.toString() ?? 'sent',
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    String? imageUrl,
    String? type,
    String? senderType,
    DateTime? timestamp,
    bool? isRead,
    String? deliveryStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      senderType: senderType ?? this.senderType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  bool get isSentByRider => senderType == 'rider';
  bool get isDelivered => deliveryStatus == 'sent' || deliveryStatus == 'read';
  bool get isFailed => deliveryStatus == 'failed';
  bool get isSending => deliveryStatus == 'sending';
}

class QuickReply {
  final String id;
  final String text;
  final int order;

  const QuickReply({
    required this.id,
    required this.text,
    required this.order,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
    );
  }
}


