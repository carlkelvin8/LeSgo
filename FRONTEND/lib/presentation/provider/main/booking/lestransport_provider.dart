import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/lestransport/lestransport_booking.dart';

class LestransportState {
  final String senderName;
  final String senderContactNumber;
  final String senderAddress;
  final DeliveryMethod deliveryMethod;
  final String branchAddress;
  final double shippingFee;
  final double standardDeliveryFee;
  final bool isLoading;
  final String? error;

  LestransportState({
    this.senderName = '',
    this.senderContactNumber = '',
    this.senderAddress = '',
    this.deliveryMethod = DeliveryMethod.pickupDoorToDoor,
    this.branchAddress = '',
    this.shippingFee = 10.00,
    this.standardDeliveryFee = 20.00,
    this.isLoading = false,
    this.error,
  });

  double get totalOrder => shippingFee + standardDeliveryFee;

  LestransportState copyWith({
    String? senderName,
    String? senderContactNumber,
    String? senderAddress,
    DeliveryMethod? deliveryMethod,
    String? branchAddress,
    double? shippingFee,
    double? standardDeliveryFee,
    bool? isLoading,
    String? error,
  }) {
    return LestransportState(
      senderName: senderName ?? this.senderName,
      senderContactNumber: senderContactNumber ?? this.senderContactNumber,
      senderAddress: senderAddress ?? this.senderAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      branchAddress: branchAddress ?? this.branchAddress,
      shippingFee: shippingFee ?? this.shippingFee,
      standardDeliveryFee: standardDeliveryFee ?? this.standardDeliveryFee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
  LestransportNotifier() : super(LestransportState());

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

  Future<void> bookTransport() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Send booking to backend
      // final booking = LestransportBooking(
      //   senderName: state.senderName,
      //   senderContactNumber: state.senderContactNumber,
      //   senderAddress: state.senderAddress,
      //   deliveryMethod: state.deliveryMethod,
      //   branchAddress: state.deliveryMethod == DeliveryMethod.padalaToBranch
      //       ? state.branchAddress
      //       : null,
      //   shippingFee: state.shippingFee,
      //   standardDeliveryFee: state.standardDeliveryFee,
      // );

      state = state.copyWith(isLoading: false);

      // Success - booking created
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = LestransportState();
  }
}

final lestransportProvider =
    StateNotifierProvider<LestransportNotifier, LestransportState>((ref) {
      return LestransportNotifier();
    });
