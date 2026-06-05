// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletDto _$WalletDtoFromJson(Map<String, dynamic> json) => WalletDto(
  id: _parseInt(json['id']),
  userId: _parseInt(json['user_id']),
  balance: _parseDouble(json['balance']),
  currency: json['currency'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$WalletDtoToJson(WalletDto instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'balance': instance.balance,
  'currency': instance.currency,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

WalletResponseDto _$WalletResponseDtoFromJson(Map<String, dynamic> json) =>
    WalletResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : WalletDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$WalletResponseDtoToJson(WalletResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };

WalletTransactionDto _$WalletTransactionDtoFromJson(
  Map<String, dynamic> json,
) => WalletTransactionDto(
  id: _parseInt(json['id']),
  walletId: _parseInt(json['wallet_id']),
  type: json['type'] as String,
  amount: _parseDouble(json['amount']),
  description: json['description'] as String?,
  reference: json['reference'] as String?,
  status: json['status'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$WalletTransactionDtoToJson(
  WalletTransactionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'wallet_id': instance.walletId,
  'type': instance.type,
  'amount': instance.amount,
  'description': instance.description,
  'reference': instance.reference,
  'status': instance.status,
  'created_at': instance.createdAt,
};

WalletTransactionsResponseDto _$WalletTransactionsResponseDtoFromJson(
  Map<String, dynamic> json,
) => WalletTransactionsResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => WalletTransactionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$WalletTransactionsResponseDtoToJson(
  WalletTransactionsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
