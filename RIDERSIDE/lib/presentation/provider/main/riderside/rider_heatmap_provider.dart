import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/rider_route_utils.dart';
import '../../../../domain/models/rider_order.dart';

class RiderHeatmapState {
  final bool showHeatmap;
  final List<DemandZone> zones;

  const RiderHeatmapState({
    this.showHeatmap = false,
    this.zones = const [],
  });

  RiderHeatmapState copyWith({bool? showHeatmap, List<DemandZone>? zones}) {
    return RiderHeatmapState(
      showHeatmap: showHeatmap ?? this.showHeatmap,
      zones: zones ?? this.zones,
    );
  }

  static Set<Circle> toCircles(List<DemandZone> zones) {
    return zones.map((zone) {
      final color = zone.intensity > 0.7
          ? Colors.red
          : zone.intensity > 0.5
              ? Colors.orange
              : Colors.yellow;
      return Circle(
        circleId: CircleId(
          'demand_${zone.center.latitude}_${zone.center.longitude}',
        ),
        center: zone.center,
        radius: zone.radius,
        fillColor: color.withValues(alpha: 0.15),
        strokeColor: color.withValues(alpha: 0.4),
        strokeWidth: 2,
      );
    }).toSet();
  }
}

class DemandZone {
  final LatLng center;
  final double radius;
  final double intensity;
  final String label;

  const DemandZone({
    required this.center,
    required this.radius,
    required this.intensity,
    this.label = '',
  });
}

final riderHeatmapProvider =
    StateNotifierProvider<RiderHeatmapNotifier, RiderHeatmapState>((ref) {
  return RiderHeatmapNotifier();
});

class RiderHeatmapNotifier extends StateNotifier<RiderHeatmapState> {
  RiderHeatmapNotifier() : super(RiderHeatmapState());

  void toggleHeatmap() {
    state = state.copyWith(showHeatmap: !state.showHeatmap);
  }

  void updateZones(List<DemandZone> zones) {
    state = state.copyWith(zones: zones);
  }

  /// Builds demand zones from real available order pickup locations.
  static List<DemandZone> zonesFromOrders(List<RiderOrder> orders) {
    final validOrders = orders
        .where(
          (order) => RiderRouteUtils.hasValidCoordinates(
            order.pickupLat,
            order.pickupLng,
          ),
        )
        .toList();

    if (validOrders.isEmpty) return const [];

    final maxEarnings = validOrders
        .map((order) => order.displayEarnings)
        .fold<double>(0, (max, value) => value > max ? value : max);

    return validOrders.map((order) {
      final intensity = maxEarnings > 0
          ? (order.displayEarnings / maxEarnings).clamp(0.35, 1.0)
          : 0.5;
      return DemandZone(
        center: LatLng(order.pickupLat, order.pickupLng),
        radius: 450 + (order.distanceKm.clamp(0.5, 8) * 40),
        intensity: intensity,
        label: 'Order #${order.id}',
      );
    }).toList();
  }
}
