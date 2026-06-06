import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import 'dart:convert';

import '../merchant_menu_edit_item_screen.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';

class MerchantMenuView extends ConsumerWidget {
  const MerchantMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final menuAsync = ref.watch(merchantMenuProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food Category',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          
          // Categories
          menuAsync.when(
            data: (menu) {
              if (menu == null || menu.categories.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" category
                    Padding(
                      padding: EdgeInsets.only(
                        right: ResponsiveUtils.spacing(context, 10),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                        child: MerchantFoodCategoryChip(
                          label: 'All',
                          icon: '🍽️',
                          isSelected: selectedCategory == null,
                        ),
                      ),
                    ),
                    // Category chips
                    ...menu.categories.map(
                      (category) => Padding(
                        padding: EdgeInsets.only(
                          right: ResponsiveUtils.spacing(context, 10),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state = category.id;
                          },
                          child: MerchantFoodCategoryChip(
                            label: category.name,
                            icon: category.iconEmoji ?? '🍴',
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
          Text(
            'Food Menu',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          
          // Menu Items
          Expanded(
            child: menuAsync.when(
              data: (menu) {
                if (menu == null) {
                  return const Center(child: Text('No menu data available'));
                }
                
                // Get filtered items
                final allItems = menu.categories
                    .expand((cat) => cat.availableItems ?? [])
                    .toList();
                
                final filteredItems = selectedCategory == null
                    ? allItems
                    : allItems.where((item) => item.menuCategoryId == selectedCategory).toList();
                
                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No menu items found'));
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(merchantMenuProvider);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 14)),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return MerchantMenuItemCard(
                        name: item.name,
                        description: item.description ?? '',
                        price: item.price.toStringAsFixed(2),
                        category: menu.categories
                            .firstWhere((cat) => cat.id == item.menuCategoryId)
                            .name,
                        imageUrl: item.imageUrl,
                        onEditTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MerchantMenuEditItemScreen(
                                initialItem: {
                                  'id': item.id.toString(),
                                  'menuCategoryId': item.menuCategoryId.toString(),
                                  'name': item.name,
                                  'description': item.description ?? '',
                                  'price': item.price.toStringAsFixed(2),
                                  'category': menu.categories
                                      .firstWhere((cat) => cat.id == item.menuCategoryId)
                                      .name,
                                  if (item.imageUrl != null) 'imageUrl': item.imageUrl!,
                                  if (item.tags != null && item.tags!.isNotEmpty)
                                    'selectedTags': item.tags!.join(','),
                                  if (item.options != null && item.options!.isNotEmpty)
                                    'optionsJson': jsonEncode(item.options),
                                },
                              ),
                            ),
                          );
                        },
                        onDeleteTap: () => confirmAndDeleteMerchantMenuItem(
                          context,
                          ref,
                          itemId: item.id,
                          itemName: item.name,
                        ),
                      );
                    },
                  ),
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
                      onPressed: () {
                        ref.invalidate(merchantMenuProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}