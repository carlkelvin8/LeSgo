import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
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
      final data = response.data['data'] ?? response.data;
      
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
  
  /// Update order status
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await _dio.patch('/v1/orders/$orderId/status', data: {'status': status});
    } catch (e) {
      throw Exception('Failed to update order status: ${ApiService.extractError(e)}');
    }
  }
  
  /// Create menu item
  Future<MenuItemDto> createMenuItem(int partnerId, CreateMenuItemRequest request) async {
    try {
      dynamic data;
      
      if (request.imagePath != null) {
        // Use FormData for file upload
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
        '/v1/partners/$partnerId/menu-items',
        data: data,
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
      dynamic data;
      
      if (request.imagePath != null) {
        // Use FormData for file upload
        // For PATCH with files in Laravel, we need to spoof it via POST with _method=PATCH
        final map = request.toJson();
        map['_method'] = 'PATCH';
        final formData = FormData.fromMap(map);
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(request.imagePath!),
        ));
        data = formData;
        
        final response = await _dio.post(
          '/v1/menu-items/$itemId',
          data: data,
        );
        final responseData = response.data['data'] ?? response.data;
        return MenuItemDto.fromJson(responseData as Map<String, dynamic>);
      } else {
        data = request.toJson();
        final response = await _dio.patch(
          '/v1/menu-items/$itemId',
          data: data,
        );
        final responseData = response.data['data'] ?? response.data;
        return MenuItemDto.fromJson(responseData as Map<String, dynamic>);
      }
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
      final response = await _dio.post(
        '/v1/partners/$partnerId/menu-categories',
        data: request.toJson(),
      );
      final data = response.data['data'] ?? response.data;
      return MenuCategoryDto.fromJson(data as Map<String, dynamic>);
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
      final response = await _dio.patch(
        '/v1/partners/$partnerId',
        data: request.toJson(),
      );
      final data = response.data['data'] ?? response.data;
      return PartnerDto.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update partner profile: ${ApiService.extractError(e)}');
    }
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
  final String? imagePath; // Added for file upload
  final bool isAvailable;
  
  CreateMenuItemRequest({
    required this.menuCategoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'menu_category_id': menuCategoryId,
    'name': name,
    if (description != null) 'description': description,
    'price': price,
    if (imageUrl != null) 'image_url': imageUrl,
    'is_available': isAvailable ? 1 : 0, // Form data requires integer/string for booleans in Laravel sometimes
  };
}

class UpdateMenuItemRequest {
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? imagePath; // Added for file upload
  final bool? isAvailable;
  
  UpdateMenuItemRequest({
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.imagePath,
    this.isAvailable,
  });
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (isAvailable != null) map['is_available'] = isAvailable! ? 1 : 0;
    return map;
  }
}

class CreateMenuCategoryRequest {
  final String name;
  final String? iconEmoji;
  final int? sortOrder;
  
  CreateMenuCategoryRequest({
    required this.name,
    this.iconEmoji,
    this.sortOrder,
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
  final bool? isOpen;
  
  UpdatePartnerRequest({
    this.name,
    this.supportPhone,
    this.supportEmail,
    this.description,
    this.isOpen,
  });
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (supportPhone != null) map['support_phone'] = supportPhone;
    if (supportEmail != null) map['support_email'] = supportEmail;
    if (description != null) map['description'] = description;
    if (isOpen != null) map['is_open'] = isOpen;
    return map;
  }
}
