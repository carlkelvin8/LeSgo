import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/polling_intervals.dart';
import '../di/local_storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/data_source/realtime_remote_datasource.dart';
import 'chat_websocket_service.dart';

typedef ChatRefreshCallback = void Function();

/// Realtime chat via WebSocket (Reverb) with HTTP notification fallback.
@lazySingleton
class ChatRealtimeService {
  ChatRealtimeService(
    this._realtimeDs,
    this._webSocket,
    this._localStorage,
    this._dioClient,
  );

  final RealtimeRemoteDataSource _realtimeDs;
  final ChatWebSocketService _webSocket;
  final LocalStorageService _localStorage;
  final DioClient _dioClient;

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

  void addListener(ChatRefreshCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(ChatRefreshCallback callback) {
    _listeners.remove(callback);
  }

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
      await _webSocket.subscribeConversation(conversationId);
    }
  }

  Future<void> release() async {
    if (_activeConversationId != null) {
      await _webSocket.unsubscribeConversation(_activeConversationId!);
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
      final session = await _realtimeDs.connect(platform: 'mobile');
      _connectionId = session['connection_id']?.toString();
    } catch (e) {
      debugPrint('Realtime session connect failed: $e');
    }

    await _ensureWebSocket();

    if (_activeConversationId != null) {
      await _webSocket.subscribeConversation(_activeConversationId!);
    }

    _timer = Timer.periodic(PollingIntervals.chatRealtime, (_) => _poll());
    await _poll();
  }

  Future<void> _ensureWebSocket() async {
    final userId = await _resolveUserId();
    if (userId == null) return;

    _webSocket.addHandler(_webSocketHandler);
    final ok = await _webSocket.connect(userId: userId);
    if (!ok) {
      debugPrint('WebSocket unavailable — using notification poll fallback');
    }
  }

  Future<int?> _resolveUserId() async {
    if (_userId != null) return _userId;
    try {
      if (_localStorage.token == null) return null;
      final me = await _dioClient.dio.get(ApiConstants.authMe);
      final data = me.data['data'] as Map<String, dynamic>? ?? {};
      _userId = (data['id'] as num?)?.toInt();
      return _userId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    _webSocket.removeHandler(_webSocketHandler);
    await _webSocket.disconnect();

    final connectionId = _connectionId;
    _connectionId = null;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _realtimeDs.disconnect(connectionId);
      } catch (_) {}
    }
  }

  Future<void> _poll() async {
    final connectionId = _connectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _realtimeDs.ping(connectionId);
      } catch (_) {}
    }

    if (_webSocket.isConnected) return;

    try {
      final notifications = await _realtimeDs.fetchNotifications(
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
          await _realtimeDs.markNotificationRead(id);
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
