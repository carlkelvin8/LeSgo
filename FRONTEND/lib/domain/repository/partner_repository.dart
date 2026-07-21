import '../../data/data_source/dto/partner/partner_dto.dart';

/// Repository interface for partner/merchant operations.
abstract class PartnerRepository {
  /// Get list of all partners with optional filters.
  Future<List<PartnerDto>> getPartners({
    String? serviceType,
    String? search,
    double? latitude,
    double? longitude,
  });

  /// Get a single partner by ID.
  Future<PartnerDto> getPartnerById(int partnerId);

  /// Get menu items for a partner.
  Future<List<MenuItemDto>> getPartnerMenu(int partnerId);

  /// Get partner reviews.
  Future<Map<String, dynamic>> getPartnerReviews(int partnerId, {int page = 1});
}
