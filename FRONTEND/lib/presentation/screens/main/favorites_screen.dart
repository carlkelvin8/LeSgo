import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/favorites/favorites_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/favorites_service.dart';

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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                children: [
                  const AuthHeader(title: 'Favorites'),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF5F2D82),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: 'All (${favoritesState.totalCount})'),
                        Tab(text: 'Restaurants (${favoritesState.restaurantsCount})'),
                        Tab(text: 'Stores (${favoritesState.storesCount})'),
                        Tab(text: 'Addresses (${favoritesState.addressesCount})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.grey[300]),

            // Content
            Expanded(
              child: favoritesState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFavoritesList(context, favoritesState.allFavorites),
                        _buildFavoritesList(context, favoritesState.restaurants),
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
      color: const Color(0xFF5F2D82),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getTypeColor(item.type).withOpacity(0.1),
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
              : Icon(
                  _getTypeIcon(item.type),
                  color: _getTypeColor(item.type),
                ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: item.subtitle != null
            ? Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.spacing(context, 4)),
                child: Text(
                  item.subtitle!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[600],
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed from favorites'),
                  backgroundColor: Colors.grey[700],
                  duration: const Duration(seconds: 2),
                ),
              );
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Start adding your favorite places',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
    // TODO: Navigate to appropriate detail screen based on type and metadata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${item.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
