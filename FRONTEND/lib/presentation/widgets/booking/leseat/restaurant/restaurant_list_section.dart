import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';
import '../restaurant_card.dart';

class RestaurantListSection extends StatelessWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant)? onRestaurantTap;

  const RestaurantListSection({
    super.key,
    required this.restaurants,
    this.onRestaurantTap,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: ResponsiveUtils.fontSize(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'No restaurants found',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: onRestaurantTap != null
              ? () => onRestaurantTap!(restaurant)
              : null,
        );
      },
    );
  }
}
