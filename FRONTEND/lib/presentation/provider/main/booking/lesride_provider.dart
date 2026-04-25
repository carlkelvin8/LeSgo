import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lesride_location_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/data_source/order_remote_datasource.dart';
import '../../../../data/data_source/dto/order/create_order_request_dto.dart';
import '../profile/profile_provider.dart';
import '../../../widgets/widgets.dart';

class LesrideState {
  final bool isFullscreen;
  final String paymentMethod;
  final bool selectingDestination;
  final bool pendingFit;
  final bool shouldCollapseAfterFullscreen;

  LesrideState({
    this.isFullscreen = false,
    this.paymentMethod = 'cash',
    this.selectingDestination = false,
    this.pendingFit = false,
    this.shouldCollapseAfterFullscreen = false,
  });

  LesrideState copyWith({
    bool? isFullscreen,
    String? paymentMethod,
    bool? selectingDestination,
    bool? pendingFit,
    bool? shouldCollapseAfterFullscreen,
  }) {
    return LesrideState(
      isFullscreen: isFullscreen ?? this.isFullscreen,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectingDestination: selectingDestination ?? this.selectingDestination,
      pendingFit: pendingFit ?? this.pendingFit,
      shouldCollapseAfterFullscreen:
          shouldCollapseAfterFullscreen ?? this.shouldCollapseAfterFullscreen,
    );
  }
}

class LesrideNotifier extends StateNotifier<LesrideState> {
  final Ref _ref;
  GoogleMapController? _mainMapController;
  GoogleMapController? _overlayMapController;
  static const double _sheetMin = 0.04;
  static const double _sheetMax = 0.55;
  static const double _sheetDefault =
      0.28; // Default initial size - shows more map

  LesrideNotifier(this._ref) : super(LesrideState());

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
    final notifier = _ref.read(lesrideLocationProvider.notifier);
    notifier.reset();
    await notifier.getCurrentLocation();
  }

  void cleanup() {
    _mainMapController?.dispose();
    _mainMapController = null;
    // Note: We don't reset the location provider here to avoid lifecycle conflicts.
    // The provider state can persist, and initialize() will reset it when the screen is opened again.
  }

  Future<void> fitBoundsOrSelected() async {
    final state = _ref.read(lesrideLocationProvider);
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
    await _ref.read(lesrideLocationProvider.notifier).getCurrentLocation();
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
    if (!state.isFullscreen)
      return; // Block marker moves when not in fullscreen selection.

    if (state.selectingDestination) {
      await _ref
          .read(lesrideLocationProvider.notifier)
          .updateDestination(latLng);
    } else {
      await _ref.read(lesrideLocationProvider.notifier).updatePickup(latLng);
    }
    animateToSelected();
  }

  Future<void> animateToSelected() async {
    final selected = _ref.read(lesrideLocationProvider).selectedLocation;
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

  Future<void> updateCamera(LesrideLocationState locationState) async {
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
    final dest = _ref.read(lesrideLocationProvider).destinationLocation;
    if (dest != null) {
      _ref.read(lesrideLocationProvider.notifier).setSelectedLocation(dest);
      focusOn(dest);
    }
    openMapSelection();
  }

  void openPickupSelection() {
    state = state.copyWith(selectingDestination: false);
    final pickup = _ref.read(lesrideLocationProvider).pickupLocation;
    if (pickup != null) {
      _ref.read(lesrideLocationProvider.notifier).setSelectedLocation(pickup);
      focusOn(pickup);
    }
    openMapSelection();
  }

  Future<void> confirmSelection() async {
    // Selection already stored in provider on tap; just close overlay
    state = state.copyWith(
      isFullscreen: false,
      shouldCollapseAfterFullscreen: true,
      pendingFit: true,
    );

    // Ensure route is fetched if both locations are set
    final locationState = _ref.read(lesrideLocationProvider);
    if (locationState.pickupLocation != null &&
        locationState.destinationLocation != null) {
      await _ref.read(lesrideLocationProvider.notifier).fetchRouteIfBothSet();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => fitBoundsOrSelected());
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

  void setPendingFit(bool value) {
    state = state.copyWith(pendingFit: value);
  }

  void setShouldCollapseAfterFullscreen(bool value) {
    state = state.copyWith(shouldCollapseAfterFullscreen: value);
  }

  // Handle route auto-fetching when locations change
  void handleLocationChange(
    LesrideLocationState? previous,
    LesrideLocationState next,
  ) {
    updateCamera(next);

    // Auto-fetch route when both locations are set
    if (next.pickupLocation != null &&
        next.destinationLocation != null &&
        (previous?.pickupLocation != next.pickupLocation ||
            previous?.destinationLocation != next.destinationLocation)) {
      // Only fetch if locations changed and route is not already loading
      if (!next.isLoadingRoute && next.routePolylines.isEmpty) {
        _ref.read(lesrideLocationProvider.notifier).fetchRouteIfBothSet();
      }
    }
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

  // Handle booking action with validation and dialog
  Future<void> handleBook(BuildContext context) async {
    final locationState = _ref.read(lesrideLocationProvider);

    // Check if destination is set
    if (locationState.destinationLocation == null ||
        locationState.destinationAddress == null) {
      // Show warning message if destination is not set
      SnackBarUtils.showWarning(
        context,
        'Please select a destination before booking',
      );
      return;
    }

    // Show booking summary dialog with blurred background
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const LesrideBookingDialogWrapper(),
    );

    if (confirmed == true) {
      // User confirmed booking - create real order via API
      if (context.mounted) {
        try {
          final orderDataSource = getIt<OrderRemoteDataSource>();
          final locationState = _ref.read(lesrideLocationProvider);
          final profileState = _ref.read(profileProvider);
          final user = profileState.user;

          final createOrderRequest = CreateOrderRequestDto(
            serviceId: 2, // LesRide service ID
            estimatedDistanceM: (locationState.distanceInKm != null) 
                ? (locationState.distanceInKm! * 1000).round() 
                : 5000,
            pickup: OrderAddressDto(
              address: locationState.pickupAddress?.toString() ?? 'Pickup Location',
              lat: locationState.pickupLocation?.latitude ?? 8.4542,
              lng: locationState.pickupLocation?.longitude ?? 124.6319,
              contactName: user?.name ?? 'Customer',
              contactPhone: user?.phone ?? '+639123456789',
            ),
            dropoff: OrderAddressDto(
              address: locationState.destinationAddress?.toString() ?? 'Destination',
              lat: locationState.destinationLocation?.latitude ?? 8.4542,
              lng: locationState.destinationLocation?.longitude ?? 124.6319,
              contactName: user?.name ?? 'Customer',
              contactPhone: user?.phone ?? '+639123456789',
            ),
            notes: 'LesRide booking',
            paymentMethod: state.paymentMethod,
            meta: {
              'vehicle_type': 'motorcycle',
              'passenger_name': user?.name ?? 'Customer',
              'distance_km': locationState.distanceInKm,
              'duration_seconds': locationState.durationInSeconds,
              'order_type': 'lesride',
            },
          );

          print('🔵 LesRide: Creating order with API...');
          final response = await orderDataSource.createOrder(createOrderRequest);
          print('🟢 LesRide: Order created successfully - ID: ${response.data.id}');

          final orderId = response.data.id.toString();

          AppRouter.pushReplacement(
            context,
            BookingRoutes.driverFinding,
            arguments: {
              'orderId': orderId,
              'orderType': 'LesRide',
              'orderData': {
                'pickup': locationState.pickupLocation?.toString(),
                'destination': locationState.destinationLocation?.toString(),
                'paymentMethod': state.paymentMethod,
                'fare': 120.0, // Calculate actual fare
              },
            },
          );
        } catch (e) {
          print('🔴 LesRide: Error creating order - $e');
          if (context.mounted) {
            SnackBarUtils.showError(context, 'Failed to create booking: $e');
          }
        }
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

final lesrideProvider = StateNotifierProvider<LesrideNotifier, LesrideState>((
  ref,
) {
  return LesrideNotifier(ref);
});
