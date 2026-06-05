import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/menu_image_utils.dart';
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
        ApiConstants.partners,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final count = data is List ? data.length : 0;
      print('🟢 PartnerDataSource: Got $count partners');
      
      final normalized = _normalizePartnersResponse(
        Map<String, dynamic>.from(response.data as Map),
      );
      return PartnersResponseDto.fromJson(normalized);
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
        ApiConstants.partnerById(partnerId),
      );
      
      final normalized = _normalizePartnerDetail(
        Map<String, dynamic>.from(response.data as Map),
      );
      return PartnerDto.fromJson(normalized['data']);
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
        ApiConstants.partnerMenu(partnerId),
      );

      final categories = response.data['data']?['categories'];
      final categoryCount = categories is List ? categories.length : 0;
      print('🟢 PartnerDataSource: Got menu with $categoryCount categories');
      
      final normalized = MenuImageUtils.normalizeMenuJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return PartnerMenuResponseDto.fromJson(normalized);
    } on DioException catch (e) {
      print('🔴 PartnerDataSource: Error fetching menu - ${e.message}');
      throw Exception('Failed to fetch menu: ${e.message}');
    } catch (e) {
      print('🔴 PartnerDataSource: Unexpected error - $e');
      throw Exception('Failed to fetch menu: $e');
    }
  }

  Map<String, dynamic> _normalizePartnerDetail(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return json;

    final map = Map<String, dynamic>.from(data);
    for (final field in ['cover_image_url', 'logo_url', 'image_url']) {
      final resolved = MenuImageUtils.resolve(map[field]);
      if (resolved != null) {
        map[field] = resolved;
      }
    }
    json['data'] = map;
    return json;
  }

  Map<String, dynamic> _normalizePartnersResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return json;

    json['data'] = data.map((partner) {
      if (partner is! Map) return partner;
      final map = Map<String, dynamic>.from(partner);
      for (final field in ['cover_image_url', 'logo_url', 'image_url']) {
        final resolved = MenuImageUtils.resolve(map[field]);
        if (resolved != null) {
          map[field] = resolved;
        }
      }
      return map;
    }).toList();

    return json;
  }
}
