import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/support/support_dto.dart';

@lazySingleton
class SupportRemoteDataSource {
  final DioClient _dioClient;

  SupportRemoteDataSource(this._dioClient);

  Future<List<SupportTicketDto>> getTickets({
    String? status,
    int perPage = 30,
  }) async {
    final response = await _dioClient.dio.get(
      ApiConstants.supportTickets,
      queryParameters: {
        if (status != null) 'status': status,
        'per_page': perPage,
      },
    );
    return _parseTicketList(response.data);
  }

  Future<SupportTicketDto> createTicket(
    CreateTicketDto request, {
    List<String>? attachments,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.supportTickets,
      data: {
        ...request.toJson(),
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SupportTicketDto.fromJson(data);
  }

  Future<SupportTicketDetail> getTicket(int ticketId) async {
    final response = await _dioClient.dio.get(
      ApiConstants.supportTicketById(ticketId),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SupportTicketDetail.fromJson(data);
  }

  Future<TicketMessageDto> addMessage(
    int ticketId,
    String message, {
    List<String>? attachments,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.supportTicketMessages(ticketId),
      data: {
        'message': message,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return TicketMessageDto.fromJson(data);
  }

  Future<Map<String, dynamic>> rateSatisfaction(
    int ticketId, {
    required int rating,
    String? comment,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.supportTicketSatisfaction(ticketId),
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _dioClient.dio.get(
      ApiConstants.supportTicketStatistics,
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  List<SupportTicketDto> _parseTicketList(dynamic body) {
    if (body is! Map<String, dynamic>) return [];
    final raw = body['data'];
    if (raw is List) {
      return raw
          .map((e) => SupportTicketDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .map((e) => SupportTicketDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

class SupportTicketDetail {
  final SupportTicketDto ticket;
  final List<TicketMessageDto> messages;
  final int? satisfactionRating;
  final String? satisfactionComment;

  SupportTicketDetail({
    required this.ticket,
    required this.messages,
    this.satisfactionRating,
    this.satisfactionComment,
  });

  bool get canRateSatisfaction =>
      satisfactionRating == null &&
      (ticket.status == 'resolved' || ticket.status == 'closed');

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final messagesRaw = json['messages'] as List? ?? [];
    return SupportTicketDetail(
      ticket: SupportTicketDto.fromJson(json),
      messages: messagesRaw
          .map((e) => TicketMessageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      satisfactionRating: (json['satisfaction_rating'] as num?)?.toInt(),
      satisfactionComment: json['satisfaction_comment']?.toString(),
    );
  }
}
