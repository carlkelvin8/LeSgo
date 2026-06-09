import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/booking_geo_utils.dart';
import '../../../../../data/data_source/dto/voucher/validate_voucher_request_dto.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../data/data_source/voucher_remote_datasource.dart';
import '../../address/address_provider.dart';

class LesbuyCheckoutState {
  final double deliveryFee;
  final double discount;
  final String? voucherCode;
  final String? voucherError;
  final bool isLoadingFare;
  final bool isValidatingVoucher;
  final double pickupLat;
  final double pickupLng;
  final int? partnerId;
  final int estimatedDistanceM;
  final bool deliveryFeeUncertain;

  const LesbuyCheckoutState({
    this.deliveryFee = 50,
    this.discount = 0,
    this.voucherCode,
    this.voucherError,
    this.isLoadingFare = false,
    this.isValidatingVoucher = false,
    this.pickupLat = BookingGeoUtils.defaultLat,
    this.pickupLng = BookingGeoUtils.defaultLng,
    this.partnerId,
    this.estimatedDistanceM = 5000,
    this.deliveryFeeUncertain = false,
  });

  LesbuyCheckoutState copyWith({
    double? deliveryFee,
    double? discount,
    String? voucherCode,
    String? voucherError,
    bool? isLoadingFare,
    bool? isValidatingVoucher,
    double? pickupLat,
    double? pickupLng,
    int? partnerId,
    int? estimatedDistanceM,
    bool? deliveryFeeUncertain,
    bool clearVoucher = false,
    bool clearVoucherError = false,
  }) {
    return LesbuyCheckoutState(
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      voucherCode: clearVoucher ? null : (voucherCode ?? this.voucherCode),
      voucherError:
          clearVoucherError ? null : (voucherError ?? this.voucherError),
      isLoadingFare: isLoadingFare ?? this.isLoadingFare,
      isValidatingVoucher: isValidatingVoucher ?? this.isValidatingVoucher,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      partnerId: partnerId ?? this.partnerId,
      estimatedDistanceM: estimatedDistanceM ?? this.estimatedDistanceM,
      deliveryFeeUncertain:
          deliveryFeeUncertain ?? this.deliveryFeeUncertain,
    );
  }
}

class LesbuyCheckoutNotifier extends StateNotifier<LesbuyCheckoutState> {
  LesbuyCheckoutNotifier(this._ref) : super(const LesbuyCheckoutState());

  final Ref _ref;
  final OrderRemoteDataSource _orders = getIt<OrderRemoteDataSource>();
  final VoucherRemoteDataSource _vouchers = getIt<VoucherRemoteDataSource>();
  final PartnerRemoteDataSource _partners = getIt<PartnerRemoteDataSource>();

  Future<void> initialize({required String? storePartnerId}) async {
    final id = int.tryParse(storePartnerId ?? '');
    state = state.copyWith(partnerId: id, clearVoucherError: true);
    if (id != null) {
      await _loadPartnerPickup(id);
    }
    await refreshDeliveryFee(
      dropoffLat: null,
      dropoffLng: null,
    );
  }

  Future<void> _loadPartnerPickup(int partnerId) async {
    try {
      await _partners.getPartner(partnerId);
      // Partner profile has no coords in DTO; keep default pickup hub near CDO.
    } catch (_) {}
  }

  void setManualDeliveryFeeUncertain(bool uncertain) {
    if (uncertain) {
      state = state.copyWith(
        deliveryFeeUncertain: true,
        deliveryFee: 0,
        estimatedDistanceM: 0,
        isLoadingFare: false,
      );
      return;
    }
    state = state.copyWith(deliveryFeeUncertain: false);
  }

  Future<void> refreshDeliveryFee({
    double? dropoffLat,
    double? dropoffLng,
    bool hasManualItems = false,
    bool hasStoreItems = true,
  }) async {
    if (hasManualItems && !hasStoreItems) {
      setManualDeliveryFeeUncertain(true);
      return;
    }
    double lat = dropoffLat ?? BookingGeoUtils.defaultLat;
    double lng = dropoffLng ?? BookingGeoUtils.defaultLng;

    if (dropoffLat == null || dropoffLng == null) {
      final addressState = _ref.read(addressProvider);
      final deliveryAddr = addressState.deliveryAddress;
      if (deliveryAddr != null) {
        lat = deliveryAddr.latitude;
        lng = deliveryAddr.longitude;
      }
    }

    final distanceM = BookingGeoUtils.distanceMeters(
      lat1: state.pickupLat,
      lng1: state.pickupLng,
      lat2: lat,
      lng2: lng,
    );

    state = state.copyWith(isLoadingFare: true, estimatedDistanceM: distanceM);

    try {
      final fee = await _orders.getFareEstimateRaw(
        serviceId: 4,
        estimatedDistanceM: distanceM,
        pickupLat: state.pickupLat,
        pickupLng: state.pickupLng,
        dropoffLat: lat,
        dropoffLng: lng,
      );
      state = state.copyWith(
        deliveryFee: fee ?? 50,
        isLoadingFare: false,
        deliveryFeeUncertain: false,
      );
    } catch (_) {
      state = state.copyWith(
        deliveryFee: 50,
        isLoadingFare: false,
        deliveryFeeUncertain: false,
      );
    }
  }

  Future<String?> applyVoucher(String code, double orderSubtotal) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return 'Enter a voucher code';

    state = state.copyWith(
      isValidatingVoucher: true,
      clearVoucherError: true,
    );

    try {
      final response = await _vouchers.validateVoucher(
        ValidateVoucherRequestDto(
          voucherCode: trimmed,
          orderValue: orderSubtotal + state.deliveryFee,
        ),
      );

      final data = response.data;
      if (!data.valid) {
        final msg = data.error ?? response.message;
        state = state.copyWith(
          isValidatingVoucher: false,
          voucherError: msg,
          clearVoucher: true,
          discount: 0,
        );
        return msg;
      }

      final discount = data.discountAmount ?? 0;
      state = state.copyWith(
        isValidatingVoucher: false,
        voucherCode: trimmed.toUpperCase(),
        discount: discount,
        clearVoucherError: true,
      );
      return null;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isValidatingVoucher: false,
        voucherError: msg,
      );
      return msg;
    }
  }

  void removeVoucher() {
    state = state.copyWith(
      clearVoucher: true,
      discount: 0,
      clearVoucherError: true,
    );
  }
}

final lesbuyCheckoutProvider =
    StateNotifierProvider<LesbuyCheckoutNotifier, LesbuyCheckoutState>((ref) {
  return LesbuyCheckoutNotifier(ref);
});
