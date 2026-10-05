import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/file_upload_service.dart';
import 'package:lesgo/data/data_source/support_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/support/support_dto.dart';
import 'package:lesgo/presentation/screens/main/support/support_ticket_detail_screen.dart';

class FakeUpload extends Fake implements FileUploadService {}

class FakeSupport extends Fake implements SupportRemoteDataSource {
  CreateTicketDto? lastRequest;
  int creates = 0;
  int replies = 0;
  bool fail = false;
  final messages = <TicketMessageDto>[];
  final ticket = SupportTicketDto(
    id: 42,
    userId: 1,
    subject: 'Help',
    description: 'Hello',
    category: 'general',
    priority: 'medium',
    status: 'open',
    createdAt: '2026-09-13T01:00:00Z',
    updatedAt: '2026-09-13T01:00:00Z',
  );
  @override
  Future<SupportTicketDto> createTicket(
    CreateTicketDto request, {
    List<String>? attachments,
  }) async {
    lastRequest = request;
    creates++;
    if (fail) throw Exception('Network error');
    messages.add(
      TicketMessageDto(
        id: 1,
        ticketId: 42,
        userId: 1,
        message: request.description,
        isStaff: false,
        createdAt: ticket.createdAt,
      ),
    );
    return ticket;
  }

  @override
  Future<SupportTicketDetail> getTicket(int id) async =>
      SupportTicketDetail(ticket: ticket, messages: List.of(messages));
  @override
  Future<TicketMessageDto> addMessage(
    int id,
    String message, {
    List<String>? attachments,
  }) async {
    replies++;
    final reply = TicketMessageDto(
      id: 2,
      ticketId: id,
      userId: 1,
      message: message,
      isStaff: false,
      createdAt: ticket.createdAt,
    );
    messages.add(reply);
    return reply;
  }
}

void main() {
  late FakeSupport support;
  setUp(() {
    support = FakeSupport();
    getIt.registerSingleton<SupportRemoteDataSource>(support);
    getIt.registerSingleton<FileUploadService>(FakeUpload());
  });
  tearDown(() async {
    await getIt.reset();
  });
  test('parses agent messages and image attachments from the API', () {
    final message = TicketMessageDto.fromJson({
      'id': 1,
      'ticket_id': 42,
      'user_id': 5,
      'message': 'Hello',
      'user': {'role': 'admin'},
      'created_at': '2026-09-13',
      'attachments': ['https://example.com/image.png'],
    });
    expect(message.isStaff, isTrue);
    expect(message.attachments, hasLength(1));
  });
  testWidgets(
    'first message creates a conversation; next message replies to it',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SupportTicketDetailScreen())),
      );
      expect(find.text('How can we help?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Help with my order');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(support.creates, 1);
      expect(support.lastRequest!.toJson()['category'], 'general_inquiry');
      expect(find.text('Help with my order'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Here is more detail');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(support.creates, 1);
      expect(support.lastRequest!.toJson()['category'], 'general_inquiry');
      expect(support.replies, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('failed send keeps the draft for retry', (tester) async {
    support.fail = true;
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SupportTicketDetailScreen())),
    );
    await tester.enterText(find.byType(TextField), 'Please help');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Please help'), findsOneWidget);
    expect(find.text('How can we help?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('composer remains usable on a small phone with keyboard open', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SupportTicketDetailScreen())),
    );
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'I need help with an order');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Send message').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'rejects the legacy fake-success response with a friendly mappable error',
    () {
      expect(
        () => SupportTicketDto.fromJson({
          'id': 0,
          'user_id': 1,
          'subject': 'Live agent support',
          'status': 'open',
        }),
        throwsFormatException,
      );
    },
  );
  test('legacy general category uses the database enum value', () {
    expect(
      CreateTicketDto(
        subject: 'Help',
        description: 'Hello',
        category: 'general',
      ).toJson()['category'],
      'general_inquiry',
    );
  });
  testWidgets('order topic sends the supported order category', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SupportTicketDetailScreen())),
    );
    await tester.scrollUntilVisible(
      find.text('Order help'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Order help'));
    await tester.enterText(find.byType(TextField), 'Order concern');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(support.lastRequest!.toJson()['category'], 'order_issue');
    await tester.pumpWidget(const SizedBox());
  });
}

