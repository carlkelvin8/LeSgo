import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/service/service_response_dto.dart';
import 'dto/service/services_response_dto.dart';

@lazySingleton
class ServiceRemoteDataSource {
  final DioClient _dioClient;

  ServiceRemoteDataSource(this._dioClient);

  /// Get list of services with optional filters
  /// 
  /// Query parameters:
  /// - partnerId: Filter by partner
  /// - category: Filter by category
  /// - onlyActive: Show only active services (default: true)
  /// - perPage: Items per page (default: 20)
  Future<ServicesResponseDto> getServices({
    int? partnerId,
    String? category,
    bool? onlyActive,
    int? perPage,
  }) async {
    final dio = _dioClient.dio;
    try {
      final queryParams = <String, dynamic>{};
      if (partnerId != null) queryParams['partner_id'] = partnerId;
      if (category != null) queryParams['category'] = category;
      if (onlyActive != null) queryParams['only_active'] = onlyActive;
      if (perPage != null) queryParams['per_page'] = perPage;

      final response = await dio.get(
        ApiConstants.servicesEndpoint,
        queryParameters: queryParams,
      );

      return ServicesResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return ServicesResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return ServicesResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return ServicesResponseDto.withError(e.toString());
    }
  }

  /// Get a single service by ID
  Future<ServiceResponseDto> getServiceById(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(
        ApiConstants.serviceByIdEndpoint(id),
      );

      return ServiceResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return ServiceResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return ServiceResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return ServiceResponseDto.withError(e.toString());
    }
  }
}
