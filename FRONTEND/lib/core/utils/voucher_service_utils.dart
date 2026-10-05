import '../../data/data_source/dto/voucher/voucher_dto.dart';

/// Backend service IDs used when validating or filtering vouchers.
class BookingServiceIds {
  static const int lesgo = 1;
  static const int lesride = 2;
  static const int leseat = 3;
  static const int lesbuy = 4;
}

bool isLesgoVoucher(VoucherDto voucher) =>
    isVoucherForService(voucher, BookingServiceIds.lesgo);

bool isVoucherForService(VoucherDto voucher, int serviceId) {
  final fromApi = voucher.serviceId;
  if (fromApi != null) return fromApi == serviceId;

  final upper = voucher.code.toUpperCase();
  final title = voucher.title.toUpperCase();
  final description = (voucher.description ?? '').toUpperCase();
  final combined = '$upper $title $description';

  switch (serviceId) {
    case BookingServiceIds.lesgo:
      if (_matchesOtherService(combined)) return false;
      return combined.contains('LESGO') ||
          combined.contains('SEND') ||
          RegExp(r'\bGO\b').hasMatch(combined) ||
          combined.contains('DELIVERY');
    case BookingServiceIds.lesride:
      return combined.contains('RIDE');
    case BookingServiceIds.leseat:
      return combined.contains('LUNCH') ||
          combined.contains('EAT') ||
          combined.contains('FOOD');
    case BookingServiceIds.lesbuy:
      return combined.contains('BUY');
    default:
      return true;
  }
}

bool _matchesOtherService(String combined) {
  return combined.contains('RIDE') ||
      combined.contains('LUNCH') ||
      combined.contains('FOOD') ||
      combined.contains('EAT') ||
      combined.contains('BUY') ||
      combined.contains('WALLET') ||
      combined.contains('LESPAY');
}

List<VoucherDto> filterVouchersForService(
  List<VoucherDto> vouchers,
  int serviceId,
) {
  return vouchers
      .where((voucher) => isVoucherForService(voucher, serviceId))
      .toList(growable: false);
}
