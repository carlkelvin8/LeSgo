import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';
import '../../../../provider/main/booking/restaurant_detail_provider.dart';
import '../../../../provider/main/booking/checkout_provider.dart';
import '../../../../provider/main/favorites/favorites_provider.dart';
import '../../reviews/reviews_list_screen.dart';
import '../../../../../core/navigation/favorite_navigation.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref
          .read(restaurantDetailProvider.notifier)
          .loadRestaurantDetails(
            widget.restaurant.id,
            widget.restaurant.categories,
            restaurantName: widget.restaurant.name,
          );
      final isFav = await ref
          .read(favoritesProvider.notifier)
          .isFavoriteRestaurant(widget.restaurant.id);
      if (mounted) setState(() => _isFavorite = isFav);
    });
  }

  Future<void> _toggleFavorite() async {
    final isFav = await ref.read(favoritesProvider.notifier).toggleFavoriteRestaurant(
          id: widget.restaurant.id,
          name: widget.restaurant.name,
          subtitle: widget.restaurant.address,
          imageUrl: widget.restaurant.imagePath,
          metadata: FavoriteNavigation.restaurantMetadata(widget.restaurant),
        );
    if (mounted) setState(() => _isFavorite = isFav);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(restaurantDetailProvider);
    final detailNotifier = ref.read(restaurantDetailProvider.notifier);
    final headerHeight = ResponsiveUtils.imageHeight(context, 240);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.black,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: detailState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Restaurant Header with Image
                    RestaurantDetailHeader(
                      restaurant: widget.restaurant,
                      imagePath: detailState.restaurantImagePath,
                      height: headerHeight,
                    ),

                    // Category Filters - Add padding to account for overlapping card
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.spacing(
                          context,
                          36,
                        ), // Space for overlapping card
                      ),
                      child: MenuCategoryFilters(
                        categories: detailState.menuCategories,
                        selectedCategoryId: detailState.selectedCategoryId,
                        onCategorySelected: (categoryId) {
                          detailNotifier.selectCategory(categoryId);
                        },
                      ),
                    ),

                    // Sticky Header (Popular or Category)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                        vertical: ResponsiveUtils.spacing(context, 12),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child:
                            (detailState.selectedCategoryId == 'popular' ||
                                detailState.selectedCategoryId == null)
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: ResponsiveUtils.fontSize(context, 20),
                                    color: Colors.orange,
                                  ),
                                  SizedBox(
                                    width: ResponsiveUtils.spacing(context, 8),
                                  ),
                                  Text(
                                    'Popular Items',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(
                                        context,
                                        20,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                detailState.selectedCategoryName ?? 'Items',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    20,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ),

                    // Menu Items List
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: ResponsiveUtils.horizontalPadding(context),
                          right: ResponsiveUtils.horizontalPadding(context),
                          bottom: ResponsiveUtils.spacing(context, 16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (detailState.selectedCategoryId == 'popular' ||
                                detailState.selectedCategoryId == null)
                              PopularItemsSection(
                                items: detailState.filteredMenuItems,
                                onAddToCart: (item) {
                                  detailNotifier.addToCart(item);
                                },
                                onItemTap: (item) {
                                  AppRouter.push(
                                    context,
                                    BookingRoutes.leseatMenuItemDetail,
                                    arguments: item,
                                  );
                                },
                              )
                            else
                              MenuItemsSection(
                                items: detailState.filteredMenuItems,
                                categoryName: detailState.selectedCategoryName,
                                onAddToCart: (item) {
                                  detailNotifier.addToCart(item);
                                },
                                onItemTap: (item) {
                                  AppRouter.push(
                                    context,
                                    BookingRoutes.leseatMenuItemDetail,
                                    arguments: item,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Restaurant Info Card - Positioned to overlay middle of header
                // Top edge at middle of header, extends down into body
                Positioned(
                  top:
                      headerHeight *
                      0.45, // Adjusted to match LesBuy StoreDetailScreen
                  left: ResponsiveUtils.horizontalPadding(context),
                  right: ResponsiveUtils.horizontalPadding(context),
                  child: RestaurantInfoCard(
                    restaurant: widget.restaurant,
                    onViewReviews: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsListScreen(
                            title: 'Restaurant Reviews',
                            reviewableType: 'partner',
                            reviewableId:
                                int.tryParse(widget.restaurant.id) ?? 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: detailState.cartItems.isNotEmpty
          ? RestaurantCartBar(
              itemCount: detailState.cartItemCount,
              total: detailState.cartTotal,
              onViewCart: () async {
                await ref
                    .read(checkoutProvider.notifier)
                    .initializeFromCart(widget.restaurant.name);
                if (!context.mounted) return;
                AppRouter.push(context, BookingRoutes.leseatCheckout);
              },
            )
          : null,
    );
  }
}
