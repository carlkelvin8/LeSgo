import 'support_api.dart';

/// The authenticated support inbox used by both riders and admin staff.
class RiderLiveSupportService {
  static const subject = 'Rider live support';

  Future<RiderSupportTicketDetail?> findConversation() async {
    final tickets = await SupportApi.getTickets(perPage: 100);
    for (final ticket in tickets) {
      if (ticket.subject == subject &&
          ticket.status != 'closed' &&
          ticket.status != 'cancelled') {
        return load(ticket.id);
      }
    }
    return null;
  }

  Future<RiderSupportTicket> create(String message) async {
    final ticket = await SupportApi.createTicket(
      subject: subject,
      description: message,
      category: 'general_inquiry',
    );
    if (ticket.id <= 0) {
      throw StateError(
        'Support could not save your message. Please try again.',
      );
    }
    return ticket;
  }

  Future<RiderSupportMessage> send(int ticketId, String message) =>
      SupportApi.addMessage(ticketId, message);

  Future<RiderSupportTicketDetail> load(int ticketId) =>
      SupportApi.getTicket(ticketId);
}
