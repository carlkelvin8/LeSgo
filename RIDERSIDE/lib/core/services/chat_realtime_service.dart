import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/polling_intervals.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../services/secure_storage_service.dart';
import 'chat_websocket_service.dart';
import 'realtime_remote_datasource.dart';

typedef ChatRefreshCallback = void Function();

class ChatRealtimeService {
  ChatRealtimeService._();
  static final ChatRealtimeService instance = ChatRealtimeService._();

  Timer? _timer;
  String? _connectionId;
  int _refCount = 0;
  int? _activeConversationId;
  int? _userId;
  final Set<ChatRefreshCallback> _listeners = {};
  final Set<int> _seenNotificationIds = {};

  late final ChatWebSocketEventHandler _webSocketHandler = (eventName, payload) {
    if (_isChatWebSocketEvent(eventName, payload)) {
      notifyChatUpdate();
    }
  };

  void addListener(ChatRefreshCallback callback) => _listeners.add(callback);

  void removeListener(ChatRefreshCallback callback) =>
      _listeners.remove(callback);

  void notifyChatUpdate() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Future<void> acquire({int? conversationId}) async {
    _refCount++;
    if (conversationId != null) {
      _activeConversationId = conversationId;
    }
    if (_refCount == 1) {
      await _start();
    } else if (conversationId != null) {
      await ChatWebSocketService.instance.subscribeConversation(conversationId);
    }
  }

  Future<void> release() async {
    if (_activeConversationId != null) {
      await ChatWebSocketService.instance
          .unsubscribeConversation(_activeConversationId!);
      _activeConversationId = null;
    }
    _refCount--;
    if (_refCount <= 0) {
      _refCount = 0;
      await _stop();
    }
  }

  Future<void> _start() async {
    if (_timer != null) return;

    try {
      final session = await RealtimeRemoteDataSource.connect(platform: 'mobile');
      _connectionId = session['connection_id']?.toString();
    } catch (e) {
      debugPrint('Realtime session connect failed: $e');
    }

    try {
      await _ensureWebSocket();

      if (_activeConversationId != null) {
        await ChatWebSocketService.instance
            .subscribeConversation(_activeConversationId!);
      }
    } catch (e) {
      debugPrint('WebSocket setup failed: $e');
    }

    _timer = Timer.periodic(PollingIntervals.chatRealtime, (_) => _poll());
    await _poll();
  }

  Future<void> _ensureWebSocket() async {
    final userId = await _resolveUserId();
    if (userId == null) return;

    ChatWebSocketService.instance.addHandler(_webSocketHandler);
    final ok = await ChatWebSocketService.instance.connect(userId: userId);
    if (!ok) {
      debugPrint('WebSocket unavailable — using notification poll fallback');
    }
  }

  Future<int?> _resolveUserId() async {
    if (_userId != null) return _userId;
    final stored = await SecureStorageService.getUserId();
    if (stored != null) {
      _userId = stored;
      return _userId;
    }
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return null;
      final me = await getIt<DioClient>().dio.get(ApiConstants.authMe);
      final data = me.data['data'] as Map<String, dynamic>? ?? {};
      _userId = (data['id'] as num?)?.toInt();
      if (_userId != null) {
        await SecureStorageService.saveUserId(_userId!);
      }
      return _userId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    ChatWebSocketService.instance.removeHandler(_webSocketHandler);
    await ChatWebSocketService.instance.disconnect();

    final connectionId = _connectionId;
    _connectionId = null;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await RealtimeRemoteDataSource.disconnect(connectionId);
      } catch (_) {}
    }
  }

  Future<void> _poll() async {
    final connectionId = _connectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await RealtimeRemoteDataSource.ping(connectionId);
      } catch (_) {}
    }

    if (ChatWebSocketService.instance.isConnected) return;

    try {
      final notifications = await RealtimeRemoteDataSource.fetchNotifications(
        unreadOnly: true,
        type: 'chat_message',
        perPage: 30,
      );
      var shouldRefresh = false;
      for (final notification in notifications) {
        final id = (notification['id'] as num?)?.toInt();
        if (id == null || _seenNotificationIds.contains(id)) continue;
        if (!_isChatRelated(notification)) continue;

        _seenNotificationIds.add(id);
        shouldRefresh = true;
        try {
          await RealtimeRemoteDataSource.markNotificationRead(id);
        } catch (_) {}
      }

      if (shouldRefresh) {
        notifyChatUpdate();
      }
    } catch (_) {}
  }

  bool _isChatWebSocketEvent(String eventName, Map<String, dynamic> payload) {
    final name = eventName.toLowerCase();
    if (name.contains('chat.message') || name.contains('notification.sent')) {
      if (name.contains('notification')) {
        final notification = payload['notification'];
        if (notification is Map) {
          final type = notification['type']?.toString() ?? '';
          return type == 'chat_message';
        }
      }
      return true;
    }
    return false;
  }

  bool _isChatRelated(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toLowerCase() ?? '';
    if (type.contains('chat') || type.contains('message')) {
      return true;
    }
    final data = notification['data'];
    if (data is Map &&
        (data['conversation_id'] != null || data['order_id'] != null)) {
      return true;
    }
    return false;
  }
}
