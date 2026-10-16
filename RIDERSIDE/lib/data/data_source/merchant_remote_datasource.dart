import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/media_url_utils.dart';
import '../../core/utils/menu_image_utils.dart';
import '../../core/utils/multipart_file_utils.dart';
import 'dto/merchant/menu_item_dto.dart';
import 'dto/merchant/partner_dto.dart';
import 'dto/merchant/order_dto.dart';
import 'dto/merchant/review_dto.dart';

class MerchantRemoteDataSource {
  MerchantRemoteDataSource({Dio? dio}) : _client = dio;

  final Dio? _client;
  Dio get _dio => _client ?? ApiService.dio;
  
  /// Get partner profile by ID
  Future<PartnerDto> getPartnerProfile(int partnerId) async {
    try {
      final response = await _dio.get('/v1/partners/$partnerId');
      final data = response.data['data'] ?? response.data;
      return PartnerDto.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch partner profile: ${ApiService.extractError(e)}');
    }
  }
  
  /// Get menu with categories and items for a partner
  Future<MenuResponse> getMenu(int partnerId) =>
      _getMenu('/v1/partners/$partnerId/menu');

  Future<MenuResponse> _getMenu(String path) async {
    try {
      final response = await _dio.get(path);
      final raw = response.data as Map<String, dynamic>;
      final normalized = MenuImageUtils.normalizeMenuJson(raw);
      final data = normalized['data'] ?? normalized;
      
      final categories = (data['categories'] as List<dynamic>?)
          ?.map((json) => MenuCategoryDto.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];
      
      final partner = data['partner'] != null 
          ? PartnerDto.fromJson(data['partner'] as Map<String, dynamic>)
          : null;
      
      return MenuResponse(categories: categories, partner: partner);
    } catch (e) {
      throw Exception('Failed to fetch menu: ${ApiService.extractError(e)}');
    }
  }
  
  /// Includes hidden categories and sold-out items; failures remain visible.
  Future<MenuResponse> getMerchantMenu(int partnerId) =>
      _getMenu('/v1/partners/$partnerId/merchant-menu');

  Future<List<MenuItemDto>> getMenuItems(int partnerId) async {
    final menu = await getMerchantMenu(partnerId);
    return [
      for (final category in menu.categories) ...?category.availableItems,
    ];
  }

  /// Get orders for a partner
  Future<List<OrderDto>> getPartnerOrders(int partnerId, {String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        'partner_id': partnerId,
        'per_page': 100,
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      final orders = <int, OrderDto>{};
      var page = 1;
      var lastPage = 1;
      do {
        final response = await _dio.get('/v1/orders', queryParameters: {
          ...queryParams,
          'page': page,
        });
        final root = response.data as Map;
        final data = root['data'];
        final rows = data is Map ? data['data'] : data;
        if (rows is! List) {
          throw const FormatException('Invalid orders response');
        }
        for (final row in rows) {
          final order = OrderDto.fromJson(Map<String, dynamic>.from(row as Map));
          orders[order.id] = order;
        }
        final meta = root['meta'] is Map ? root['meta'] as Map : data;
        lastPage = meta is Map
            ? int.tryParse('${meta['last_page']}') ?? page
            : page;
        page++;
        if (rows.isEmpty) break;
      } while (page <= lastPage);
      return orders.values.toList();
    } catch (e) {
      throw Exception('Failed to fetch partner orders: ${ApiService.extractError(e)}');
    }
  }

  /// Fetch a single order with full relationships (driver profile, items, etc.)
  Future<OrderDto> getOrderById(int orderId) async {
    try {
      final response = await _dio.get('/v1/orders/$orderId');
      final data = response.data['data'] ?? response.data;
      return OrderDto.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch order details: ${ApiService.extractError(e)}');
    }
  }
  
  /// Get reviews for a partner restaurant
  Future<MerchantReviewsPage> getPartnerReviews(
    int partnerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/partners/$partnerId/reviews',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      return _parsePartnerReviewsPage(response.data);
    } catch (e) {
      throw Exception('Failed to fetch partner reviews: ${ApiService.extractError(e)}');
    }
  }

  /// Get review statistics for a partner
  Future<ReviewStatisticsDto?> getPartnerReviewStatistics(int partnerId) async {
    try {
      final response = await _dio.get(
        '/v1/reviews/statistics',
        queryParameters: {
          'reviewable_type': 'partner',
          'reviewable_id': partnerId,
        },
      );
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is! Map<String, dynamic>) return null;
      return ReviewStatisticsDto.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  MerchantReviewsPage _parsePartnerReviewsPage(dynamic raw) {
    final root = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final data = root['data'] ?? root;

    if (data is List) {
      final reviews = data
          .whereType<Map>()
          .map((item) => ReviewDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return MerchantReviewsPage(
        reviews: reviews,
        currentPage: 1,
        lastPage: 1,
        total: reviews.length,
      );
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final list = (map['data'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ReviewDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return MerchantReviewsPage(
        reviews: list,
        currentPage: (map['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (map['last_page'] as num?)?.toInt() ?? 1,
        total: (map['total'] as num?)?.toInt() ?? list.length,
      );
    }

    return MerchantReviewsPage(
      reviews: const [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }

  /// Update order status
  Future<void> updateOrderStatus(
    int orderId,
    String status, {
    String? cancelReason,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (cancelReason != null && cancelReason.isNotEmpty) {
        data['cancel_reason'] = cancelReason;
      }
      await _dio.patch('/v1/orders/$orderId/status', data: data);
    } catch (e) {
      throw Exception('Failed to update order status: ${ApiService.extractError(e)}');
    }
  }
  
  /// Upload image to media API and return public URL.
  Future<String> uploadMediaFile(
    String filePath, {
    String context = 'general',
  }) async {
    final formData = FormData.fromMap({'context': context});
    await appendDocumentFile(formData, 'file', filePath);

    final response = await _dio.post(
      ApiConstants.mediaUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data['data'] ?? response.data;
    if (data is Map<String, dynamic>) {
      final raw = data['url']?.toString() ?? data['path']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final absolute = MediaUrlUtils.toAbsoluteUrl(raw);
        if (absolute != null && absolute.isNotEmpty) return absolute;
        if (MediaUrlUtils.isHttpUrl(raw)) return raw;
      }
    }
    throw Exception('Media upload did not return a URL');
  }

  Future<String?> _resolveMenuItemImageUrl({
    String? imageUrl,
    String? imagePath,
  }) async {
    if (MediaUrlUtils.isLocalFilePath(imagePath)) {
      return uploadMediaFile(imagePath!, context: 'general');
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return MediaUrlUtils.resolve(imageUrl) ??
          (MediaUrlUtils.isHttpUrl(imageUrl) ? imageUrl : null);
    }
    // Existing server image in the form — omit from PATCH unless user picked a new file.
    if (MediaUrlUtils.isApiMediaPath(imagePath)) return null;
    return null;
  }

  Map<String, dynamic> _menuItemFieldsMap(CreateMenuItemRequest request) {
    final map = request.toJson();
    map.remove('image_url');
    return _normalizeMenuItemMultipartFields(map);
  }

  Map<String, dynamic> _menuItemUpdateFieldsMap(UpdateMenuItemRequest request) {
    final map = request.toJson();
    map.remove('image_url');
    return _normalizeMenuItemMultipartFields(map);
  }

  Map<String, dynamic> _normalizeMenuItemMultipartFields(
    Map<String, dynamic> map,
  ) {
    final normalized = <String, dynamic>{};
    map.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        normalized[key] = value ? '1' : '0';
      } else {
        normalized[key] = value;
      }
    });
    return normalized;
  }

  /// Create menu item
  Future<MenuItemDto> createMenuItem(int partnerId, CreateMenuItemRequest request) async {
    try {
      final payload = _menuItemFieldsMap(request);
      final uploadedImageUrl = await _resolveMenuItemImageUrl(
        imageUrl: request.imageUrl,
        imagePath: request.imagePath,
      );
      if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
        payload['image_url'] = uploadedImageUrl;
      }

      final response = await _dio.post(
        '/v1/partners/$partnerId/menu-items',
        data: payload,
      );

      final responseData = response.data['data'] ?? response.data;
      return MenuItemDto.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create menu item: ${ApiService.extractError(e)}');
    }
  }
  
  /// Update menu item
  Future<MenuItemDto> updateMenuItem(int itemId, UpdateMenuItemRequest request) async {
    try {
      final payload = _menuItemUpdateFieldsMap(request);
      final uploadedImageUrl = await _resolveMenuItemImageUrl(
        imageUrl: request.imageUrl,
        imagePath: request.imagePath,
      );
      if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
        payload['image_url'] = uploadedImageUrl;
      }

      final response = await _dio.patch(
        '/v1/menu-items/$itemId',
        data: payload,
      );

      final responseData = response.data['data'] ?? response.data;
      return MenuItemDto.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update menu item: ${ApiService.extractError(e)}');
    }
  }
  
  /// Delete menu item
  Future<void> deleteMenuItem(int itemId) async {
    try {
      await _dio.delete('/v1/menu-items/$itemId');
    } catch (e) {
      throw Exception('Failed to delete menu item: ${ApiService.extractError(e)}');
    }
  }

  /// Create menu category
  Future<MenuCategoryDto> createMenuCategory(int partnerId, CreateMenuCategoryRequest request) async {
    try {
      final payload = request.toJson();

      if (request.imagePath != null &&
          MediaUrlUtils.isLocalFilePath(request.imagePath)) {
        final uploadedIconUrl = await uploadMediaFile(
          request.imagePath!,
          context: 'general',
        );
        payload['icon_url'] = uploadedIconUrl;
      } else if (request.iconUrl != null && request.iconUrl!.isNotEmpty) {
        payload['icon_url'] = request.iconUrl;
      }

      final response = await _dio.post(
        '/v1/partners/$partnerId/menu-categories',
        data: payload,
      );
      final responseData = response.data['data'] ?? response.data;
      return MenuCategoryDto.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create menu category: ${ApiService.extractError(e)}');
    }
  }

  /// Update menu category
  Future<MenuCategoryDto> updateMenuCategory(int categoryId, UpdateMenuCategoryRequest request) async {
    try {
      final payload = request.toJson();

      if (request.imagePath != null &&
          MediaUrlUtils.isLocalFilePath(request.imagePath)) {
        final uploadedIconUrl = await uploadMediaFile(
          request.imagePath!,
          context: 'general',
        );
        payload['icon_url'] = uploadedIconUrl;
      } else if (request.iconUrl != null && request.iconUrl!.isNotEmpty) {
        payload['icon_url'] = request.iconUrl;
      }

      final response = await _dio.patch(
        '/v1/menu-categories/$categoryId',
        data: payload,
      );
      final data = response.data['data'] ?? response.data;
      return MenuCategoryDto.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update menu category: ${ApiService.extractError(e)}');
    }
  }

  /// Delete menu category
  Future<void> deleteMenuCategory(int categoryId) async {
    try {
      await _dio.delete('/v1/menu-categories/$categoryId');
    } catch (e) {
      throw Exception('Failed to delete menu category: ${ApiService.extractError(e)}');
    }
  }

  /// Update partner profile
  Future<PartnerDto> updatePartnerProfile(int partnerId, UpdatePartnerRequest request) async {
    try {
      final payload = request.toJson();
      payload.remove('logo_url');

      // Send a newly selected logo directly to the partner endpoint so the
      // backend stores it and persists the resulting logo_url in one request.
      dynamic requestData = payload;
      if (request.logoPath != null &&
          MediaUrlUtils.isLocalFilePath(request.logoPath)) {
        final formData = FormData.fromMap(payload);
        formData.files.add(MapEntry(
          'logo',
          await multipartFileFromPath(request.logoPath!),
        ));
        requestData = formData;
      } else {
        final existingLogoUrl = await _resolvePartnerLogoUrl(
          logoUrl: request.logoUrl,
          logoPath: request.logoPath,
        );
        if (existingLogoUrl != null && existingLogoUrl.isNotEmpty) {
          payload['logo_url'] = existingLogoUrl;
        }
      }

      final response = await _dio.patch(
        '/v1/partners/$partnerId',
        data: requestData,
      );
      final responseData = response.data['data'] ?? response.data;
      return PartnerDto.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update partner profile: ${ApiService.extractError(e)}');
    }
  }

  /// Toggle store open/close status using dedicated endpoint
  Future<PartnerDto> toggleStoreStatus(int partnerId, bool isOpen) async {
    try {
      final response = await _dio.post(
        '/v1/partners/$partnerId/toggle-status',
        data: {'is_open': isOpen},
      );
      final responseData = response.data['data'] ?? response.data;
      return PartnerDto.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to toggle store status: ${ApiService.extractError(e)}');
    }
  }

  Future<String?> _resolvePartnerLogoUrl({
    String? logoUrl,
    String? logoPath,
  }) async {
    if (MediaUrlUtils.isLocalFilePath(logoPath)) {
      return uploadMediaFile(logoPath!, context: 'profile');
    }
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return MediaUrlUtils.resolve(logoUrl) ??
          (MediaUrlUtils.isHttpUrl(logoUrl) ? logoUrl : null);
    }
    if (MediaUrlUtils.isApiMediaPath(logoPath)) {
      return null;
    }
    return null;
  }
}

/// Response wrapper for menu endpoint
class MenuResponse {
  final List<MenuCategoryDto> categories;
  final PartnerDto? partner;
  
  MenuResponse({required this.categories, this.partner});
}

/// Request DTOs
class CreateMenuItemRequest {
  final int menuCategoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? imagePath;
  final bool isAvailable;
  final int? stockCount;
  final List<String>? tags;
  final Map<String, dynamic>? options;

  CreateMenuItemRequest({
    required this.menuCategoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable = true,
    this.stockCount,
    this.tags,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'menu_category_id': menuCategoryId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_available': isAvailable,
      if (stockCount != null) 'stock_count': stockCount,
    };
    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
    }
    if (options != null && options!.isNotEmpty) {
      map['options'] = options;
    }
    return map;
  }
}

class UpdateMenuItemRequest {
  final int? menuCategoryId;
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? imagePath;
  final bool? isAvailable;
  final int? stockCount;
  final List<String>? tags;
  final Map<String, dynamic>? options;

  UpdateMenuItemRequest({
    this.menuCategoryId,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable,
    this.stockCount,
    this.tags,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (menuCategoryId != null) map['menu_category_id'] = menuCategoryId;
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (isAvailable != null) map['is_available'] = isAvailable;
    if (stockCount != null) map['stock_count'] = stockCount;
    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
    }
    if (options != null) {
      map['options'] = options;
    }
    return map;
  }
}

class CreateMenuCategoryRequest {
  final String name;
  final String? iconEmoji;
  final int? sortOrder;
  final String? imagePath;
  final String? iconUrl;

  CreateMenuCategoryRequest({
    required this.name,
    this.iconEmoji,
    this.sortOrder,
    this.imagePath,
    this.iconUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (iconEmoji != null) 'icon_emoji': iconEmoji,
    if (sortOrder != null) 'sort_order': sortOrder,
    if (iconUrl != null) 'icon_url': iconUrl,
  };
}

class UpdateMenuCategoryRequest {
  final String? name;
  final String? iconEmoji;
  final int? sortOrder;
  final String? imagePath;
  final String? iconUrl;

  UpdateMenuCategoryRequest({
    this.name,
    this.iconEmoji,
    this.sortOrder,
    this.imagePath,
    this.iconUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (iconEmoji != null) map['icon_emoji'] = iconEmoji;
    if (sortOrder != null) map['sort_order'] = sortOrder;
    if (iconUrl != null) map['icon_url'] = iconUrl;
    return map;
  }
}

class UpdatePartnerRequest {
  final String? name;
  final String? supportPhone;
  final String? supportEmail;
  final String? description;
  final String? logoUrl;
  final String? logoPath;
  final bool? isOpen;
  final int? estimatedDeliveryMinutes;
  final Map<String, dynamic>? openingHours;
  
  UpdatePartnerRequest({
    this.name,
    this.supportPhone,
    this.supportEmail,
    this.description,
    this.logoUrl,
    this.logoPath,
    this.isOpen,
    this.estimatedDeliveryMinutes,
    this.openingHours,
  });
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (supportPhone != null) map['support_phone'] = supportPhone;
    if (supportEmail != null) map['support_email'] = supportEmail;
    if (description != null) map['description'] = description;
    if (isOpen != null) map['is_open'] = isOpen;
    if (estimatedDeliveryMinutes != null) {
      map['estimated_delivery_minutes'] = estimatedDeliveryMinutes;
    }
    if (openingHours != null) map['opening_hours'] = openingHours;
    return map;
  }
}
