import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/menu_image_utils.dart';
import 'dto/partner/partner_dto.dart';
import 'dto/partner/store_branch.dart';

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
    // List every open branch of a store as its own card (same menu, own
    // name/location). Older servers ignore the flag and return one card.
    bool expandBranches = false,
  }) async {
    final dio = _dioClient.dio;

    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (category != null) queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isOpen != null) queryParams['is_open'] = isOpen ? '1' : '0';
      if (isFeatured != null) {
        queryParams['is_featured'] = isFeatured ? '1' : '0';
      }
      if (expandBranches) queryParams['expand_branches'] = '1';

      print(
        '🔵 PartnerDataSource: Fetching partners with params: $queryParams',
      );

      final response = await dio.get(
        ApiConstants.partners,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      final count = data is List ? data.length : 0;
      print('🟢 PartnerDataSource: Got $count partners');

      final normalized = _normalizePartnersResponse(
        Map<String, dynamic>.from(response.data as Map),
        expandBranches: expandBranches,
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

      final response = await dio.get(ApiConstants.partnerById(partnerId));

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

  /// Get a store's branches (pickup points).
  Future<List<StoreBranch>> getBranches(int partnerId) async {
    final response = await _dioClient.dio.get(
      ApiConstants.partnerBranches(partnerId),
    );
    final data = response.data;
    final raw = data is Map ? data['data'] : data;
    return (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => StoreBranch.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get partner menu (categories and items)
  Future<PartnerMenuResponseDto> getPartnerMenu(int partnerId) async {
    final dio = _dioClient.dio;

    try {
      print('🔵 PartnerDataSource: Fetching menu for partner $partnerId');

      final response = await dio.get(ApiConstants.partnerMenu(partnerId));

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

  Map<String, dynamic> _normalizePartnersResponse(
    Map<String, dynamic> json, {
    required bool expandBranches,
  }) {
    final data = json['data'];
    if (data is! List) return json;

    final rows = data.map((row) => Map<String, dynamic>.from(row as Map));
    final listings = expandBranches ? _branchListings(rows) : rows;
    json['data'] = listings.map((listing) {
      for (final field in ['cover_image_url', 'logo_url', 'image_url']) {
        final resolved = MenuImageUtils.resolve(listing[field]);
        if (resolved != null) {
          listing[field] = resolved;
        }
      }
      return listing;
    }).toList();

    return json;
  }

  // Older catalog responses can embed branches without expanding them. A
  // current server may send both formats together, so key by merchant and branch.
  Iterable<Map<String, dynamic>> _branchListings(
    Iterable<Map<String, dynamic>> rows,
  ) {
    final listings = <(int, int?), Map<String, dynamic>>{};
    for (final row in rows) {
      final partnerId = int.tryParse(row['id'].toString());
      if (partnerId == null) continue;
      final listingBranchId = int.tryParse(row['branch_id'].toString());
      final embedded = row['branches'];
      final branches = embedded is List
          ? embedded.whereType<Map>()
          : const <Map>[];
      var hasBranchRecords = false;

      for (final rawBranch in branches) {
        final branchId = int.tryParse(rawBranch['id'].toString());
        if (branchId == null || branchId <= 0) continue;
        hasBranchRecords = true;

        final branch = StoreBranch.fromJson(
          Map<String, dynamic>.from(rawBranch),
        );
        if (!branch.isOpen) continue;

        final key = (partnerId, branchId);
        final isExpandedRow = listingBranchId == branchId;
        if (!isExpandedRow && listings.containsKey(key)) continue;
        final partnerName = row['name'] as String;
        final branchName = branch.name.trim();
        final name =
            isExpandedRow ||
                branchName.isEmpty ||
                branchName.toLowerCase() == partnerName.toLowerCase()
            ? partnerName
            : branchName.toLowerCase().contains(partnerName.toLowerCase())
            ? branchName
            : '$partnerName – $branchName';

        listings[key] = {
          ...row,
          'branch_id': branchId,
          'name': name,
          'address': branch.address.isNotEmpty
              ? branch.address
              : (isExpandedRow ? row['address'] : null),
          'logo_url':
              MenuImageUtils.resolve(rawBranch['logo_url']) ?? row['logo_url'],
          'latitude': branch.latitude,
          'longitude': branch.longitude,
        };
      }

      if (!hasBranchRecords) {
        listings.putIfAbsent((partnerId, listingBranchId), () => row);
      }
    }
    return listings.values;
  }
}
