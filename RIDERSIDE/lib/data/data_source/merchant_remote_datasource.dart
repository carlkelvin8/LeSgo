import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/media_url_utils.dart';
import '../../core/utils/menu_image_utils.dart';
import '../../core/utils/multipart_file_utils.dart';
import 'dto/merchant/menu_item_dto.dart';
import 'dto/merchant/partner_dto.dart';
import 'dto/merchant/order_dto.dart';

class MerchantRemoteDataSource {
  final Dio _dio = ApiService.dio;
  
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
  Future<MenuResponse> getMenu(int partnerId) async {
    try {
      final response = await _dio.get('/v1/partners/$partnerId/menu');
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
  
  /// Get all menu items for a partner (flattened list)
  Future<List<MenuItemDto>> getMenuItems(int partnerId) async {
    try {
      final menuResponse = await getMenu(partnerId);
      final items = <MenuItemDto>[];
      
      for (final category in menuResponse.categories) {
        if (category.availableItems != null) {
          items.addAll(category.availableItems!);
        }
      }
      
      return items;
    } catch (e) {
      throw Exception('Failed to fetch menu items: ${ApiService.extractError(e)}');
    }
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
      
      final response = await _dio.get('/v1/orders', queryParameters: queryParams);
      
      // Handle both paginated and non-paginated responses
      final dynamic responseData = response.data['data'];
      final List<dynamic> ordersList;
      
      if (responseData is Map && responseData.containsKey('data')) {
        // Paginated response
        ordersList = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        // Direct list response
        ordersList = responseData;
      } else {
        ordersList = [];
      }
      
      return ordersList
          .map((json) => OrderDto.fromJson(json as Map<String, dynamic>))
          .toList();
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
      dynamic data;

      if (request.imagePath != null) {
        final formData = FormData.fromMap(request.toJson());
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(request.imagePath!),
        ));
        data = formData;
      } else {
        data = request.toJson();
      }

      final response = await _dio.post(
        '/v1/partners/$partnerId/menu-categories',
        data: data,
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
      final response = await _dio.patch(
        '/v1/menu-categories/$categoryId',
        data: request.toJson(),
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

      dynamic requestData;
      if (request.logoPath != null &&
          MediaUrlUtils.isLocalFilePath(request.logoPath)) {
        final formData = FormData.fromMap(payload);
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(request.logoPath!),
        ));
        requestData = formData;
      } else {
        final uploadedLogoUrl = await _resolvePartnerLogoUrl(
          logoUrl: request.logoUrl,
          logoPath: request.logoPath,
        );
        if (uploadedLogoUrl != null && uploadedLogoUrl.isNotEmpty) {
          payload['logo_url'] = uploadedLogoUrl;
        }
        requestData = payload;
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
  final List<String>? tags;

  CreateMenuItemRequest({
    required this.menuCategoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable = true,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'menu_category_id': menuCategoryId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_available': isAvailable,
    };
    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
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
  final List<String>? tags;

  UpdateMenuItemRequest({
    this.menuCategoryId,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (menuCategoryId != null) map['menu_category_id'] = menuCategoryId;
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (isAvailable != null) map['is_available'] = isAvailable;
    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
    }
    return map;
  }
}

class CreateMenuCategoryRequest {
  final String name;
  final String? iconEmoji;
  final int? sortOrder;
  final String? imagePath;

  CreateMenuCategoryRequest({
    required this.name,
    this.iconEmoji,
    this.sortOrder,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (iconEmoji != null) 'icon_emoji': iconEmoji,
    if (sortOrder != null) 'sort_order': sortOrder,
  };
}

class UpdateMenuCategoryRequest {
  final String? name;
  final String? iconEmoji;
  final int? sortOrder;
  
  UpdateMenuCategoryRequest({
    this.name,
    this.iconEmoji,
    this.sortOrder,
  });
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (iconEmoji != null) map['icon_emoji'] = iconEmoji;
    if (sortOrder != null) map['sort_order'] = sortOrder;
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
  
  UpdatePartnerRequest({
    this.name,
    this.supportPhone,
    this.supportEmail,
    this.description,
    this.logoUrl,
    this.logoPath,
    this.isOpen,
  });
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (supportPhone != null) map['support_phone'] = supportPhone;
    if (supportEmail != null) map['support_email'] = supportEmail;
    if (description != null) map['description'] = description;
    if (isOpen != null) map['is_open'] = isOpen! ? 1 : 0;
    return map;
  }
}
