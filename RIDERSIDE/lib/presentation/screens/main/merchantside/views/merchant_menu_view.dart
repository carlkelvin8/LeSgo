import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/screen_auto_refresh.dart';
import '../../../../mixins/auto_refresh_mixin.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../provider/main/merchantside/merchant_inventory_provider.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../widgets/main/merchantside/menu/merchant_low_stock_banner.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_inventory_badge.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_stock_controls.dart';
import 'dart:convert';

import '../merchant_menu_add_category_screen.dart';
import '../merchant_menu_edit_item_screen.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_duplicate.dart';
import '../../../../../data/data_source/dto/merchant/menu_item_dto.dart';

class MerchantMenuView extends ConsumerStatefulWidget {
  const MerchantMenuView({super.key});

  @override
  ConsumerState<MerchantMenuView> createState() => _MerchantMenuViewState();
}

class _MerchantMenuViewState extends ConsumerState<MerchantMenuView>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    refreshMerchantScreen(ref, MerchantNavType.menu, silent: true);
  }

  Future<void> _refreshMenu() async {
    ref.invalidate(merchantMenuProvider);
    ref.invalidate(merchantMenuItemsProvider);
    await ref.read(merchantMenuProvider.future);
  }

  String _categoryName(List<MenuCategoryDto> categories, int? categoryId) {
    if (categoryId == null) return 'Unknown';
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Unknown';
  }

  MenuCategoryDto? _categoryById(List<MenuCategoryDto> categories, int? categoryId) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  Widget _buildInventoryFilters(BuildContext context) {
    final selected = ref.watch(merchantInventoryFilterProvider);

    Widget chip(MerchantInventoryFilter filter, String label) {
      final isSelected = selected == filter;
      return FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.fontSize(context, 11),
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          ref.read(merchantInventoryFilterProvider.notifier).state = filter;
        },
        selectedColor: const Color(0xFFE8D9F5),
        checkmarkColor: const Color(0xFF5F2D82),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade300,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(MerchantInventoryFilter.all, 'All'),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          chip(MerchantInventoryFilter.inStock, 'In Stock'),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          chip(MerchantInventoryFilter.lowStock, 'Low Stock'),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          chip(MerchantInventoryFilter.soldOut, 'Sold Out'),
        ],
      ),
    );
  }

  Future<void> _openEditCategory(MenuCategoryDto category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantMenuAddCategoryScreen(editingCategory: category),
      ),
    );
    await _refreshMenu();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final menuAsync = ref.watch(merchantMenuProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return RefreshIndicator(
      onRefresh: _refreshMenu,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveUtils.spacing(context, 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            menuAsync.when(
              data: (menu) {
                final selectedCategoryDto = menu == null
                    ? null
                    : _categoryById(menu.categories, selectedCategory);

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Food Category',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (selectedCategoryDto != null)
                      TextButton.icon(
                        onPressed: () => _openEditCategory(selectedCategoryDto),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: ResponsiveUtils.fontSize(context, 16),
                          color: const Color(0xFF5F2D82),
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => Text(
                'Food Category',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              error: (error, stack) => Text(
                'Food Category',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            menuAsync.when(
              data: (menu) {
                if (menu == null || menu.categories.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: ResponsiveUtils.spacing(context, 10),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state =
                                null;
                          },
                          child: MerchantFoodCategoryChip(
                            label: 'All',
                            icon: '🍽️',
                            isSelected: selectedCategory == null,
                          ),
                        ),
                      ),
                      ...menu.categories.map(
                        (category) => Padding(
                          padding: EdgeInsets.only(
                            right: ResponsiveUtils.spacing(context, 10),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(selectedCategoryProvider.notifier).state =
                                  category.id;
                            },
                            onLongPress: () => _openEditCategory(category),
                            child: MerchantFoodCategoryChip(
                              label: category.name,
                              icon: category.iconEmoji ?? '🍴',
                              imageUrl: category.imageUrl,
                              isSelected: selectedCategory == category.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading categories: $error'),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 14)),
            const Divider(height: 1, color: Color(0xFFE4E4E7)),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            const MerchantLowStockBanner(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Food Menu',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            _buildInventoryFilters(context),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: menuAsync.when(
                data: (menu) {
                  if (menu == null) {
                    return const Center(child: Text('No menu data available'));
                  }

                  final List<MenuItemDto> allItems = [
                    for (final category in menu.categories)
                      ...?category.availableItems,
                  ];

                  final inventoryFilter = ref.watch(merchantInventoryFilterProvider);

                  List<MenuItemDto> filteredItems = selectedCategory == null
                      ? allItems
                      : allItems
                          .where((item) => item.menuCategoryId == selectedCategory)
                          .toList();

                  filteredItems = filterMenuItemsByInventory(
                    filteredItems,
                    inventoryFilter,
                  );

                  if (filteredItems.isEmpty) {
                    return const Center(child: Text('No menu items found'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveUtils.spacing(context, 14),
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final categoryName =
                          _categoryName(menu.categories, item.menuCategoryId);

                      return MerchantMenuItemCard(
                        name: item.name,
                        description: item.description ?? '',
                        price: item.price.toStringAsFixed(2),
                        category: categoryName,
                        imageUrl: item.imageUrl,
                        inventoryBadge: MerchantMenuInventoryBadge(item: item),
                        stockControls: MerchantMenuStockControls(
                          item: item,
                          onStockChanged: (newStock) async {
                            try {
                              await updateMerchantItemStock(
                                ref,
                                item: item,
                                newStock: newStock,
                              );
                              await _refreshMenu();
                            } catch (e) {
                              if (mounted) {
                                SnackBarUtils.showError(
                                  context,
                                  'Failed to update stock: $e',
                                );
                              }
                            }
                          },
                        ),
                        onEditTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MerchantMenuEditItemScreen(
                                initialItem: menuItemToEditFormMap(
                                  item,
                                  categoryName: categoryName,
                                  encodeOptions: jsonEncode,
                                ),
                              ),
                            ),
                          );
                          await _refreshMenu();
                        },
                        onDeleteTap: () => confirmAndDeleteMerchantMenuItem(
                          context,
                          ref,
                          itemId: item.id,
                          itemName: item.name,
                        ),
                        onDuplicateTap: () async {
                          await duplicateMerchantMenuItem(
                            context,
                            ref,
                            item: item,
                          );
                          await _refreshMenu();
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading menu: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshMenu,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
