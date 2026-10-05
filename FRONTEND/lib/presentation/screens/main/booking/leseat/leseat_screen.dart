import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/widgets.dart';
import '../../../../provider/main/booking/leseat/leseat_provider.dart';
import '../../../../provider/main/booking/controller/leseat.controller.notifier.dart';
import '../../../../provider/main/profile/profile_provider.dart';

import '../../../../provider/main/booking/checkout_provider.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';

class LeseatScreen extends ConsumerStatefulWidget {
  const LeseatScreen({super.key});

  @override
  ConsumerState<LeseatScreen> createState() => _LeseatScreenState();
}

class _LeseatScreenState extends ConsumerState<LeseatScreen> {
  late final LeseatControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = LeseatControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leseatState = ref.watch(leseatProvider);
    final leseatNotifier = ref.read(leseatProvider.notifier);
    final profileState = ref.watch(profileProvider);

    final userName = profileState.name.isNotEmpty ? profileState.name : 'Guest';

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      appBar: BookingServiceHeader(
        title: 'LesEat',
        action: IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: Color(0xFFA930D0),
            size: 28,
          ),
          onPressed: () async {
            await ref
                .read(checkoutProvider.notifier)
                .initializeFromCart('Restaurant');
            if (!context.mounted) return;
            AppRouter.push(context, BookingRoutes.leseatCheckout);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 4)),

            // Location Header
            BookingLocationHeader(userName: userName),

            SizedBox(height: ResponsiveUtils.spacing(context, 10)),

            // Search Field
            LeseatSearchField(
              controller: _controllers.searchController,
              onChanged: (value) => leseatNotifier.updateSearchQuery(value),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 10)),

            // Categories
            CategoryListSection(
              categories: leseatState.categories,
              selectedCategoryId: leseatState.selectedCategoryId,
              onCategorySelected: (categoryId) {
                leseatNotifier.selectCategory(categoryId);
              },
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 2)),

            // Banner
            LeseatBanner(
              onTap: () => AppRouter.push(context, MainRoutes.offers),
            ),

            // Section Header
            const SectionHeader(title: 'Explore restaurants'),

            SizedBox(height: ResponsiveUtils.spacing(context, 8)),

            // Restaurant List
            Expanded(
              child: RestaurantListSection(
                restaurants: leseatState.filteredRestaurants,
                onRestaurantTap: (restaurant) {
                  AppRouter.push(
                    context,
                    BookingRoutes.leseatRestaurantDetail,
                    arguments: restaurant,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
