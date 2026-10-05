import 'package:lesgo/core/theme/app_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(restaurantDetailProvider.notifier)
            .loadRestaurantDetails(
              widget.restaurant.id,
              widget.restaurant.categories,
              restaurantName: widget.restaurant.name,
            );
        ref
            .read(favoritesProvider.notifier)
            .isFavoriteRestaurant(widget.restaurant.id)
            .then((isFav) {
              if (mounted) setState(() => _isFavorite = isFav);
            });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    final isFav = await ref
        .read(favoritesProvider.notifier)
        .toggleFavoriteRestaurant(
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
    final headerHeight = ResponsiveUtils.imageHeight(context, 200);

    return Scaffold(
      backgroundColor: AppColors.surface(context, Color(0xFFFEFDFE)),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.white),
        elevation: 0,
        surfaceTintColor: AppColors.surface(context, Colors.white),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.foreground(context, Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.white),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? Colors.red
                    : AppColors.foreground(context, Colors.black87),
              ),
              onPressed: _toggleFavorite,
              padding: EdgeInsets.zero,
            ),
          ),
          // Cart button with badge
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context, Colors.white),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.foreground(context, Colors.black87),
                    ),
                    onPressed: detailState.cartItems.isNotEmpty
                        ? () async {
                            await ref
                                .read(checkoutProvider.notifier)
                                .initializeFromCart(widget.restaurant.name);
                            if (!context.mounted) return;
                            AppRouter.push(
                              context,
                              BookingRoutes.leseatCheckout,
                            );
                          }
                        : null,
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (detailState.cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent(context, Color(0xFF5F2D82)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${detailState.cartItemCount > 99 ? '99+' : detailState.cartItemCount}',
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: detailState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Restaurant Header Image
                RestaurantDetailHeader(
                  restaurant: widget.restaurant,
                  imagePath: detailState.restaurantImagePath,
                  height: headerHeight,
                ),

                // Restaurant Info Section (Compact)
                Container(
                  color: AppColors.surface(context, Colors.white),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurant.name,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground(
                            context,
                            Color(0xFF25232B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (widget.restaurant.rating > 0) ...[
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFA726),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.restaurant.rating.toStringAsFixed(1)} (${widget.restaurant.reviewCount})',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13,
                                color: AppColors.foreground(
                                  context,
                                  Color(0xFF69626F),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (widget.restaurant.deliveryTime != null) ...[
                            Icon(
                              Icons.access_time,
                              color: AppColors.foreground(
                                context,
                                Color(0xFF69626F),
                              ),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.restaurant.deliveryTime!,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13,
                                color: AppColors.foreground(
                                  context,
                                  Color(0xFF69626F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Header with Title and Search
                Container(
                  color: AppColors.surface(context, const Color(0xFFFEFDFE)),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground(
                            context,
                            Color(0xFF25232B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your favorites',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          color: AppColors.foreground(
                            context,
                            Color(0xFF89858E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context, Color(0xFFF5F4F7)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border(context, Color(0xFFECEAF0)),
                          ),
                        ),
                        child: TextField(
                          onChanged: (query) {
                            detailNotifier.updateSearchQuery(query);
                          },
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            color: AppColors.foreground(
                              context,
                              Color(0xFF302B36),
                            ),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search menu items...',
                            hintStyle: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 14,
                              color: AppColors.foreground(
                                context,
                                Color(0xFF918A98),
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.foreground(
                                context,
                                Color(0xFF918A98),
                              ),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filters
                MenuCategoryFilters(
                  categories: detailState.menuCategories,
                  selectedCategoryId: detailState.selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    detailNotifier.selectCategory(categoryId);
                  },
                ),

                // Menu Items List
                Expanded(
                  child: detailState.filteredMenuItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  detailState.searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.restaurant_menu,
                                  size: 64,
                                  color: AppColors.foreground(
                                    context,
                                    Colors.grey[300]!,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  detailState.searchQuery.isNotEmpty
                                      ? 'No products found'
                                      : 'No menu items available',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground(
                                      context,
                                      Color(0xFF69626F),
                                    ),
                                  ),
                                ),
                                if (detailState.searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 13,
                                      color: AppColors.foreground(
                                        context,
                                        Color(0xFF918A98),
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                  categoryName:
                                      detailState.selectedCategoryName,
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
