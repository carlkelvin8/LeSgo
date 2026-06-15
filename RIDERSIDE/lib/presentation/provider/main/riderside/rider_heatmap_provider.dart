import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
        circleId: CircleId('demand_${zone.center.latitude}_${zone.center.longitude}'),
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

  List<DemandZone> getMockZones(LatLng center) {
    return [
      DemandZone(
        center: LatLng(center.latitude + 0.01, center.longitude + 0.01),
        radius: 800,
        intensity: 0.9,
        label: 'High demand',
      ),
      DemandZone(
        center: LatLng(center.latitude - 0.008, center.longitude + 0.015),
        radius: 600,
        intensity: 0.7,
        label: 'Medium demand',
      ),
      DemandZone(
        center: LatLng(center.latitude + 0.015, center.longitude - 0.01),
        radius: 500,
        intensity: 0.5,
        label: 'Low demand',
      ),
      DemandZone(
        center: LatLng(center.latitude - 0.012, center.longitude - 0.008),
        radius: 700,
        intensity: 0.8,
        label: 'High demand',
      ),
      DemandZone(
        center: LatLng(center.latitude + 0.005, center.longitude - 0.015),
        radius: 400,
        intensity: 0.3,
        label: 'Low demand',
      ),
    ];
  }

}
