import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/network/dio_client.dart';
import 'package:lezgo_rider/core/services/chat_realtime_service.dart';
import 'package:lezgo_rider/core/services/gemini_customer_service.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/core/services/notification_payload.dart';
import 'package:lezgo_rider/data/data_source/chat_remote_datasource.dart';
import 'package:lezgo_rider/data/data_source/dto/chat/chat_dto.dart';
import 'package:lezgo_rider/presentation/provider/chat/chat_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_customer_service_chat_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_inbox_provider.dart';
import 'package:lezgo_rider/presentation/screens/chat/rider_chat_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_inbox_view.dart';

class _FakeDioClient implements DioClient {
  _FakeDioClient(this._dio);
  final Dio _dio;
  @override
  Dio get dio => _dio;
  @override
  void initialize() {}
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);
  final String body;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(body, 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
}

ChatRemoteDataSource _ds(String body) {
  final dio = Dio()..httpClientAdapter = _JsonAdapter(body);
  return ChatRemoteDataSource(_FakeDioClient(dio));
}

class _FailingChatDataSource implements ChatRemoteDataSource {
  int getOrCreateCalls = 0;
  @override
  Future<ConversationDto> getOrCreateConversation(int orderId) async {
    getOrCreateCalls++;
    throw Exception('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}

class _NotConfiguredGemini extends GeminiCustomerService {
  @override
  bool get isConfigured => false;
}

class _StaticInbox extends RiderInboxNotifier {
  _StaticInbox(RiderInboxState s) {
    state = s;
  }
  @override
  Future<void> loadConversations({bool silent = false}) async {}
}

void main() {
  group('unread count parsing', () {
    test('accepts string counts', () async {
      final ds = _ds('{"success":true,"data":{"count":"3","unread_count":"3"}}');
      expect(await ds.getUnreadCount(), 3);
    });
    test('empty PHP array does not throw', () async {
      final ds = _ds('{"success":true,"data":[]}');
      expect(await ds.getUnreadCount(), 0);
    });
  });

  group('notification payloads', () {
    test('toRaw round trips through parse', () {
      for (final raw in ['order_5', 'chat_order_7', 'chat_9', 'inbox', 'merchant_order']) {
        expect(NotificationPayload.parse(raw)!.toRaw(), raw);
      }
      expect(NotificationPayload.parse('zzz')!.toRaw(), isNull);
    });

    test('newer pending tap is not cleared by an older one finishing', () {
      f(String? c, String h, bool ok) =>
          NotificationNavigationService.pendingAfterHandling(c, h, ok);
      expect(f('chat_order_1', 'chat_order_1', true), isNull);
      expect(f('chat_order_1', 'chat_order_1', false), 'chat_order_1');
      expect(f('order_2', 'chat_order_1', true), 'order_2');
    });
  });

  group('admin support chat without Gemini key', () {
    test('files a real ticket and confirms only after success', () async {
      final sent = <String>[];
      final n = RiderCustomerServiceChatNotifier(
        _NotConfiguredGemini(),
        ticketSender: (t) async {
          sent.add(t);
          return '#42';
        },
      );
      await n.sendMessage('my wallet is stuck');
      expect(sent, ['my wallet is stuck']);
      expect(n.state.messages.last.text, contains('#42'));
      expect(n.state.error, isNull);
    });

    test('does not claim success when the ticket fails', () async {
      final n = RiderCustomerServiceChatNotifier(
        _NotConfiguredGemini(),
        ticketSender: (_) async => throw Exception('offline'),
      );
      await n.sendMessage('help');
      expect(n.state.error, isNotNull);
      expect(n.state.isSending, isFalse);
      expect(n.state.messages.where((m) => !m.isUser).length, 1); // welcome only
    });

    test('callback request files a ticket', () async {
      final sent = <String>[];
      final n = RiderCustomerServiceChatNotifier(
        _NotConfiguredGemini(),
        ticketSender: (t) async {
          sent.add(t);
          return '#1';
        },
      );
      await n.requestAdminCallback();
      expect(sent.single, contains('call me back'));
    });
  });

  group('chat realtime', () {
    test('a chat that failed to load never releases another chat\'s hold', () async {
      final before = ChatRealtimeService.instance.debugRefCount;
      final n = ChatNotifier(_FailingChatDataSource());
      await n.getOrCreateConversation(1);
      expect(n.state.error, isNotNull);
      n.stopRealtime();
      n.dispose();
      expect(ChatRealtimeService.instance.debugRefCount, before);
    });
  });

  testWidgets('chat Retry button actually retries', (tester) async {
    final ds = _FailingChatDataSource();
    await tester.pumpWidget(ProviderScope(
      overrides: [chatDataSourceProvider.overrideWithValue(ds)],
      child: const MaterialApp(home: RiderChatScreen(orderId: 1)),
    ));
    await tester.pumpAndSettle();
    expect(ds.getOrCreateCalls, 1);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(ds.getOrCreateCalls, 2);
  });

  testWidgets('inbox load failure still offers Admin Support', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riderInboxProvider.overrideWith(
            (ref) => _StaticInbox(const RiderInboxState(error: 'x'))),
      ],
      child: const MaterialApp(home: Scaffold(body: RiderInboxView())),
    ));
    await tester.pump();
    expect(find.text('Admin Support'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
