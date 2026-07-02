import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../food_detail_screen.dart';

class MerchantBookView extends ConsumerWidget {
  const MerchantBookView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final menuAsync = ref.watch(merchantMenuProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredItems = ref.watch(filteredMenuItemsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
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
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
          menuAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading categories: $error'),
            ),
            data: (menu) {
              if (menu == null || menu.categories.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No categories available'),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...menu.categories.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          right: ResponsiveUtils.spacing(context, 8),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state =
                                selectedCategory == entry.value.id
                                    ? null
                                    : entry.value.id;
                          },
                          child: MerchantFoodCategoryChip(
                            label: entry.value.name,
                            icon: entry.value.iconEmoji ?? '🍽️',
                            imageUrl: entry.value.imageUrl,
                            isSelected: selectedCategory == entry.value.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          const Divider(height: 1, color: Color(0xFFE4E4E7)),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedCategory != null
                              ? 'No items in this category'
                              : 'Add items to your menu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.only(
                        bottom: ResponsiveUtils.spacing(context, 16)),
                    itemCount: filteredItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: ResponsiveUtils.spacing(context, 14),
                      crossAxisSpacing: ResponsiveUtils.spacing(context, 8),
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return MerchantFoodGridItem(
                        name: item.name,
                        imagePath: item.imageUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailScreen(
                                foodName: item.name,
                                foodImage: item.imageUrl,
                                price: 'PHP ${item.price.toStringAsFixed(2)}',
                                description: item.description ?? '',
                                sizes: item.options?['sizes'] != null
                                    ? List<String>.from(item.options!['sizes'])
                                    : ['Regular'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
