import 'package:injectable/injectable.dart';

import '../../domain/repository/partner_repository.dart';
import '../data_source/partner_remote_datasource.dart';
import '../data_source/dto/partner/partner_dto.dart';

/// Implementation of [PartnerRepository] that delegates to PartnerRemoteDataSource.
@LazySingleton(as: PartnerRepository)
class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource _remoteDataSource;

  PartnerRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PartnerDto>> getPartners({
    String? serviceType,
    String? search,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _remoteDataSource.getPartners(
      category: serviceType,
      search: search,
    );
    return response.data;
  }

  @override
  Future<PartnerDto> getPartnerById(int partnerId) async {
    return await _remoteDataSource.getPartner(partnerId);
  }

  @override
  Future<List<MenuItemDto>> getPartnerMenu(int partnerId) async {
    final response = await _remoteDataSource.getPartnerMenu(partnerId);
    // Flatten categories → items
    final items = <MenuItemDto>[];
    for (final category in response.data.categories) {
      if (category.availableItems != null) {
        items.addAll(category.availableItems!);
      }
    }
    return items;
  }

  @override
  Future<Map<String, dynamic>> getPartnerReviews(int partnerId, {int page = 1}) async {
    // Not yet available in datasource — return empty for now
    return {'reviews': [], 'total': 0};
  }
}
