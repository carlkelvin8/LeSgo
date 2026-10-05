import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/navigation/favorite_navigation.dart';
import '../../../core/services/favorites_service.dart';
import '../../provider/main/favorites/favorites_provider.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';

class HomeFavoritesSection extends ConsumerWidget {
  const HomeFavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favorites = favoritesState.allFavorites.take(5).toList();

    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: ResponsiveUtils.fontSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Your Favorites',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground(context, Colors.black87),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  AppRouter.push(context, MainRoutes.favorites);
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent(context, Color(0xFF5F2D82)),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          
          // Favorites list
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return _buildFavoriteCard(context, favorite);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, FavoriteItem favorite) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => FavoriteNavigation.open(context, favorite),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(favorite.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(favorite.type),
                  color: _getTypeColor(favorite.type),
                  size: 20,
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              
              // Name
              Text(
                favorite.name,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground(context, Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Subtitle
              if (favorite.subtitle != null)
                Text(
                  favorite.subtitle!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
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
}

