import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/address/address_dto.dart';
import 'dto/address/address_response_dto.dart';
import 'dto/address/addresses_response_dto.dart';
import 'dto/address/create_address_request_dto.dart';
import 'dto/address/update_address_request_dto.dart';
import 'dto/address/delete_address_response_dto.dart';

@lazySingleton
class AddressRemoteDataSource {
  final DioClient _dioClient;

  AddressRemoteDataSource(this._dioClient);

  /// Get all addresses for the authenticated user
  Future<AddressesResponseDto> getAddresses() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/addresses');
      return AddressesResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return AddressesResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return AddressesResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return AddressesResponseDto.withError(e.toString());
    }
  }

  /// Get a single address by ID
  Future<AddressResponseDto> getAddress(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/addresses/$id');
      return AddressResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return AddressResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return AddressResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return AddressResponseDto.withError(e.toString());
    }
  }

  /// Create a new address
  Future<AddressResponseDto> createAddress(CreateAddressRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      print('🔵 AddressRemoteDataSource: Creating address...');
      print('🔵 AddressRemoteDataSource: Request data: ${request.toJson()}');
      
      final response = await dio.post(
        '/v1/addresses',
        data: request.toJson(),
      );
      
      print('🔵 AddressRemoteDataSource: Response status: ${response.statusCode}');
      print('🔵 AddressRemoteDataSource: Response data: ${response.data}');
      
      return AddressResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('🔴 AddressRemoteDataSource: DioException - ${e.message}');
      print('🔴 AddressRemoteDataSource: Response: ${e.response?.data}');
      print('🔴 AddressRemoteDataSource: Status code: ${e.response?.statusCode}');
      
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return AddressResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return AddressResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      print('🔴 AddressRemoteDataSource: Exception - $e');
      return AddressResponseDto.withError(e.toString());
    }
  }

  /// Update an existing address
  Future<AddressResponseDto> updateAddress(
    int id,
    UpdateAddressRequestDto request,
  ) async {
    final dio = _dioClient.dio;
    try {
      print('🔵 AddressRemoteDataSource: Updating address $id...');
      print('🔵 AddressRemoteDataSource: Request data: ${request.toJson()}');

      final response = await dio.patch(
        '/v1/addresses/$id',
        data: request.toJson(),
      );

      print('🔵 AddressRemoteDataSource: Update status: ${response.statusCode}');
      print('🔵 AddressRemoteDataSource: Update data: ${response.data}');

      return AddressResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('🔴 AddressRemoteDataSource: Update DioException - ${e.message}');
      print('🔴 AddressRemoteDataSource: Update response: ${e.response?.data}');
      print('🔴 AddressRemoteDataSource: Update status: ${e.response?.statusCode}');

      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return _addressResponseFromApiMap(
            e.response?.data as Map<String, dynamic>,
            fallbackMessage: e.message,
          );
        }
      }
      return AddressResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      print('🔴 AddressRemoteDataSource: Update exception - $e');
      return AddressResponseDto.withError(e.toString());
    }
  }

  AddressResponseDto _addressResponseFromApiMap(
    Map<String, dynamic> json, {
    String? fallbackMessage,
  }) {
    try {
      return AddressResponseDto.fromJson(json);
    } catch (_) {
      final message = json['message']?.toString() ??
          json['error']?.toString() ??
          fallbackMessage ??
          'Failed to save address';
      return AddressResponseDto.withError(message);
    }
  }

  /// Delete an address
  Future<DeleteAddressResponseDto> deleteAddress(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.delete('/v1/addresses/$id');
      return DeleteAddressResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return DeleteAddressResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return DeleteAddressResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return DeleteAddressResponseDto.withError(e.toString());
    }
  }
}
