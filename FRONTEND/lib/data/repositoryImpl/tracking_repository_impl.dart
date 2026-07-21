import 'package:injectable/injectable.dart';

import '../../domain/repository/tracking_repository.dart';
import '../data_source/tracking_remote_datasource.dart';
import '../data_source/dto/tracking/tracking_dto.dart';

/// Implementation of [TrackingRepository].
@LazySingleton(as: TrackingRepository)
class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource _remoteDataSource;

  TrackingRepositoryImpl(this._remoteDataSource);

  @override
  Future<TrackingDto> getOrderTracking(int orderId) async {
    final response = await _remoteDataSource.getOrderTracking(orderId);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getDriverLocation(int orderId) async {
    final response = await _remoteDataSource.getDriverLocation(orderId);
    return response.toJson();
  }

  @override
  Future<Map<String, dynamic>> getOrderEta(int orderId) async {
    return await _remoteDataSource.getEta(orderId);
  }
}
