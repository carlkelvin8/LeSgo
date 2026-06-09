import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/booking_checkout_payment.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/active_order_limit_guard.dart';
import '../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../domain/entities/booking/lestransport/lestransport_booking.dart';

class LestransportState {
  final String senderName;
  final String senderContactNumber;
  final String senderAddress;
  final DeliveryMethod deliveryMethod;
  final String branchAddress;
  final String paymentMethod;
  final double shippingFee;
  final double standardDeliveryFee;
  final bool isLoading;
  final String? error;
  final int? createdOrderId;

  LestransportState({
    this.senderName = '',
    this.senderContactNumber = '',
    this.senderAddress = '',
    this.deliveryMethod = DeliveryMethod.pickupDoorToDoor,
    this.branchAddress = '',
    this.paymentMethod = 'cash',
    this.shippingFee = 10.00,
    this.standardDeliveryFee = 20.00,
    this.isLoading = false,
    this.error,
    this.createdOrderId,
  });

  double get totalOrder => shippingFee + standardDeliveryFee;

  LestransportState copyWith({
    String? senderName,
    String? senderContactNumber,
    String? senderAddress,
    DeliveryMethod? deliveryMethod,
    String? branchAddress,
    String? paymentMethod,
    double? shippingFee,
    double? standardDeliveryFee,
    bool? isLoading,
    String? error,
    int? createdOrderId,
    bool clearError = false,
    bool clearOrderId = false,
  }) {
    return LestransportState(
      senderName: senderName ?? this.senderName,
      senderContactNumber: senderContactNumber ?? this.senderContactNumber,
      senderAddress: senderAddress ?? this.senderAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      branchAddress: branchAddress ?? this.branchAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingFee: shippingFee ?? this.shippingFee,
      standardDeliveryFee: standardDeliveryFee ?? this.standardDeliveryFee,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      createdOrderId:
          clearOrderId ? null : (createdOrderId ?? this.createdOrderId),
    );
  }

  bool get isValid {
    if (senderName.isEmpty ||
        senderContactNumber.isEmpty ||
        senderAddress.isEmpty) {
      return false;
    }
    if (deliveryMethod == DeliveryMethod.padalaToBranch &&
        branchAddress.isEmpty) {
      return false;
    }
    return true;
  }
}

class LestransportNotifier extends StateNotifier<LestransportState> {
  LestransportNotifier(this._ref) : super(LestransportState());

  final Ref _ref;

  void updateSenderName(String name) {
    state = state.copyWith(senderName: name);
  }

  void updateContactNumber(String number) {
    state = state.copyWith(senderContactNumber: number);
  }

  void updateAddress(String address) {
    state = state.copyWith(senderAddress: address);
  }

  void updateDeliveryMethod(DeliveryMethod method) {
    state = state.copyWith(deliveryMethod: method);
  }

  void updateBranchAddress(String address) {
    state = state.copyWith(branchAddress: address);
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  Future<({double lat, double lng})> _geocode(String address) async {
    try {
      final results = await locationFromAddress(address);
      if (results.isNotEmpty) {
        return (lat: results.first.latitude, lng: results.first.longitude);
      }
    } catch (_) {}
    return (lat: BookingGeoUtils.defaultLat, lng: BookingGeoUtils.defaultLng);
  }

  Future<bool> bookTransport(BuildContext context) async {
    if (!await NetworkGuard.ensureOnline(context)) return false;
    if (!await ActiveOrderLimitGuard.ensureCanBook(context)) return false;

    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearOrderId: true);

    try {
      final amount = state.totalOrder;
      final walletOk = await validateWalletBalanceForOrder(
        _ref,
        amount: amount,
        paymentMethod: state.paymentMethod,
        context: context,
      );
      if (!walletOk) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final pickupCoords = await _geocode(state.senderAddress);
      final dropoffAddress = state.deliveryMethod ==
              DeliveryMethod.padalaToBranch
          ? state.branchAddress
          : state.senderAddress;
      final dropoffCoords = state.deliveryMethod ==
              DeliveryMethod.padalaToBranch
          ? await _geocode(state.branchAddress)
          : pickupCoords;

      final request = CreateOrderRequestDto(
        serviceId: 5,
        estimatedDistanceM: 5000,
        pickup: OrderAddressDto(
          address: state.senderAddress,
          lat: pickupCoords.lat,
          lng: pickupCoords.lng,
          contactName: state.senderName,
          contactPhone: state.senderContactNumber,
        ),
        dropoff: OrderAddressDto(
          address: dropoffAddress,
          lat: dropoffCoords.lat,
          lng: dropoffCoords.lng,
          contactName: state.senderName,
          contactPhone: state.senderContactNumber,
        ),
        notes: 'LesTransport — ${state.deliveryMethod.displayName}',
        paymentMethod: state.paymentMethod,
        meta: {
          'order_type': 'lestransport',
          'delivery_method': state.deliveryMethod.name,
          'branch_address': state.branchAddress,
          'shipping_fee': state.shippingFee,
          'standard_delivery_fee': state.standardDeliveryFee,
          'total': amount,
          'sender_name': state.senderName,
        },
      );

      final response =
          await getIt<OrderRemoteDataSource>().createOrder(request);
      final order = response.data;
      final orderId = order.id;
      final payAmount = order.effectiveTotalAmount > 0
          ? order.effectiveTotalAmount
          : amount;

      if (!context.mounted) return false;

      final paid = await completeBookingPayment(
        context: context,
        ref: _ref,
        orderId: orderId,
        amount: payAmount,
        paymentMethod: state.paymentMethod,
        serviceLabel: 'LesTransport',
      );

      if (!paid) {
        state = state.copyWith(
          isLoading: false,
          error: 'Payment was not completed.',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, createdOrderId: orderId);

      if (context.mounted) {
        AppRouter.pushReplacement(
          context,
          BookingRoutes.driverFinding,
          arguments: {
            'orderId': orderId.toString(),
            'orderType': 'LesTransport',
            'orderData': {
              'pickup_address': state.senderAddress,
              'dropoff_address': dropoffAddress,
              'paymentMethod': state.paymentMethod,
              'total': payAmount,
              'estimated_fare': payAmount,
            },
          },
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: bookingPaymentErrorMessage(e),
      );
      if (context.mounted) {
        SnackBarUtils.showErrorFrom(
          context,
          e,
          fallbackEn: 'Could not book LesTransport.',
          fallbackTl: 'Hindi makapag-book ng LesTransport.',
        );
      }
      return false;
    }
  }

  void reset() {
    state = LestransportState();
  }
}

final lestransportProvider =
    StateNotifierProvider<LestransportNotifier, LestransportState>((ref) {
  return LestransportNotifier(ref);
});
