import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:lesgo/presentation/widgets/common/empty_state_view.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/favorites/favorites_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/navigation/favorite_navigation.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.grey[50]!),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                children: [
                  const AuthHeader(title: 'Favorites'),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                  // Tabs
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final labels = [
                        'All (${favoritesState.totalCount})',
                        'Restaurants (${favoritesState.restaurantsCount})',
                        'Stores (${favoritesState.storesCount})',
                        'Addresses (${favoritesState.addressesCount})',
                      ];
                      final labelStyle = TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      );
                      // Tabs share the full width when their labels fit;
                      // otherwise they scroll instead of truncating the text.
                      var needed = 0.0;
                      for (final label in labels) {
                        final painter = TextPainter(
                          text: TextSpan(text: label, style: labelStyle),
                          textDirection: TextDirection.ltr,
                          textScaler: MediaQuery.textScalerOf(context),
                          maxLines: 1,
                        )..layout();
                        needed += painter.width + 32; // default label padding
                      }
                      final fits = needed <= constraints.maxWidth;

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context, Colors.grey[100]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: !fits,
                          tabAlignment: fits
                              ? TabAlignment.fill
                              : TabAlignment.start,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.accent(
                              context,
                              Color(0xFF5F2D82),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.foreground(
                            context,
                            Colors.grey[600]!,
                          ),
                          labelStyle: labelStyle,
                          tabs: [for (final label in labels) Tab(text: label)],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: AppColors.border(context, Colors.grey[300]!),
            ),

            // Content
            Expanded(
              child: favoritesState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5F2D82),
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFavoritesList(
                          context,
                          favoritesState.allFavorites,
                        ),
                        _buildFavoritesList(
                          context,
                          favoritesState.restaurants,
                        ),
                        _buildFavoritesList(context, favoritesState.stores),
                        _buildFavoritesList(context, favoritesState.addresses),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<FavoriteItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(favoritesProvider.notifier).loadFavorites(),
      color: AppColors.accent(context, Color(0xFF5F2D82)),
      child: ListView.builder(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildFavoriteCard(context, item);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, FavoriteItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      decoration: AppCard.decoration(context, radius: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getTypeColor(item.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      _getTypeIcon(item.type),
                      color: _getTypeColor(item.type),
                    ),
                  ),
                )
              : Icon(_getTypeIcon(item.type), color: _getTypeColor(item.type)),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        subtitle: item.subtitle != null
            ? Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.spacing(context, 4),
                ),
                child: Text(
                  item.subtitle!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            await ref.read(favoritesProvider.notifier).removeFavorite(item);
            if (context.mounted) {
              SnackBarUtils.showWarning(context, 'Removed from favorites');
            }
          },
        ),
        onTap: () {
          // Navigate to detail screen based on type
          _navigateToDetail(context, item);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.favorite_border_rounded,
      title: 'No favorites yet',
      message: 'Tap the heart on a restaurant or store to save it here.',
    );
  }

  IconData _getTypeIcon(FavoriteType type) {
    switch (type) {
      case FavoriteType.restaurant:
        return Icons.restaurant;
      case FavoriteType.store:
        return Icons.store;
      case FavoriteType.address:
        return Icons.location_on;
    }
  }

  Color _getTypeColor(FavoriteType type) {
    switch (type) {
      case FavoriteType.restaurant:
        return const Color(0xFFFF9800);
      case FavoriteType.store:
        return const Color(0xFF4CAF50);
      case FavoriteType.address:
        return const Color(0xFF2196F3);
    }
  }

  void _navigateToDetail(BuildContext context, FavoriteItem item) {
    FavoriteNavigation.open(context, item);
  }
}
