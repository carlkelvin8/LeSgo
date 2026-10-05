import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/services/favorites_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'favorites stay private to the signed-in customer on shared devices',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FavoritesService(prefs);

      service.setUserScope('customer-a');
      expect(
        await service.addFavoriteRestaurant(id: 'restaurant-1', name: 'Cafe'),
        isTrue,
      );

      service.setUserScope('customer-b');
      expect(await service.getFavoriteRestaurants(), isEmpty);
      expect(
        await service.addFavoriteRestaurant(id: 'restaurant-2', name: 'Diner'),
        isTrue,
      );

      service.setUserScope('customer-a');
      expect(
        (await service.getFavoriteRestaurants()).map((favorite) => favorite.id),
        ['restaurant-1'],
      );
    },
  );
}
