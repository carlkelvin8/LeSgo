# 🏪 Merchant API Integration Implementation Plan

## 📋 Overview

Currently, the merchant side uses fake/placeholder data from `fakedata.dart`. This plan outlines how to integrate real API data.

---

## 🎯 Goals

1. ✅ Fetch real menu items from database
2. ✅ Fetch real orders assigned to merchant
3. ✅ Fetch real partner profile data
4. ✅ Enable real-time order management
5. ✅ Support menu item CRUD operations

---

## 📊 Current State vs Target State

### Current (Fake Data):
```dart
// RIDERSIDE/lib/presentation/provider/main/merchantside/merchant_orders_provider.dart
import '../../../../../core/utils/helpers/fakedata.dart';  // ❌ Fake

final merchantOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return merchantFoodMenuItems.asMap()...  // ❌ Hardcoded
});
```

### Target (Real API):
```dart
// New: RIDERSIDE/lib/data/data_source/merchant_remote_datasource.dart
class MerchantRemoteDataSource {
  Future<List<MenuItemDto>> getMenuItems(int partnerId);
  Future<List<OrderDto>> getPartnerOrders(int partnerId);
  Future<PartnerDto> getPartnerProfile(int partnerId);
}
```

---

## 🏗️ Implementation Steps

### Phase 1: Backend API Verification ✅

**Check existing endpoints:**
- `GET /api/v1/partners/{id}/menu` - Get menu items
- `GET /api/v1/orders?partner_id={id}` - Get partner orders
- `GET /api/v1/partners/{id}` - Get partner profile

**Status:** ✅ Already implemented in backend

---

### Phase 2: Create Data Layer

#### 2.1 Create DTOs

**File:** `RIDERSIDE/lib/data/data_source/dto/merchant/menu_item_dto.dart`
```dart
import 'package:json_annotation/json_annotation.dart';

part 'menu_item_dto.g.dart';

@JsonSerializable()
class MenuItemDto {
  final int id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'menu_category_id')
  final int menuCategoryId;
  @JsonKey(name: 'category_name')
  final String? categoryName;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  final List<String>? sizes;
  
  MenuItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.menuCategoryId,
    this.categoryName,
    this.imageUrl,
    required this.isAvailable,
    this.sizes,
  });
  
  factory MenuItemDto.fromJson(Map<String, dynamic> json) => 
      _$MenuItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemDtoToJson(this);
}
```

**File:** `RIDERSIDE/lib/data/data_source/dto/merchant/menu_category_dto.dart`
```dart
@JsonSerializable()
class MenuCategoryDto {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  
  // Constructor and methods...
}
```

**File:** `RIDERSIDE/lib/data/data_source/dto/merchant/partner_dto.dart`
```dart
@JsonSerializable()
class PartnerDto {
  final int id;
  final String name;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? slug;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final String? description;
  final String? category;
  @JsonKey(name: 'support_phone')
  final String? supportPhone;
  @JsonKey(name: 'support_email')
  final String? supportEmail;
  final double? rating;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  
  // Constructor and methods...
}
```

#### 2.2 Create Remote Data Source

**File:** `RIDERSIDE/lib/data/data_source/merchant_remote_datasource.dart`
```dart
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import 'dto/merchant/menu_item_dto.dart';
import 'dto/merchant/menu_category_dto.dart';
import 'dto/merchant/partner_dto.dart';
import 'dto/order/order_dto.dart';

class MerchantRemoteDataSource {
  final Dio _dio = ApiService.dio;
  
  /// Get partner profile
  Future<PartnerDto> getPartnerProfile(int partnerId) async {
    try {
      final response = await _dio.get('/partners/$partnerId');
      return PartnerDto.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to fetch partner profile: $e');
    }
  }
  
  /// Get menu categories for partner
  Future<List<MenuCategoryDto>> getMenuCategories(int partnerId) async {
    try {
      final response = await _dio.get('/partners/$partnerId/menu-categories');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => MenuCategoryDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu categories: $e');
    }
  }
  
  /// Get menu items for partner
  Future<List<MenuItemDto>> getMenuItems(int partnerId) async {
    try {
      final response = await _dio.get('/partners/$partnerId/menu');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => MenuItemDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu items: $e');
    }
  }
  
  /// Get orders for partner
  Future<List<OrderDto>> getPartnerOrders(int partnerId, {String? status}) async {
    try {
      final queryParams = {
        'partner_id': partnerId,
        if (status != null) 'status': status,
      };
      final response = await _dio.get('/orders', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => OrderDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch partner orders: $e');
    }
  }
  
  /// Update order status
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await _dio.patch('/orders/$orderId/status', data: {'status': status});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
```

---

### Phase 3: Create Providers

#### 3.1 Partner Profile Provider

**File:** `RIDERSIDE/lib/presentation/provider/main/merchantside/merchant_profile_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../data/data_source/dto/merchant/partner_dto.dart';
import '../../auth/rider_auth_provider.dart';

final merchantDataSourceProvider = Provider((ref) => MerchantRemoteDataSource());

final merchantProfileProvider = FutureProvider<PartnerDto?>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  
  if (partnerId == null) return null;
  
  final dataSource = ref.read(merchantDataSourceProvider);
  return await dataSource.getPartnerProfile(partnerId);
});
```

#### 3.2 Menu Items Provider

**File:** `RIDERSIDE/lib/presentation/provider/main/merchantside/merchant_menu_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../data/data_source/dto/merchant/menu_category_dto.dart';
import '../../auth/rider_auth_provider.dart';

final merchantMenuCategoriesProvider = FutureProvider<List<MenuCategoryDto>>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  
  if (partnerId == null) return [];
  
  final dataSource = ref.read(merchantDataSourceProvider);
  return await dataSource.getMenuCategories(partnerId);
});

final merchantMenuItemsProvider = FutureProvider<List<MenuItemDto>>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  
  if (partnerId == null) return [];
  
  final dataSource = ref.read(merchantDataSourceProvider);
  return await dataSource.getMenuItems(partnerId);
});

// Filter by category
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final filteredMenuItemsProvider = Provider<List<MenuItemDto>>((ref) {
  final menuItems = ref.watch(merchantMenuItemsProvider).value ?? [];
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  if (selectedCategory == null) return menuItems;
  
  return menuItems.where((item) => item.menuCategoryId == selectedCategory).toList();
});
```

#### 3.3 Orders Provider (Replace existing)

**File:** `RIDERSIDE/lib/presentation/provider/main/merchantside/merchant_orders_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../data/data_source/dto/order/order_dto.dart';
import '../../auth/rider_auth_provider.dart';

enum MerchantOrderFilter { all, pending, pickUp, forDelivery, delivered }

extension MerchantOrderFilterX on MerchantOrderFilter {
  String get label {
    switch (this) {
      case MerchantOrderFilter.all: return 'All';
      case MerchantOrderFilter.pending: return 'Pending';
      case MerchantOrderFilter.pickUp: return 'For Pick Up';
      case MerchantOrderFilter.forDelivery: return 'For Delivery';
      case MerchantOrderFilter.delivered: return 'Delivered';
    }
  }
  
  String? get apiStatus {
    switch (this) {
      case MerchantOrderFilter.all: return null;
      case MerchantOrderFilter.pending: return 'pending';
      case MerchantOrderFilter.pickUp: return 'accepted';
      case MerchantOrderFilter.forDelivery: return 'picked_up';
      case MerchantOrderFilter.delivered: return 'completed';
    }
  }
}

final selectedMerchantOrderFilterProvider = StateProvider<MerchantOrderFilter>((ref) {
  return MerchantOrderFilter.all;
});

final merchantOrdersProvider = FutureProvider<List<OrderDto>>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  final filter = ref.watch(selectedMerchantOrderFilterProvider);
  
  if (partnerId == null) return [];
  
  final dataSource = ref.read(merchantDataSourceProvider);
  return await dataSource.getPartnerOrders(partnerId, status: filter.apiStatus);
});
```

---

### Phase 4: Update UI Views

#### 4.1 Update Profile View

**File:** `RIDERSIDE/lib/presentation/screens/main/merchantside/views/merchant_profile_view.dart`

Replace fake data with:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final profileAsync = ref.watch(merchantProfileProvider);
  final menuItemsAsync = ref.watch(merchantMenuItemsProvider);
  
  return profileAsync.when(
    loading: () => Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
    data: (profile) {
      if (profile == null) return Center(child: Text('No profile found'));
      
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 18),
        child: Column(
          children: [
            // Display real profile data
            Text(profile.name),
            Text(profile.supportPhone ?? ''),
            // ... rest of UI
            
            // Display real menu items
            menuItemsAsync.when(
              loading: () => CircularProgressIndicator(),
              error: (e, s) => Text('Error loading menu'),
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MerchantMenuItemCard(
                    name: item.name,
                    description: item.description,
                    price: item.price.toStringAsFixed(2),
                    category: item.categoryName,
                    onEditTap: () => // Navigate to edit
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

#### 4.2 Update Book View

**File:** `RIDERSIDE/lib/presentation/screens/main/merchantside/views/merchant_book_view.dart`

Replace with real data fetching.

#### 4.3 Update Orders View

**File:** `RIDERSIDE/lib/presentation/screens/main/merchantside/views/merchant_orders_view.dart`

Replace with real orders from API.

---

## 🔧 Additional Requirements

### 1. Update User Model

Add `partnerId` to user model:
```dart
class User {
  final int? partnerId;  // Add this field
  // ... other fields
}
```

### 2. Update Auth Response

Ensure login response includes partner_id for merchant users.

### 3. Generate JSON Serialization

Run after creating DTOs:
```bash
cd RIDERSIDE
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Testing Checklist

- [ ] Login as merchant
- [ ] View profile with real data
- [ ] View menu items from database
- [ ] View real orders
- [ ] Filter orders by status
- [ ] Update order status
- [ ] Add new menu item
- [ ] Edit existing menu item
- [ ] Delete menu item

---

## 🚀 Deployment Steps

1. Implement DTOs
2. Generate JSON serialization code
3. Create data source
4. Create providers
5. Update UI views
6. Test thoroughly
7. Deploy

---

## ⏱️ Estimated Time

- **DTOs & Data Source:** 2-3 hours
- **Providers:** 2-3 hours
- **UI Updates:** 3-4 hours
- **Testing & Bug Fixes:** 2-3 hours
- **Total:** 9-13 hours

---

## 📚 Resources

- Backend API: `http://127.0.0.1:8000/api/v1/`
- API Documentation: `API_DOCUMENTATION.md`
- Existing DTOs: `FRONTEND/lib/data/data_source/dto/`
- Riverpod Docs: https://riverpod.dev

---

**This is a comprehensive plan. Implementation should be done step-by-step, testing each phase before moving to the next.**
