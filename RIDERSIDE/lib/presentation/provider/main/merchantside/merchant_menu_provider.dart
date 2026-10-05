import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';

/// Deletes a menu item and refreshes menu providers.
Future<void> deleteMerchantMenuItem(WidgetRef ref, int itemId) async {
  final dataSource = ref.read(merchantDataSourceProvider);
  try {
    await dataSource.deleteMenuItem(itemId);
    ref.invalidate(merchantMenuProvider);
    ref.invalidate(merchantMenuItemsProvider);
  } catch (e) {
    throw Exception(ApiService.extractError(e));
  }
}

/// Provider for menu categories with items
final merchantMenuProvider = FutureProvider.autoDispose<MenuResponse?>((ref) async {
  // Get partner_id from auth state
  final authState = ref.watch(riderAuthProvider);
  final profile = ref.watch(merchantProfileProvider).value;
  final partnerId = authState.user?.partnerId ?? profile?.id;

  if (partnerId == null) {
    AppLogger.warn('merchantMenuProvider - No partner_id available');
    return null;
  }
  
  AppLogger.debug('📋 merchantMenuProvider - Using partner_id: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final menu = await dataSource.getMerchantMenu(partnerId);
    AppLogger.debug('✅ Loaded menu with ${menu.categories.length} categories');
    return menu;
  } catch (e) {
    AppLogger.error('Error loading menu', e);
    rethrow;
  }
});

/// Provider for flattened list of all menu items
final merchantMenuItemsProvider = FutureProvider.autoDispose<List<MenuItemDto>>((ref) async {
  // Get partner_id from auth state
  final authState = ref.watch(riderAuthProvider);
  final profile = ref.watch(merchantProfileProvider).value;
  final partnerId = authState.user?.partnerId ?? profile?.id;

  if (partnerId == null) {
    AppLogger.warn('merchantMenuItemsProvider - No partner_id available');
    return [];
  }
  
  AppLogger.debug('📋 merchantMenuItemsProvider - Using partner_id: $partnerId');
  
  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final items = await dataSource.getMenuItems(partnerId);
    AppLogger.debug('✅ Loaded ${items.length} menu items');
    return items;
  } catch (e) {
    AppLogger.error('Error loading menu items', e);
    rethrow;
  }
});

/// Provider for selected category filter
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

/// Provider for search query
final merchantMenuSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered menu items by category and search
final filteredMenuItemsProvider = Provider<List<MenuItemDto>>((ref) {
  final menuItemsAsync = ref.watch(merchantMenuItemsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(merchantMenuSearchQueryProvider);
  
  return menuItemsAsync.when(
    data: (items) {
      var filtered = items;
      
      // Filter by search query first (if not empty)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((item) {
          final name = item.name.toLowerCase();
          final desc = (item.description ?? '').toLowerCase();
          return name.contains(query) || desc.contains(query);
        }).toList();
      } else if (selectedCategory != null) {
        // Only filter by category if no search query
        filtered = filtered.where((item) => item.menuCategoryId == selectedCategory).toList();
      }
      
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
