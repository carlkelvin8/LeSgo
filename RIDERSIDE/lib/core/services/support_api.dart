import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

class RiderSupportTicket {
  final int id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String createdAt;

  const RiderSupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory RiderSupportTicket.fromJson(Map<String, dynamic> json) {
    return RiderSupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class RiderSupportMessage {
  final int id;
  final int userId;
  final String message;
  final bool isStaff;
  final String createdAt;
  final String? authorName;
  final List<String> attachments;

  const RiderSupportMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.isStaff,
    required this.createdAt,
    this.authorName,
    this.attachments = const [],
  });

  factory RiderSupportMessage.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments.map((e) => e.toString()).toList()
        : <String>[];
    return RiderSupportMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      isStaff: json['is_internal'] == true ||
          (user is Map && user['role']?.toString() == 'admin'),
      createdAt: json['created_at']?.toString() ?? '',
      authorName: user is Map ? user['name']?.toString() : null,
      attachments: attachments,
    );
  }
}

class RiderSupportTicketDetail {
  final RiderSupportTicket ticket;
  final List<RiderSupportMessage> messages;
  final int? satisfactionRating;

  const RiderSupportTicketDetail({
    required this.ticket,
    required this.messages,
    this.satisfactionRating,
  });

  bool get canRateSatisfaction =>
      satisfactionRating == null &&
      (ticket.status == 'resolved' || ticket.status == 'closed');
}

class SupportApi {
  SupportApi._();

  static final _dio = getIt<DioClient>().dio;

  static List<RiderSupportTicket> _parseTicketList(dynamic body) {
    if (body is! Map<String, dynamic>) return [];
    final raw = body['data'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => RiderSupportTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => RiderSupportTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<RiderSupportTicket>> getTickets({
    String? status,
    int perPage = 30,
  }) async {
    final res = await _dio.get(
      ApiConstants.supportTickets,
      queryParameters: {
        if (status != null) 'status': status,
        'per_page': perPage,
      },
    );
    return _parseTicketList(res.data);
  }

  static Future<RiderSupportTicket> createTicket({
    required String subject,
    required String description,
    String category = 'general',
    String priority = 'medium',
    int? orderId,
  }) async {
    final res = await _dio.post(
      ApiConstants.supportTickets,
      data: {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
        if (orderId != null) 'order_id': orderId,
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return RiderSupportTicket.fromJson(data);
  }

  static Future<RiderSupportTicketDetail> getTicket(int ticketId) async {
    final res = await _dio.get(ApiConstants.supportTicketById(ticketId));
    final data = res.data['data'] as Map<String, dynamic>;
    final messagesRaw = data['messages'] as List? ?? [];
    return RiderSupportTicketDetail(
      ticket: RiderSupportTicket.fromJson(data),
      messages: messagesRaw
          .whereType<Map>()
          .map((e) => RiderSupportMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      satisfactionRating: (data['satisfaction_rating'] as num?)?.toInt(),
    );
  }

  static Future<RiderSupportMessage> addMessage(
    int ticketId,
    String message, {
    List<String> attachments = const [],
  }) async {
    final res = await _dio.post(
      ApiConstants.supportTicketMessages(ticketId),
      data: {
        'message': message,
        if (attachments.isNotEmpty) 'attachments': attachments,
      },
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return RiderSupportMessage.fromJson(data);
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    final res = await _dio.get(ApiConstants.supportTicketStatistics);
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<void> requestClose(int ticketId, {String? reason}) async {
    await _dio.post(
      ApiConstants.supportTicketClose(ticketId),
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  static Future<void> rateSatisfaction(
    int ticketId, {
    required int rating,
    String? comment,
  }) async {
    await _dio.post(
      ApiConstants.supportTicketSatisfaction(ticketId),
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }
}
