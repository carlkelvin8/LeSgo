import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../domain/entities/booking/lesbuy/store.dart';
import '../../../../provider/main/booking/lesbuy/store_detail_provider.dart';
import '../../../../provider/main/favorites/favorites_provider.dart';
import '../../../../../core/navigation/favorite_navigation.dart';
import '../../../../widgets/booking/lesbuy/store/store_detail_header.dart';
import '../../../../widgets/booking/lesbuy/store/store_info_card.dart';
import '../../../../widgets/booking/lesbuy/store/store_category_filters.dart';
import '../../../../widgets/booking/lesbuy/store/store_product_list.dart';
import '../../../../widgets/booking/lesbuy/store/store_cart_bar.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(storeDetailProvider.notifier).loadStoreDetails(
          widget.store.id,
          widget.store.categories,
        );
        ref.read(favoritesProvider.notifier).isFavoriteStore(widget.store.id).then((isFav) {
          if (mounted) setState(() => _isFavorite = isFav);
        });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    final isFav = await ref.read(favoritesProvider.notifier).toggleFavoriteStore(
          id: widget.store.id,
          name: widget.store.name,
          subtitle: widget.store.address,
          imageUrl: widget.store.imagePath,
          metadata: FavoriteNavigation.storeMetadata(widget.store),
        );
    if (mounted) setState(() => _isFavorite = isFav);
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeDetailProvider);
    final storeNotifier = ref.read(storeDetailProvider.notifier);
    
    // Exact same header height calculation as RestaurantDetailScreen
    final headerHeight = ResponsiveUtils.imageHeight(context, 340);

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
      body: storeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load products. Please try again.',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      TextButton(
                        onPressed: () {
                          ref.read(storeDetailProvider.notifier).loadStoreDetails(
                                widget.store.id,
                                widget.store.categories,
                              );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header using exact height
                    StoreDetailHeader(
                      store: widget.store,
                      height: headerHeight,
                    ),

                    // Filters with exact padding from RestaurantDetailScreen (80)
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.spacing(context, 80),
                      ),
                      child: StoreCategoryFilters(
                        categories: storeState.categories,
                        categoryLabels: storeState.categoryNames,
                        selectedCategoryId: storeState.selectedCategoryId,
                        onCategorySelected: (categoryId) {
                          storeNotifier.selectCategory(categoryId);
                        },
                      ),
                    ),
                    
                    // Category Title (Sticky)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.horizontalPadding(context),
                        vertical: ResponsiveUtils.spacing(context, 12),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: (storeState.selectedCategoryId == 'popular' || storeState.selectedCategoryId == null)
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: ResponsiveUtils.fontSize(context, 20),
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                  Text(
                                    storeState.selectedCategoryName ?? 'Popular Items',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 18),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                storeState.selectedCategoryName ?? 'Products',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 18),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ),

                    // Product List in Expanded > SingleChildScrollView
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
                            StoreProductList(
                              products: storeState.filteredProducts,
                              onAddToCart: (product) {
                                storeNotifier.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              onItemTap: (product) {
                                AppRouter.push(
                                  context, 
                                  BookingRoutes.lesbuyProductDetail,
                                  arguments: product,
                                );
                              },
                            ),
                            // Bottom padding
                            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Info Card positioned at 0.45, same as RestaurantDetailScreen
                Positioned(
                  top: headerHeight * 0.65,
                  left: ResponsiveUtils.horizontalPadding(context),
                  right: ResponsiveUtils.horizontalPadding(context),
                  child: StoreInfoCard(store: widget.store),
                ),
              ],
            ),
      bottomNavigationBar: storeState.cartItems.isNotEmpty
          ? StoreCartBar(
              itemCount: storeState.cartItemCount,
              total: storeState.cartTotal,
              onViewCart: () {
                AppRouter.push(context, BookingRoutes.lesbuyCart);
              },
            )
          : null,
    );
  }
}
