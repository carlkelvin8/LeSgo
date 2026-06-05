import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../../data/data_source/realtime_remote_datasource.dart';
import '../di/local_storage_service.dart';

typedef ChatWebSocketEventHandler = void Function(
  String eventName,
  Map<String, dynamic> payload,
);

/// Laravel Reverb WebSocket client for instant chat delivery.
@lazySingleton
class ChatWebSocketService {
  ChatWebSocketService(this._realtimeDs, this._localStorage);

  final RealtimeRemoteDataSource _realtimeDs;
  final LocalStorageService _localStorage;

  ReverbClient? _client;
  bool _connected = false;
  final Set<ChatWebSocketEventHandler> _handlers = {};
  final Set<String> _subscribedChannels = {};

  bool get isConnected => _connected;

  void addHandler(ChatWebSocketEventHandler handler) {
    _handlers.add(handler);
  }

  void removeHandler(ChatWebSocketEventHandler handler) {
    _handlers.remove(handler);
  }

  Future<bool> connect({required int userId}) async {
    if (_connected && _client != null) {
      await subscribeUserChannel(userId);
      return true;
    }

    final config = await _realtimeDs.fetchConfig();
    if (config['enabled'] != true) {
      debugPrint('WebSocket disabled: Reverb not configured on server');
      return false;
    }

    final token = _localStorage.token;
    if (token == null || token.isEmpty) {
      return false;
    }

    final host = config['host']?.toString() ?? '';
    final port = (config['port'] as num?)?.toInt() ?? 443;
    final useTls = config['use_tls'] == true || config['scheme'] == 'https';
    final authEndpoint = config['auth_endpoint']?.toString() ?? '';
    final appKey = config['key']?.toString() ?? '';

    if (host.isEmpty || appKey.isEmpty || authEndpoint.isEmpty) {
      return false;
    }

    _client = ReverbClient.instance(
      host: host,
      port: port,
      appKey: appKey,
      useTLS: useTls,
      authEndpoint: authEndpoint,
      authorizer: (channelName, socketId) async {
        return {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
      },
      onConnected: (_) => _connected = true,
      onDisconnected: () => _connected = false,
      onError: (error) => debugPrint('Reverb error: $error'),
    );

    await _client!.connect();
    await subscribeUserChannel(userId);
    _connected = true;
    return true;
  }

  Future<void> subscribeUserChannel(int userId) async {
    await _subscribePrivate('private-user.$userId');
  }

  Future<void> subscribeConversation(int conversationId) async {
    await _subscribePrivate('private-conversation.$conversationId', events: [
      'chat.message.sent',
      'notification.sent',
    ]);
  }

  Future<void> subscribeOrder(int orderId) async {
    await _subscribePrivate('private-order.$orderId', events: [
      'driver.location.updated',
      'order.status.updated',
    ]);
  }

  Future<void> unsubscribeOrder(int orderId) async {
    final channelName = 'private-order.$orderId';
    _client?.unsubscribeFromChannel(channelName);
    _subscribedChannels.remove(channelName);
  }

  Future<void> unsubscribeConversation(int conversationId) async {
    final channelName = 'private-conversation.$conversationId';
    _client?.unsubscribeFromChannel(channelName);
    _subscribedChannels.remove(channelName);
  }

  Future<void> _subscribePrivate(
    String channelName, {
    List<String> events = const [],
  }) async {
    if (_client == null || _subscribedChannels.contains(channelName)) return;

    final channel = _client!.subscribeToPrivateChannel(channelName);
    await channel.subscribe();

    final bindings = events.isEmpty
        ? ['chat.message.sent', 'notification.sent']
        : events;
    for (final event in bindings) {
      channel.bind(event, (eventName, data) {
        _dispatch(eventName, data);
      });
    }

    _subscribedChannels.add(channelName);
  }

  void _dispatch(String eventName, dynamic data) {
    Map<String, dynamic> payload = {};
    if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    } else if (data != null) {
      payload = {'raw': data};
    }

    for (final handler in List.of(_handlers)) {
      handler(eventName, payload);
    }
  }

  Future<void> disconnect() async {
    for (final channelName in _subscribedChannels.toList()) {
      _client?.unsubscribeFromChannel(channelName);
    }
    _subscribedChannels.clear();
    _client?.disconnect();
    _client = null;
    _connected = false;
  }
}
