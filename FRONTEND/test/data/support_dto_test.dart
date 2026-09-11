import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/support/support_dto.dart';

void main() {
  test('SupportTicketDto accepts the API minimal ticket response', () {
    final ticket = SupportTicketDto.fromJson({
      'id': 1,
      'user_id': 64,
      'subject': 'Need assistance',
      'status': 'open',
    });

    expect(ticket.description, isEmpty);
    expect(ticket.category, 'general_inquiry');
    expect(ticket.priority, 'medium');
    expect(ticket.createdAt, isEmpty);
    expect(ticket.updatedAt, isEmpty);
  });
}
