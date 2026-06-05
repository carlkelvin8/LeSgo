import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../widgets/widgets.dart';
import '../merchant_edit_information_screen.dart';
import '../merchant_menu_edit_item_screen.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';

class MerchantProfileView extends ConsumerWidget {
  const MerchantProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final profileAsync = ref.watch(merchantProfileProvider);
    final menuItemsAsync = ref.watch(merchantMenuItemsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading profile: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(merchantProfileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return const Center(
            child: Text('No merchant profile found. Please contact support.'),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: ResponsiveUtils.spacing(context, 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MerchantProfileHeader(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantProfileInfoSection(),
              SizedBox(
                height: ResponsiveUtils.spacing(context, 24),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MerchantEditInformationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFE5E5E5),
                    foregroundColor: const Color(0xFF9A9A9A),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.spacing(context, 16),
                      ),
                    ),
                  ),
                  child: Text(
                    'Edit Information',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 9),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Divider(color: Colors.grey.shade300, thickness: 1),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Row(
                children: [
                  Icon(
                    Icons.menu,
                    size: ResponsiveUtils.spacing(context, 18),
                    color: Colors.black87,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Food Menu',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(merchantNavProvider.notifier).state =
                          MerchantNavType.menu;
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: const Color(0xFF9B59F0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 14)),
              menuItemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading menu: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(merchantMenuItemsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No menu items yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items to your menu to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...items.take(5).map(
                        (item) => MerchantMenuItemCard(
                          name: item.name,
                          description: item.description ?? '',
                          price: item.price.toStringAsFixed(2),
                          category: item.category?.name ?? '',
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
                                    'category': item.category?.name ?? '',
                                    if (item.imageUrl != null)
                                      'imageUrl': item.imageUrl!,
                                    if (item.tags != null &&
                                        item.tags!.isNotEmpty)
                                      'selectedTags': item.tags!.join(','),
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
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 18)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
