import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lesgo_location_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../../../../data/data_source/dto/voucher/validate_voucher_request_dto.dart';
import '../../../../data/data_source/voucher_remote_datasource.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/voucher_service_utils.dart';
import '../../../../data/data_source/dto/address/address_dto.dart';
import '../profile/profile_provider.dart';
import '../../../../core/services/service_area_checker.dart';
import '../../../../core/utils/booking_geo_utils.dart';
import '../../../../core/utils/booking_checkout_payment.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/active_order_limit_guard.dart';

class LesgoState {
  final bool isFullscreen;
  final String paymentMethod;
  final bool selectingDestination;
  final bool pendingFit;
  final bool shouldCollapseAfterFullscreen;
  final String itemDescription;
  final String itemWeight;
  final String? voucherCode;
  final double discount;
  final bool isValidatingVoucher;
  final String? voucherError;
  final AddressDto? selectedPickupAddress;
  final AddressDto? selectedDropoffAddress;
  final bool isBooking;

  LesgoState({
    this.isFullscreen = false,
    this.paymentMethod = 'cash',
    this.selectingDestination = false,
    this.pendingFit = false,
    this.shouldCollapseAfterFullscreen = false,
    this.itemDescription = '',
    this.itemWeight = '',
    this.voucherCode,
    this.discount = 0,
    this.isValidatingVoucher = false,
    this.voucherError,
    this.selectedPickupAddress,
    this.selectedDropoffAddress,
    this.isBooking = false,
  });

  LesgoState copyWith({
    bool? isFullscreen,
    String? paymentMethod,
    bool? selectingDestination,
    bool? pendingFit,
    bool? shouldCollapseAfterFullscreen,
    String? itemDescription,
    String? itemWeight,
    String? voucherCode,
    double? discount,
    bool? isValidatingVoucher,
    String? voucherError,
    AddressDto? selectedPickupAddress,
    bool clearVoucher = false,
    bool clearVoucherError = false,
    AddressDto? selectedDropoffAddress,
    bool clearPickupAddress = false,
    bool clearDropoffAddress = false,
    bool? isBooking,
  }) {
    return LesgoState(
      isFullscreen: isFullscreen ?? this.isFullscreen,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectingDestination: selectingDestination ?? this.selectingDestination,
      pendingFit: pendingFit ?? this.pendingFit,
      shouldCollapseAfterFullscreen:
          shouldCollapseAfterFullscreen ?? this.shouldCollapseAfterFullscreen,
      itemDescription: itemDescription ?? this.itemDescription,
      itemWeight: itemWeight ?? this.itemWeight,
      voucherCode: clearVoucher ? null : (voucherCode ?? this.voucherCode),
      discount: clearVoucher ? 0 : (discount ?? this.discount),
      isValidatingVoucher: isValidatingVoucher ?? this.isValidatingVoucher,
      voucherError:
          clearVoucherError ? null : (voucherError ?? this.voucherError),
      selectedPickupAddress: clearPickupAddress
          ? null
          : (selectedPickupAddress ?? this.selectedPickupAddress),
      selectedDropoffAddress: clearDropoffAddress
          ? null
          : (selectedDropoffAddress ?? this.selectedDropoffAddress),
      isBooking: isBooking ?? this.isBooking,
    );
  }
}

class LesgoNotifier extends StateNotifier<LesgoState> {
  final Ref _ref;
  GoogleMapController? _mainMapController;
  GoogleMapController? _overlayMapController;
  final VoucherRemoteDataSource _voucherDataSource =
      getIt<VoucherRemoteDataSource>();
  final OrderRemoteDataSource _orderDataSource =
      getIt<OrderRemoteDataSource>();
  static const double _sheetMin = 0.04;
  static const double _sheetMax = 0.55;
  static const double _sheetDefault =
      0.28; // Default initial size - shows more map

  LesgoNotifier(this._ref) : super(LesgoState());

  void setMapController(GoogleMapController? controller) {
    _mainMapController = controller;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => fitBoundsOrSelected(),
      );
    }
  }

  void setOverlayMapController(GoogleMapController? controller) {
    _overlayMapController = controller;
  }

  GoogleMapController? get mapController => _mainMapController;
  GoogleMapController? get overlayMapController => _overlayMapController;

  double get sheetMin => _sheetMin;
  double get sheetMax => _sheetMax;
  double get sheetDefault => _sheetDefault;

  Future<void> initialize() async {
    final notifier = _ref.read(lesgoLocationProvider.notifier);

    notifier.reset();
    state = state.copyWith(
      isFullscreen: false,
      selectingDestination: true,
      pendingFit: true,
      shouldCollapseAfterFullscreen: false,
      clearPickupAddress: true,
      clearDropoffAddress: true,
      clearVoucher: true,
      clearVoucherError: true,
    );

    await notifier.getCurrentLocation();
  }

  void cleanup() {
    _mainMapController?.dispose();
    _mainMapController = null;
    // Note: We don't reset the location provider here to avoid lifecycle conflicts.
    // The provider state can persist, and initialize() will reset it when the screen is opened again.
  }

  Future<void> fitBoundsOrSelected() async {
    final state = _ref.read(lesgoLocationProvider);
    final controller = _mainMapController;
    if (controller == null) return;

    final points = <LatLng>[];
    final pickup = state.pickupLocation;
    final dest = state.destinationLocation;
    final selected = state.selectedLocation;
    if (pickup != null) points.add(pickup);
    if (dest != null) points.add(dest);

    if (points.length >= 2) {
      double minLat = points.first.latitude, maxLat = points.first.latitude;
      double minLng = points.first.longitude, maxLng = points.first.longitude;
      for (final p in points.skip(1)) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      if (minLat == maxLat) {
        minLat -= 0.0005;
        maxLat += 0.0005;
      }
      if (minLng == maxLng) {
        minLng -= 0.0005;
        maxLng += 0.0005;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 140),
        );
      } on StateError {
        // Controller was used after its GoogleMap was disposed; ignore safely.
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 80));
        try {
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 140),
          );
        } catch (_) {
          // If it still fails, give up silently.
        }
      }
    } else {
      final target = dest ?? pickup ?? selected;
      if (target != null) {
        try {
          await controller.animateCamera(CameraUpdate.newLatLng(target));
        } catch (_) {
          // Ignore if controller is no longer attached.
        }
      }
    }
  }

  Future<void> useCurrentLocation() async {
    await _ref.read(lesgoLocationProvider.notifier).getCurrentLocation();
    animateToSelected();
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);

    if (!state.isFullscreen) {
      state = state.copyWith(
        shouldCollapseAfterFullscreen: true,
        pendingFit: true,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => fitBoundsOrSelected(),
      );
    }
  }

  Future<void> onMapTap(LatLng latLng) async {
    print(
      '🔍 LesGo: onMapTap called with: $latLng, isFullscreen: ${state.isFullscreen}, selectingDestination: ${state.selectingDestination}',
    );

    if (!state.isFullscreen)
      return; // Block marker moves when not in fullscreen selection.

    if (state.selectingDestination) {
      print('🔍 LesGo: Updating destination to: $latLng');
      await _ref.read(lesgoLocationProvider.notifier).updateDestination(latLng);
    } else {
      print('🔍 LesGo: Updating pickup to: $latLng');
      await _ref.read(lesgoLocationProvider.notifier).updatePickup(latLng);
    }
    animateToSelected();
  }

  Future<void> animateToSelected() async {
    final selected = _ref.read(lesgoLocationProvider).selectedLocation;
    final controller = _mainMapController;
    if (controller != null && selected != null) {
      try {
        await controller.animateCamera(CameraUpdate.newLatLng(selected));
      } catch (_) {
        // Safe-guard against controller tied to a disposed map.
      }
    }
  }

  Future<void> animateOverlayToLocation(LatLng location) async {
    final controller = _overlayMapController;
    if (controller != null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16.0),
        );
      } catch (_) {
        // Safe-guard against controller tied to a disposed map.
      }
    }
  }

  Future<void> updateCamera(LesgoLocationState locationState) async {
    final controller = _mainMapController;
    if (controller == null) return;
    final pickup = locationState.pickupLocation;
    final dest = locationState.destinationLocation;
    if (pickup != null && dest != null) {
      final southwest = LatLng(
        pickup.latitude < dest.latitude ? pickup.latitude : dest.latitude,
        pickup.longitude < dest.longitude ? pickup.longitude : dest.longitude,
      );
      final northeast = LatLng(
        pickup.latitude > dest.latitude ? pickup.latitude : dest.latitude,
        pickup.longitude > dest.longitude ? pickup.longitude : dest.longitude,
      );
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: southwest, northeast: northeast),
            100,
          ),
        );
      } catch (_) {
        // Controller no longer valid; ignore.
      }
    } else if (pickup != null) {
      try {
        await controller.animateCamera(CameraUpdate.newLatLng(pickup));
      } catch (_) {}
    } else if (dest != null) {
      try {
        await controller.animateCamera(CameraUpdate.newLatLng(dest));
      } catch (_) {}
    } else if (locationState.selectedLocation != null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLng(locationState.selectedLocation!),
        );
      } catch (_) {}
    }
  }

  void openMapSelection() {
    state = state.copyWith(isFullscreen: true);
  }

  void openDestinationSelection() {
    state = state.copyWith(selectingDestination: true);
    final dest = _ref.read(lesgoLocationProvider).destinationLocation;
    if (dest != null) {
      _ref.read(lesgoLocationProvider.notifier).setSelectedLocation(dest);
      focusOn(dest);
    }
    openMapSelection();
  }

  void openPickupSelection() {
    state = state.copyWith(selectingDestination: false);
    final pickup = _ref.read(lesgoLocationProvider).pickupLocation;
    if (pickup != null) {
      _ref.read(lesgoLocationProvider.notifier).setSelectedLocation(pickup);
      focusOn(pickup);
    }
    openMapSelection();
  }

  Future<void> confirmSelection() async {
    print('🔍 LesGo: confirmSelection called');
    final locationNotifier = _ref.read(lesgoLocationProvider.notifier);
    var locationState = _ref.read(lesgoLocationProvider);

    // Sync map pin → pickup/destination + reverse geocode address text
    final pin = locationState.selectedLocation;
    if (pin != null) {
      if (state.selectingDestination) {
        await locationNotifier.updateDestination(pin);
      } else {
        await locationNotifier.updatePickup(pin);
      }
      locationState = _ref.read(lesgoLocationProvider);
    }

    // Selection already stored in provider on tap; just close overlay
    state = state.copyWith(
      isFullscreen: false,
      shouldCollapseAfterFullscreen: false,
      pendingFit: true,
    );

    // Ensure route is fetched if both locations are set
    // IMPORTANT: Pass forceAllow: true to allow route fetching from confirmation
    if (locationState.pickupLocation != null &&
        locationState.destinationLocation != null) {
      print(
        '🔍 LesGo: Both locations set, fetching route with forceAllow: true',
      );
      await _ref
          .read(lesgoLocationProvider.notifier)
          .fetchRouteIfBothSet(forceAllow: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => fitBoundsOrSelected());
    print('🔍 LesGo: confirmSelection completed');
  }

  Future<void> focusOn(LatLng? target) async {
    if (target == null) return;
    final controller = _mainMapController;
    await Future.wait([
      if (controller != null)
        controller.animateCamera(CameraUpdate.newLatLng(target)),
    ]);
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  Future<double?> _estimateOrderValue() async {
    final locationState = _ref.read(lesgoLocationProvider);
    final pickup = locationState.pickupLocation;
    final dropoff = locationState.destinationLocation;
    if (pickup == null || dropoff == null) return null;

    final distanceM = locationState.distanceInKm != null
        ? (locationState.distanceInKm! * 1000).round()
        : 5000;

    return _orderDataSource.getFareEstimateRaw(
      serviceId: BookingServiceIds.lesgo,
      estimatedDistanceM: distanceM,
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropoffLat: dropoff.latitude,
      dropoffLng: dropoff.longitude,
    );
  }

  Future<String?> applyVoucher(String voucherCode) async {
    final trimmed = voucherCode.trim();
    if (trimmed.isEmpty) return 'Enter a voucher code';

    final orderValue = await _estimateOrderValue();
    if (orderValue == null) {
      return 'Select pickup and drop-off locations first';
    }

    state = state.copyWith(isValidatingVoucher: true, clearVoucherError: true);

    try {
      final response = await _voucherDataSource.validateVoucher(
        ValidateVoucherRequestDto(
          voucherCode: trimmed,
          orderValue: orderValue,
          serviceId: BookingServiceIds.lesgo,
        ),
      );

      final data = response.data;
      if (!data.valid) {
        final msg = data.error ?? response.message;
        state = state.copyWith(
          isValidatingVoucher: false,
          voucherError: msg,
        );
        return msg;
      }

      state = state.copyWith(
        isValidatingVoucher: false,
        voucherCode: trimmed.toUpperCase(),
        discount: data.discountAmount ?? 0,
        clearVoucherError: true,
      );
      return null;
    } catch (e) {
      final msg = ApiErrorMapper.message(
        e,
        fallbackEn: 'Could not apply voucher. Please try again.',
        fallbackTl: 'Hindi ma-apply ang voucher. Subukan muli.',
      );
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
      clearVoucherError: true,
    );
  }

  bool get canApplyVoucher {
    final locationState = _ref.read(lesgoLocationProvider);
    return locationState.pickupLocation != null &&
        locationState.destinationLocation != null;
  }

  void selectPickupAddress(AddressDto address) {
    print(
      '🔍 LesGo: selectPickupAddress called with: ${address.addressLine1} (${address.latitude}, ${address.longitude})',
    );
    state = state.copyWith(selectedPickupAddress: address);
    final coords = BookingGeoUtils.resolveCoords(
      lat: address.latitude,
      lng: address.longitude,
    );
    final locationNotifier = _ref.read(lesgoLocationProvider.notifier);
    locationNotifier.updatePickupWithAddress(
      coords,
      address.addressLine1,
      null,
    );
    print(
      '🔍 LesGo: After updatePickupWithAddress, pickupLocation: ${_ref.read(lesgoLocationProvider).pickupLocation}',
    );
  }

  void selectDropoffAddress(AddressDto address) {
    print(
      '🔍 LesGo: selectDropoffAddress called with: ${address.addressLine1} (${address.latitude}, ${address.longitude})',
    );
    state = state.copyWith(selectedDropoffAddress: address);
    final coords = BookingGeoUtils.resolveCoords(
      lat: address.latitude,
      lng: address.longitude,
    );
    final locationNotifier = _ref.read(lesgoLocationProvider.notifier);
    locationNotifier.updateDestinationWithAddress(
      coords,
      address.addressLine1,
      null,
    );
    print(
      '🔍 LesGo: After updateDestinationWithAddress, destinationLocation: ${_ref.read(lesgoLocationProvider).destinationLocation}',
    );
  }

  void clearPickupAddress() {
    state = state.copyWith(clearPickupAddress: true);
  }

  void clearDropoffAddress() {
    state = state.copyWith(clearDropoffAddress: true);
  }

  void setPendingFit(bool value) {
    state = state.copyWith(pendingFit: value);
  }

  void setShouldCollapseAfterFullscreen(bool value) {
    state = state.copyWith(shouldCollapseAfterFullscreen: value);
  }

  // Handle route auto-fetching when locations change
  void handleLocationChange(
    LesgoLocationState? previous,
    LesgoLocationState next,
  ) {
    updateCamera(next);

    // DON'T auto-fetch route on location change
    // Route will be fetched only when user confirms location via confirmSelection()
  }

  // Handle post-frame callbacks for pending operations
  void handlePostFrameCallbacks() {
    if (state.pendingFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setPendingFit(false);
        fitBoundsOrSelected();
      });
    }
  }

  // Helper method to sync locations from selected addresses
  Future<void> _syncLocationsFromAddresses() async {
    final locationState = _ref.read(lesgoLocationProvider);
    
    // Sync dropoff location from selected address if needed
    if (locationState.destinationLocation == null && state.selectedDropoffAddress != null) {
      final address = state.selectedDropoffAddress!;
      await _ref.read(lesgoLocationProvider.notifier).updateDestinationWithAddress(
        LatLng(address.latitude, address.longitude),
        address.addressLine1,
        null,
      );
    }

    // Sync pickup location from selected address if needed
    if (locationState.pickupLocation == null && state.selectedPickupAddress != null) {
      final address = state.selectedPickupAddress!;
      await _ref.read(lesgoLocationProvider.notifier).updatePickupWithAddress(
        LatLng(address.latitude, address.longitude),
        address.addressLine1,
        null,
      );
    }
  }

  // Handle booking action with validation and API integration
  Future<void> handleBook(BuildContext context) async {
    // Double-tap guard
    if (state.isBooking) return;
    
    if (!await NetworkGuard.ensureOnline(context)) return;
    if (!await ActiveOrderLimitGuard.ensureCanBook(context)) return;

    state = state.copyWith(isBooking: true);

    print('🚀 LesGo: handleBook called!');
    final locationState = _ref.read(lesgoLocationProvider);

    // Debug logging to understand the current state
    print('🔍 LesGo Booking Debug:');
    print('  - destinationLocation: ${locationState.destinationLocation}');
    print('  - destinationAddress: ${locationState.destinationAddress}');
    print('  - pickupLocation: ${locationState.pickupLocation}');
    print('  - pickupAddress: ${locationState.pickupAddress}');
    print('  - selectedDropoffAddress: ${state.selectedDropoffAddress}');
    print('  - selectedPickupAddress: ${state.selectedPickupAddress}');

    // Strict validation - destination is required
    if (locationState.destinationLocation == null) {
      SnackBarUtils.showWarning(
        context,
        'Please select a destination before booking',
      );
      
      // Automatically open destination selection to help user
      Future.delayed(const Duration(milliseconds: 500), () {
        openDestinationSelection();
      });
      return;
    }

    // Sync locations from selected addresses if needed
    await _syncLocationsFromAddresses();

    // Re-read state after potential sync
    final updatedLocationState = _ref.read(lesgoLocationProvider);

    // Final validation - ensure both pickup and destination are set
    if (updatedLocationState.pickupLocation == null) {
      SnackBarUtils.showWarning(
        context,
        'Please select a pickup location before booking',
      );
      return;
    }

    if (updatedLocationState.destinationLocation == null) {
      SnackBarUtils.showWarning(
        context,
        'Please select a destination before booking',
      );
      return;
    }

    final pickup = updatedLocationState.pickupLocation!;
    final dropoff = updatedLocationState.destinationLocation!;

    final serviceArea = await ServiceAreaChecker.checkBookingPoints(
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropoffLat: dropoff.latitude,
      dropoffLng: dropoff.longitude,
    );
    if (!serviceArea.isAvailable) {
      SnackBarUtils.showWarning(
        context,
        '${serviceArea.messageEn}\n${serviceArea.messageTl}',
      );
      return;
    }

    // Create real order via API
    if (context.mounted) {
      try {
        final orderDataSource = getIt<OrderRemoteDataSource>();
        final profileState = _ref.read(profileProvider);
        final user = profileState.user;

        final estimatedDistanceM = (updatedLocationState.distanceInKm != null)
            ? (updatedLocationState.distanceInKm! * 1000).round()
            : 5000;

        final createOrderRequest = CreateOrderRequestDto(
          serviceId: BookingServiceIds.lesgo,
          estimatedDistanceM: estimatedDistanceM,
          pickup: OrderAddressDto(
            address: updatedLocationState.pickupAddress?.toString() ??
                state.selectedPickupAddress?.addressLine1 ??
                'Pickup Location',
            lat: pickup.latitude,
            lng: pickup.longitude,
            contactName:
                state.selectedPickupAddress?.contactName?.isNotEmpty == true
                ? state.selectedPickupAddress!.contactName!
                : (user?.name ?? 'Customer'),
            contactPhone:
                state.selectedPickupAddress?.contactPhone?.isNotEmpty == true
                ? state.selectedPickupAddress!.contactPhone!
                : (user?.phone ?? '+639123456789'),
          ),
          dropoff: OrderAddressDto(
            address: updatedLocationState.destinationAddress?.toString() ??
                state.selectedDropoffAddress?.addressLine1 ??
                'Destination',
            lat: dropoff.latitude,
            lng: dropoff.longitude,
            contactName:
                state.selectedDropoffAddress?.contactName?.isNotEmpty == true
                ? state.selectedDropoffAddress!.contactName!
                : (user?.name ?? 'Customer'),
            contactPhone:
                state.selectedDropoffAddress?.contactPhone?.isNotEmpty == true
                ? state.selectedDropoffAddress!.contactPhone!
                : (user?.phone ?? '+639123456789'),
          ),
          notes: 'LesGo delivery booking',
          paymentMethod: state.paymentMethod,
          voucherCode: state.voucherCode,
          discountAmount: state.discount > 0 ? state.discount : null,
          meta: {
            'item_description': state.itemDescription,
            'item_weight': state.itemWeight,
            'distance_km': updatedLocationState.distanceInKm,
            'duration_seconds': updatedLocationState.durationInSeconds,
            'order_type': 'lesgo',
          },
        );

        final estimatedFare = await orderDataSource.getFareEstimateRaw(
              serviceId: BookingServiceIds.lesgo,
              estimatedDistanceM: createOrderRequest.estimatedDistanceM,
              pickupLat: pickup.latitude,
              pickupLng: pickup.longitude,
              dropoffLat: dropoff.latitude,
              dropoffLng: dropoff.longitude,
            ) ??
            0.0;

        final payableFare = (estimatedFare > 0 ? estimatedFare : 50.0) -
            state.discount;
        final walletAmount = payableFare > 0 ? payableFare : 0.0;

        final walletOk = await validateWalletBalanceForOrder(
          _ref,
          amount: walletAmount,
          paymentMethod: state.paymentMethod,
          context: context,
        );
        if (!walletOk) return;

        print('🔵 LesGo: Creating order with API...');
        final response = await orderDataSource.createOrder(createOrderRequest);
        print('🟢 LesGo: Order created successfully - ID: ${response.data.id}');

        final payAmount = response.data.effectiveTotalAmount > 0
            ? response.data.effectiveTotalAmount
            : response.data.estimatedFare;

        if (!context.mounted) return;

        final paid = await completeBookingPayment(
          context: context,
          ref: _ref,
          orderId: response.data.id,
          amount: payAmount,
          paymentMethod: state.paymentMethod,
          serviceLabel: 'LesGo',
        );
        if (!paid) return;

        final orderId = response.data.id.toString();
        final order = response.data;
        final fb = order.fareBreakdown;

        AppRouter.pushReplacement(
          context,
          BookingRoutes.driverFinding,
          arguments: {
            'orderId': orderId,
            'orderType': 'LesGo',
            'orderData': {
              'pickupAddress': updatedLocationState.pickupAddress?.toString(),
              'dropoffAddress': updatedLocationState.destinationAddress
                  ?.toString(),
              'itemDescription': state.itemDescription,
              'itemWeight': state.itemWeight,
              'paymentMethod': state.paymentMethod,
              'voucherCode': state.voucherCode,
              'discount': state.discount,
              'fare': payAmount,
              'total': payAmount,
              'estimated_fare': order.estimatedFare,
              'baseFee': fb?['base_fare'] ?? order.estimatedFare,
              'distanceFee': fb?['distance_fare'] ?? 0.0,
              'serviceFee': fb?['service_fee'] ?? 0.0,
            },
          },
        );
      } catch (e) {
        print('🔴 LesGo: Error creating order - $e');
        if (context.mounted) {
          SnackBarUtils.showErrorFrom(
            context,
            e,
            fallbackEn: 'Could not create your LesGo booking.',
            fallbackTl: 'Hindi makagawa ng LesGo booking.',
          );
        }
      } finally {
        state = state.copyWith(isBooking: false);
      }
    }
  }

  // Collapse sheet helper
  void collapseSheet(DraggableScrollableController controller) {
    if (!controller.isAttached) return;
    controller.animateTo(
      sheetMin,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

final lesgoProvider = StateNotifierProvider<LesgoNotifier, LesgoState>((ref) {
  return LesgoNotifier(ref);
});
