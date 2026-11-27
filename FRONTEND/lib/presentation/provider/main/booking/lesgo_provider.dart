import 'dart:async';

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

/// Null for blank text so `a ?? fallback` falls through to the fallback.
String? _nonEmpty(String? value) =>
    (value == null || value.trim().isEmpty) ? null : value;

/// Pure helpers for the LesGo booking form (unit-testable).
class LesgoBookingRules {
  LesgoBookingRules._();

  static const double maxWeightKg = 100;

  /// Parses the optional weight field. Returns null for empty/invalid input,
  /// non-positive values and anything above [maxWeightKg].
  static double? parseWeightKg(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    final match = RegExp(r'^\d+(\.\d+)?').firstMatch(text);
    if (match == null) return null;
    final rest = text.substring(match.end).trim().toLowerCase();
    if (rest.isNotEmpty && rest != 'kg' && rest != 'kgs') return null;
    final value = double.tryParse(match.group(0)!);
    if (value == null || !value.isFinite || value <= 0 || value > maxWeightKg) {
      return null;
    }
    return value;
  }

  /// Weight is optional: empty is valid, anything else must parse.
  static bool isWeightValid(String raw) =>
      raw.trim().isEmpty || parseWeightKg(raw) != null;

  /// Combines pickup/dropoff notes into the single `notes` field (max 500).
  static String? buildNotes(String pickupNotes, String dropoffNotes) {
    final parts = <String>[
      if (pickupNotes.trim().isNotEmpty) 'Pickup: ${pickupNotes.trim()}',
      if (dropoffNotes.trim().isNotEmpty) 'Dropoff: ${dropoffNotes.trim()}',
    ];
    if (parts.isEmpty) return null;
    final joined = parts.join('\n');
    return joined.length > 500 ? joined.substring(0, 500) : joined;
  }
}

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
  final FareBreakdownResult? fareEstimate;
  final bool isLoadingFare;
  final bool fareError;
  final String pickupNotes;
  final String dropoffNotes;

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
    this.fareEstimate,
    this.isLoadingFare = false,
    this.fareError = false,
    this.pickupNotes = '',
    this.dropoffNotes = '',
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
    FareBreakdownResult? fareEstimate,
    bool clearFareEstimate = false,
    bool? isLoadingFare,
    bool? fareError,
    String? pickupNotes,
    String? dropoffNotes,
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
      voucherError: clearVoucherError
          ? null
          : (voucherError ?? this.voucherError),
      selectedPickupAddress: clearPickupAddress
          ? null
          : (selectedPickupAddress ?? this.selectedPickupAddress),
      selectedDropoffAddress: clearDropoffAddress
          ? null
          : (selectedDropoffAddress ?? this.selectedDropoffAddress),
      isBooking: isBooking ?? this.isBooking,
      fareEstimate: clearFareEstimate
          ? null
          : (fareEstimate ?? this.fareEstimate),
      isLoadingFare: isLoadingFare ?? this.isLoadingFare,
      fareError: fareError ?? this.fareError,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      dropoffNotes: dropoffNotes ?? this.dropoffNotes,
    );
  }
}

class LesgoNotifier extends StateNotifier<LesgoState> {
  final Ref _ref;
  GoogleMapController? _mainMapController;
  GoogleMapController? _overlayMapController;
  final VoucherRemoteDataSource _voucherDataSource =
      getIt<VoucherRemoteDataSource>();
  final OrderRemoteDataSource _orderDataSource = getIt<OrderRemoteDataSource>();
  static const double _sheetMin = 0.04;
  static const double _sheetMax = 0.55;
  static const double _sheetDefault =
      0.28; // Default initial size - shows more map

  LesgoNotifier(this._ref) : super(LesgoState());

  /// Bumped whenever a fare request starts or the inputs are invalidated so a
  /// slower, older response cannot overwrite a newer one.
  int _fareSeq = 0;
  Timer? _weightDebounce;

  @override
  void dispose() {
    _weightDebounce?.cancel();
    super.dispose();
  }

  void setItemDescription(String value) {
    if (value == state.itemDescription) return;
    state = state.copyWith(itemDescription: value);
  }

  void setPickupNotes(String value) {
    if (value == state.pickupNotes) return;
    state = state.copyWith(pickupNotes: value);
  }

  void setDropoffNotes(String value) {
    if (value == state.dropoffNotes) return;
    state = state.copyWith(dropoffNotes: value);
  }

  /// Stores the weight and re-quotes the fare (debounced) when it changes.
  void setItemWeight(String value) {
    if (value == state.itemWeight) return;
    state = state.copyWith(itemWeight: value);
    _weightDebounce?.cancel();
    final loc = _ref.read(lesgoLocationProvider);
    if (loc.pickupLocation == null || loc.destinationLocation == null) return;
    if (!LesgoBookingRules.isWeightValid(value)) return;
    _weightDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) fetchFareEstimate();
    });
  }

  /// Distance for the estimate: routed distance, else straight-line distance.
  int _estimatedDistanceM(LesgoLocationState loc) {
    final km = loc.distanceInKm;
    if (km != null && km > 0) return (km * 1000).round();
    return BookingGeoUtils.distanceMeters(
      lat1: loc.pickupLocation!.latitude,
      lng1: loc.pickupLocation!.longitude,
      lat2: loc.destinationLocation!.latitude,
      lng2: loc.destinationLocation!.longitude,
    );
  }

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
      clearFareEstimate: true,
      itemDescription: '',
      itemWeight: '',
      paymentMethod: 'cash',
      pickupNotes: '',
      dropoffNotes: '',
      fareError: false,
      isLoadingFare: false,
      isBooking: false,
    );
    _fareSeq++;
    _weightDebounce?.cancel();

    await notifier.getCurrentLocation();
  }

  void cleanup() {
    _mainMapController?.dispose();
    _mainMapController = null;
    _overlayMapController?.dispose();
    _overlayMapController = null;
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
      // Fetch fare estimate after route is ready
      await fetchFareEstimate();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => fitBoundsOrSelected());
    print('🔍 LesGo: confirmSelection completed');
  }

  /// Fetches the full fare breakdown from the estimate API.
  Future<void> fetchFareEstimate() async {
    final locationState = _ref.read(lesgoLocationProvider);
    final pickup = locationState.pickupLocation;
    final dropoff = locationState.destinationLocation;
    if (pickup == null || dropoff == null) return;
    if (!LesgoBookingRules.isWeightValid(state.itemWeight)) {
      state = state.copyWith(isLoadingFare: false, clearFareEstimate: true);
      return;
    }

    final seq = ++_fareSeq;
    state = state.copyWith(isLoadingFare: true, fareError: false);

    FareBreakdownResult? result;
    try {
      result = await _orderDataSource.getFareBreakdownFull(
        serviceId: BookingServiceIds.lesgo,
        estimatedDistanceM: _estimatedDistanceM(locationState),
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        estimatedWeightKg: LesgoBookingRules.parseWeightKg(state.itemWeight),
      );
    } catch (_) {
      result = null;
    }
    if (!mounted || seq != _fareSeq) return;

    state = state.copyWith(
      fareEstimate: result,
      clearFareEstimate: result == null,
      isLoadingFare: false,
      fareError: result == null,
    );
  }

  /// Auto-fetch route and fare when both locations are available (from saved addresses).
  Future<void> _autoFetchRouteAndFare() async {
    final locationState = _ref.read(lesgoLocationProvider);
    if (locationState.pickupLocation != null &&
        locationState.destinationLocation != null) {
      await _ref
          .read(lesgoLocationProvider.notifier)
          .fetchRouteIfBothSet(forceAllow: true);
      await fetchFareEstimate();
    }
  }

  Future<void> focusOn(LatLng? target) async {
    if (target == null) return;
    final controller = _mainMapController;
    await Future.wait([
      if (controller != null)
        controller.animateCamera(CameraUpdate.newLatLng(target)),
    ]);
  }

  void updateItemDescription(String value) {
    state = state.copyWith(itemDescription: value);
  }

  void updateItemWeight(String value) {
    state = state.copyWith(itemWeight: value);
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  Future<double?> _estimateOrderValue() async {
    final locationState = _ref.read(lesgoLocationProvider);
    final pickup = locationState.pickupLocation;
    final dropoff = locationState.destinationLocation;
    if (pickup == null || dropoff == null) return null;

    return _orderDataSource.getFareEstimateRaw(
      serviceId: BookingServiceIds.lesgo,
      estimatedDistanceM: _estimatedDistanceM(locationState),
      estimatedWeightKg: LesgoBookingRules.parseWeightKg(state.itemWeight),
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropoffLat: dropoff.latitude,
      dropoffLng: dropoff.longitude,
    );
  }

  Future<String?> applyVoucher(String voucherCode) async {
    final trimmed = voucherCode.trim();
    if (trimmed.isEmpty) return 'Enter a voucher code';

    double? orderValue;
    try {
      orderValue = await _estimateOrderValue();
    } catch (e) {
      return ApiErrorMapper.message(
        e,
        fallbackEn: 'Could not apply voucher. Please try again.',
        fallbackTl: 'Hindi ma-apply ang voucher. Subukan muli.',
      );
    }
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
        state = state.copyWith(isValidatingVoucher: false, voucherError: msg);
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
      state = state.copyWith(isValidatingVoucher: false, voucherError: msg);
      return msg;
    }
  }

  void removeVoucher() {
    state = state.copyWith(clearVoucher: true, clearVoucherError: true);
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
    _fareSeq++;
    state = state.copyWith(
      selectedPickupAddress: address,
      clearFareEstimate: true,
      isLoadingFare: false,
      fareError: false,
    );
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
    // Auto-fetch route + fare if both locations are set
    _autoFetchRouteAndFare();
  }

  void selectDropoffAddress(AddressDto address) {
    print(
      '🔍 LesGo: selectDropoffAddress called with: ${address.addressLine1} (${address.latitude}, ${address.longitude})',
    );
    _fareSeq++;
    state = state.copyWith(
      selectedDropoffAddress: address,
      clearFareEstimate: true,
      isLoadingFare: false,
      fareError: false,
    );
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
    // Auto-fetch route + fare if both locations are set
    _autoFetchRouteAndFare();
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
    if (locationState.destinationLocation == null &&
        state.selectedDropoffAddress != null) {
      final address = state.selectedDropoffAddress!;
      await _ref
          .read(lesgoLocationProvider.notifier)
          .updateDestinationWithAddress(
            LatLng(address.latitude, address.longitude),
            address.addressLine1,
            null,
          );
    }

    // Sync pickup location from selected address if needed
    if (locationState.pickupLocation == null &&
        state.selectedPickupAddress != null) {
      final address = state.selectedPickupAddress!;
      await _ref
          .read(lesgoLocationProvider.notifier)
          .updatePickupWithAddress(
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
    if (state.isLoadingFare ||
        _ref.read(lesgoLocationProvider).isLoadingRoute) {
      SnackBarUtils.showWarning(
        context,
        'Still calculating your route and fare. Please wait a moment.',
      );
      return;
    }
    if (!LesgoBookingRules.isWeightValid(state.itemWeight)) {
      SnackBarUtils.showWarning(
        context,
        'Enter an item weight between 0 and ${LesgoBookingRules.maxWeightKg.toInt()} kg.',
      );
      return;
    }
    state = state.copyWith(isBooking: true);

    try {
      if (!await NetworkGuard.ensureOnline(context)) return;
      if (!await ActiveOrderLimitGuard.ensureCanBook(context)) return;

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

          final estimatedDistanceM = _estimatedDistanceM(updatedLocationState);
          final weightKg = LesgoBookingRules.parseWeightKg(state.itemWeight);
          final userPhone = user?.phone?.trim();
          final fallbackPhone = (userPhone != null && userPhone.isNotEmpty)
              ? userPhone
              : null;

          final createOrderRequest = CreateOrderRequestDto(
            serviceId: BookingServiceIds.lesgo,
            estimatedDistanceM: estimatedDistanceM,
            pickup: OrderAddressDto(
              address:
                  _nonEmpty(updatedLocationState.pickupAddress?.toString()) ??
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
                  : fallbackPhone,
            ),
            dropoff: OrderAddressDto(
              address:
                  _nonEmpty(
                    updatedLocationState.destinationAddress?.toString(),
                  ) ??
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
                  : fallbackPhone,
            ),
            notes: LesgoBookingRules.buildNotes(
              state.pickupNotes,
              state.dropoffNotes,
            ),
            itemDescription: state.itemDescription.trim().isEmpty
                ? null
                : state.itemDescription.trim(),
            estimatedWeightKg: weightKg,
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

          // Client-side wallet pre-check only when we have a real quote; if
          // the estimate is unavailable the server decides on createOrder.
          double? estimatedFare;
          try {
            estimatedFare = await orderDataSource.getFareEstimateRaw(
              serviceId: BookingServiceIds.lesgo,
              estimatedDistanceM: createOrderRequest.estimatedDistanceM,
              pickupLat: pickup.latitude,
              pickupLng: pickup.longitude,
              dropoffLat: dropoff.latitude,
              dropoffLng: dropoff.longitude,
              estimatedWeightKg: weightKg,
            );
          } catch (_) {
            estimatedFare = null;
          }

          if (estimatedFare != null && estimatedFare > 0) {
            final payableFare = estimatedFare - state.discount;
            final walletAmount = payableFare > 0 ? payableFare : 0.0;

            final walletOk = await validateWalletBalanceForOrder(
              _ref,
              amount: walletAmount,
              paymentMethod: state.paymentMethod,
              context: context,
            );
            if (!walletOk) return;
          }

          print('🔵 LesGo: Creating order with API...');
          final response = await orderDataSource.createOrder(
            createOrderRequest,
          );
          print(
            '🟢 LesGo: Order created successfully - ID: ${response.data.id}',
          );

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
        }
      }
    } catch (e) {
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
