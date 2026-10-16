import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

enum VehicleType {
  motorcycle,
  bicycle,
  car,
  scooter;

  String get label {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.scooter:
        return 'Scooter';
    }
  }

}

class RiderVehicle {
  final String id;
  final VehicleType type;
  final String plateNumber;
  final String makeModel;
  final String color;
  final bool isDefault;

  const RiderVehicle({
    required this.id,
    required this.type,
    required this.plateNumber,
    required this.makeModel,
    required this.color,
    this.isDefault = false,
  });

  RiderVehicle copyWith({
    String? id,
    VehicleType? type,
    String? plateNumber,
    String? makeModel,
    String? color,
    bool? isDefault,
  }) {
    return RiderVehicle(
      id: id ?? this.id,
      type: type ?? this.type,
      plateNumber: plateNumber ?? this.plateNumber,
      makeModel: makeModel ?? this.makeModel,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_type': type.name,
      'plate_number': plateNumber,
      'make_model': makeModel,
      'color': color,
      'is_default': isDefault,
    };
  }

  factory RiderVehicle.fromJson(Map<String, dynamic> json) {
    return RiderVehicle(
      id: json['id']?.toString() ?? '',
      type: VehicleType.values.firstWhere(
        (t) => t.name == json['vehicle_type'],
        orElse: () => VehicleType.motorcycle,
      ),
      plateNumber: json['plate_number']?.toString() ?? '',
      makeModel: json['make_model']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      isDefault: json['is_default'] == true,
    );
  }
}

class RiderVehicleState {
  final List<RiderVehicle> vehicles;
  final bool isLoading;
  final String? error;

  const RiderVehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
  });

  RiderVehicleState copyWith({
    List<RiderVehicle>? vehicles,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderVehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderVehicleNotifier extends StateNotifier<RiderVehicleState> {
  RiderVehicleNotifier() : super(const RiderVehicleState()) {
    loadVehicles();
  }

  Future<void> loadVehicles({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final response =
          await ApiService.dio.get('/v1/drivers/vehicles');
      final data = response.data;
      final vehiclesRaw =
          (data['data'] ?? data['vehicles'] ?? data) as List<dynamic>? ??
              [];

      final vehicles = vehiclesRaw.whereType<Map>().map((item) {
        return RiderVehicle.fromJson(Map<String, dynamic>.from(item));
      }).toList();

      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to load vehicles', e);
      state = state.copyWith(
        vehicles: const [],
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> addVehicle(RiderVehicle vehicle) async {
    try {
      // Server owns the authoritative vehicle id; never send the local
      // placeholder/timestamp id on create.
      final payload = vehicle.toJson()..remove('id');
      await ApiService.dio.post('/v1/drivers/vehicles', data: payload);
      await loadVehicles(silent: true);
      return true;
    } catch (e) {
      AppLogger.error('Failed to add vehicle', e);
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> updateVehicle(String id, RiderVehicle updated) async {
    try {
      await ApiService.dio.put('/v1/drivers/vehicles/$id', data: updated.toJson());
      await loadVehicles(silent: true);
      return true;
    } catch (e) {
      AppLogger.error('Failed to update vehicle', e);
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    try {
      await ApiService.dio.delete('/v1/drivers/vehicles/$id');
      await loadVehicles(silent: true);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete vehicle', e);
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }
}

final riderVehicleProvider =
    StateNotifierProvider<RiderVehicleNotifier, RiderVehicleState>(
  (ref) => RiderVehicleNotifier(),
);
