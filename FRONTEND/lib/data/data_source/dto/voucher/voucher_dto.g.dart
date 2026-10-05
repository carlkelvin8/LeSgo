// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoucherDto _$VoucherDtoFromJson(Map<String, dynamic> json) => VoucherDto(
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  discountText: json['discount_text'] as String?,
  minOrder: _parseMoney(json['min_order']),
  expiresAt: json['expires_at'] as String?,
  serviceId: _parseIntNullable(json['service_id']),
  eligible: _parseBool(json['eligible']),
  claimed: json['claimed'] == null ? false : _parseBool(json['claimed']),
);

Map<String, dynamic> _$VoucherDtoToJson(VoucherDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'discount_text': instance.discountText,
      'min_order': instance.minOrder,
      'expires_at': instance.expiresAt,
      'service_id': instance.serviceId,
      'eligible': instance.eligible,
      'claimed': instance.claimed,
    };
