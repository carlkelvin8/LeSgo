// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoucherDto _$VoucherDtoFromJson(Map<String, dynamic> json) => VoucherDto(
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  discountText: json['discount_text'] as String,
  minOrder: (json['min_order'] as num).toDouble(),
  expiresAt: json['expires_at'] as String,
  eligible: json['eligible'] as bool,
);

Map<String, dynamic> _$VoucherDtoToJson(VoucherDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'discount_text': instance.discountText,
      'min_order': instance.minOrder,
      'expires_at': instance.expiresAt,
      'eligible': instance.eligible,
    };

VoucherDetailsDto _$VoucherDetailsDtoFromJson(Map<String, dynamic> json) =>
    VoucherDetailsDto(
      code: json['code'] as String,
      title: json['title'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderValue: (json['min_order_value'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num).toDouble(),
      expiresAt: json['expires_at'] as String,
    );

Map<String, dynamic> _$VoucherDetailsDtoToJson(VoucherDetailsDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'discount_value': instance.discountValue,
      'min_order_value': instance.minOrderValue,
      'max_discount': instance.maxDiscount,
      'expires_at': instance.expiresAt,
    };
