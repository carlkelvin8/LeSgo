import 'package:flutter/foundation.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

import '../services/secure_storage_service.dart';
import 'realtime_remote_datasource.dart';

typedef ChatWebSocketEventHandler = void Function(
  String eventName,
  Map<String, dynamic> payload,
);

class ChatWebSocketService {
  ChatWebSocketService._();
  static final ChatWebSocketService instance = ChatWebSocketService._();

  ReverbClient? _client;
  bool _connected = false;
  final Set<ChatWebSocketEventHandler> _handlers = {};
  final Set<String> _subscribedChannels = {};

  bool get isConnected => _connected;

  void addHandler(ChatWebSocketEventHandler handler) => _handlers.add(handler);

  void removeHandler(ChatWebSocketEventHandler handler) =>
      _handlers.remove(handler);

  Future<bool> connect({required int userId}) async {
    if (_connected && _client != null) {
      await subscribeUserChannel(userId);
      return true;
    }

    final config = await RealtimeRemoteDataSource.fetchConfig();
    if (config['enabled'] != true) {
      debugPrint('WebSocket disabled: Reverb not configured on server');
      return false;
    }

    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) return false;

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
    await _subscribePrivate(
      'private-conversation.$conversationId',
      events: const ['chat.message.sent', 'notification.sent'],
    );
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
        ? const ['chat.message.sent', 'notification.sent']
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
