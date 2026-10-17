/// DTO for merchant withdrawal request
///
/// Parsing is done manually (instead of json_serializable) because the API
/// serialises `decimal` columns as strings, e.g. `"amount": "150.00"`. The
/// generated `as num` casts throw at runtime, so every numeric field is parsed
/// through [asDouble] / [asInt] which accept both numbers and strings.
class WithdrawalRequestDto {
  final int id;
  final int userId;
  final int walletId;
  final int? partnerId;
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;
  final String status;
  final String payoutMethod;
  final String payoutAccountNumber;
  final String payoutAccountName;
  final String? payoutBankName;
  final String? referenceNumber;
  final String? adminNotes;
  final int? approvedBy;
  final String? approvedAt;
  final int? processedBy;
  final String? processedAt;
  final String? rejectionReason;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  WithdrawalRequestDto({
    required this.id,
    required this.userId,
    required this.walletId,
    this.partnerId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.currency,
    required this.status,
    required this.payoutMethod,
    required this.payoutAccountNumber,
    required this.payoutAccountName,
    this.payoutBankName,
    this.referenceNumber,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalRequestDto.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestDto(
      id: asInt(json['id']) ?? 0,
      userId: asInt(json['user_id']) ?? 0,
      walletId: asInt(json['wallet_id']) ?? 0,
      partnerId: asInt(json['partner_id']),
      amount: asDouble(json['amount']),
      fee: asDouble(json['fee']),
      netAmount: asDouble(json['net_amount']),
      currency: asString(json['currency'], fallback: 'PHP'),
      status: asString(json['status'], fallback: 'pending'),
      payoutMethod: asString(json['payout_method']),
      payoutAccountNumber: asString(json['payout_account_number']),
      payoutAccountName: asString(json['payout_account_name']),
      payoutBankName: json['payout_bank_name'] as String?,
      referenceNumber: json['reference_number'] as String?,
      adminNotes: json['admin_notes'] as String?,
      approvedBy: asInt(json['approved_by']),
      approvedAt: json['approved_at'] as String?,
      processedBy: asInt(json['processed_by']),
      processedAt: json['processed_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      completedAt: json['completed_at'] as String?,
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'wallet_id': walletId,
        'partner_id': partnerId,
        'amount': amount,
        'fee': fee,
        'net_amount': netAmount,
        'currency': currency,
        'status': status,
        'payout_method': payoutMethod,
        'payout_account_number': payoutAccountNumber,
        'payout_account_name': payoutAccountName,
        'payout_bank_name': payoutBankName,
        'reference_number': referenceNumber,
        'admin_notes': adminNotes,
        'approved_by': approvedBy,
        'approved_at': approvedAt,
        'processed_by': processedBy,
        'processed_at': processedAt,
        'rejection_reason': rejectionReason,
        'completed_at': completedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';
  bool get canBeCancelled => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String get payoutMethodLabel {
    switch (payoutMethod) {
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return payoutMethod;
    }
  }
}

/// DTO for creating a withdrawal request
class CreateWithdrawalRequestDto {
  final double amount;
  final String payoutMethod;
  final String payoutAccountNumber;
  final String payoutAccountName;
  final String? payoutBankName;

  CreateWithdrawalRequestDto({
    required this.amount,
    required this.payoutMethod,
    required this.payoutAccountNumber,
    required this.payoutAccountName,
    this.payoutBankName,
  });

  factory CreateWithdrawalRequestDto.fromJson(Map<String, dynamic> json) {
    return CreateWithdrawalRequestDto(
      amount: asDouble(json['amount']),
      payoutMethod: asString(json['payout_method']),
      payoutAccountNumber: asString(json['payout_account_number']),
      payoutAccountName: asString(json['payout_account_name']),
      payoutBankName: json['payout_bank_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'payout_method': payoutMethod,
        'payout_account_number': payoutAccountNumber,
        'payout_account_name': payoutAccountName,
        if (payoutBankName != null) 'payout_bank_name': payoutBankName,
      };
}

/// DTO for withdrawal summary
class WithdrawalSummaryDto {
  final double totalBalance;
  final double availableBalance;
  final double pendingWithdrawals;
  final double totalWithdrawn;
  final int pendingCount;
  final String currency;
  final double minWithdrawalAmount;
  final double maxWithdrawalAmount;

  WithdrawalSummaryDto({
    required this.totalBalance,
    required this.availableBalance,
    required this.pendingWithdrawals,
    required this.totalWithdrawn,
    required this.pendingCount,
    required this.currency,
    required this.minWithdrawalAmount,
    required this.maxWithdrawalAmount,
  });

  factory WithdrawalSummaryDto.fromJson(Map<String, dynamic> json) {
    return WithdrawalSummaryDto(
      totalBalance: asDouble(json['total_balance']),
      availableBalance: asDouble(json['available_balance']),
      pendingWithdrawals: asDouble(json['pending_withdrawals']),
      totalWithdrawn: asDouble(json['total_withdrawn']),
      pendingCount: asInt(json['pending_count']) ?? 0,
      currency: asString(json['currency'], fallback: 'PHP'),
      minWithdrawalAmount: asDouble(json['min_withdrawal_amount']),
      maxWithdrawalAmount: asDouble(json['max_withdrawal_amount']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'total_balance': totalBalance,
        'available_balance': availableBalance,
        'pending_withdrawals': pendingWithdrawals,
        'total_withdrawn': totalWithdrawn,
        'pending_count': pendingCount,
        'currency': currency,
        'min_withdrawal_amount': minWithdrawalAmount,
        'max_withdrawal_amount': maxWithdrawalAmount,
      };
}

/// Response wrapper for withdrawal list
class WithdrawalListResponseDto {
  final bool success;
  final WithdrawalPaginationDto data;

  WithdrawalListResponseDto({
    required this.success,
    required this.data,
  });

  factory WithdrawalListResponseDto.fromJson(Map<String, dynamic> json) {
    return WithdrawalListResponseDto(
      success: json['success'] as bool? ?? false,
      data: WithdrawalPaginationDto.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
        'data': data.toJson(),
      };
}

/// Pagination data for withdrawal list
class WithdrawalPaginationDto {
  final int currentPage;
  final List<WithdrawalRequestDto> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  WithdrawalPaginationDto({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory WithdrawalPaginationDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return WithdrawalPaginationDto(
      currentPage: asInt(json['current_page']) ?? 1,
      data: rawData is List
          ? rawData
              .whereType<Map<String, dynamic>>()
              .map(WithdrawalRequestDto.fromJson)
              .toList()
          : const [],
      firstPageUrl: json['first_page_url'] as String?,
      from: asInt(json['from']),
      lastPage: asInt(json['last_page']) ?? 1,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      path: asString(json['path']),
      perPage: asInt(json['per_page']) ?? 20,
      prevPageUrl: json['prev_page_url'] as String?,
      to: asInt(json['to']),
      total: asInt(json['total']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'current_page': currentPage,
        'data': data.map((e) => e.toJson()).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };
}

/// Single withdrawal response
class WithdrawalResponseDto {
  final bool success;
  final String? message;
  final WithdrawalRequestDto? data;
  final double? availableBalance;
  final double? pendingWithdrawals;

  WithdrawalResponseDto({
    required this.success,
    this.message,
    this.data,
    this.availableBalance,
    this.pendingWithdrawals,
  });

  factory WithdrawalResponseDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return WithdrawalResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: rawData is Map<String, dynamic>
          ? WithdrawalRequestDto.fromJson(rawData)
          : null,
      availableBalance: json['available_balance'] == null
          ? null
          : asDouble(json['available_balance']),
      pendingWithdrawals: json['pending_withdrawals'] == null
          ? null
          : asDouble(json['pending_withdrawals']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
        'message': message,
        'data': data?.toJson(),
        'available_balance': availableBalance,
        'pending_withdrawals': pendingWithdrawals,
      };
}

/// Summary response
class WithdrawalSummaryResponseDto {
  final bool success;
  final WithdrawalSummaryDto data;

  WithdrawalSummaryResponseDto({
    required this.success,
    required this.data,
  });

  factory WithdrawalSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return WithdrawalSummaryResponseDto(
      success: json['success'] as bool? ?? false,
      data: WithdrawalSummaryDto.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
        'data': data.toJson(),
      };
}

/// Parse a numeric value that the API may serialise as a JSON number or a
/// decimal string (e.g. `"150.00"`).
double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Parse an integer value that may arrive as a number or string.
int? asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Parse a string, tolerating non-string scalars.
String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}
