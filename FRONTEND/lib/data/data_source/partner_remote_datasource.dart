import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/partner/partner_dto.dart';

@lazySingleton
class PartnerRemoteDataSource {
  final DioClient _dioClient;

  PartnerRemoteDataSource(this._dioClient);

  /// Get list of partners (restaurants, stores, etc.)
  Future<PartnersResponseDto> getPartners({
    String? category,
    String? search,
    bool? isOpen,
    bool? isFeatured,
    int page = 1,
    int perPage = 20,
  }) async {
    final dio = _dioClient.dio;
    
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (category != null) queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isOpen != null) queryParams['is_open'] = isOpen ? '1' : '0';
      if (isFeatured != null) queryParams['is_featured'] = isFeatured ? '1' : '0';
      
      print('🔵 PartnerDataSource: Fetching partners with params: $queryParams');
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.partners}',
        queryParameters: queryParams,
      );
      
      print('🟢 PartnerDataSource: Got ${response.data['data'].length} partners');
      
      return PartnersResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      print('🔴 PartnerDataSource: Error fetching partners - ${e.message}');
      throw Exception('Failed to fetch partners: ${e.message}');
    } catch (e) {
      print('🔴 PartnerDataSource: Unexpected error - $e');
      throw Exception('Failed to fetch partners: $e');
    }
  }

  /// Get partner details
  Future<PartnerDto> getPartner(int partnerId) async {
    final dio = _dioClient.dio;
    
    try {
      print('🔵 PartnerDataSource: Fetching partner $partnerId');
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.partnerById(partnerId)}',
      );
      
      return PartnerDto.fromJson(response.data['data']);
    } on DioException catch (e) {
      print('🔴 PartnerDataSource: Error fetching partner - ${e.message}');
      throw Exception('Failed to fetch partner: ${e.message}');
    } catch (e) {
      print('🔴 PartnerDataSource: Unexpected error - $e');
      throw Exception('Failed to fetch partner: $e');
    }
  }

  /// Get partner menu (categories and items)
  Future<PartnerMenuResponseDto> getPartnerMenu(int partnerId) async {
    final dio = _dioClient.dio;
    
    try {
      print('🔵 PartnerDataSource: Fetching menu for partner $partnerId');
      
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.partnerMenu(partnerId)}',
      );
      
      print('🟢 PartnerDataSource: Got menu with ${response.data['data']['categories'].length} categories');
      
      return PartnerMenuResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      print('🔴 PartnerDataSource: Error fetching menu - ${e.message}');
      throw Exception('Failed to fetch menu: ${e.message}');
    } catch (e) {
      print('🔴 PartnerDataSource: Unexpected error - $e');
      throw Exception('Failed to fetch menu: $e');
    }
  }
}
