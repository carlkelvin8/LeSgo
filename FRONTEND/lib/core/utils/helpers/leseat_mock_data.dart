import '../../../domain/entities/booking/leseat/menu_item.dart';
import '../../../domain/entities/booking/leseat/food_category.dart';

class LeseatMockData {
  /// Get menu categories based on restaurant categories
  static List<FoodCategory> getMenuCategoriesForRestaurant(
    List<String> restaurantCategories,
  ) {
    final categories = <FoodCategory>[
      FoodCategory(id: 'popular', name: 'Popular', iconPath: ''),
    ];

    // Map restaurant category IDs to menu categories
    final categoryMap = {
      'pizza': FoodCategory(id: 'pizza', name: 'Pizza', iconPath: ''),
      'pasta': FoodCategory(id: 'pasta', name: 'Pasta', iconPath: ''),
      'starters': FoodCategory(id: 'starters', name: 'Starters', iconPath: ''),
      'chicken': FoodCategory(id: 'chicken', name: 'Chicken', iconPath: ''),
      'burger': FoodCategory(id: 'burger', name: 'Burgers', iconPath: ''),
      'fries': FoodCategory(id: 'fries', name: 'Fries', iconPath: ''),
      'drinks': FoodCategory(id: 'drinks', name: 'Drinks', iconPath: ''),
      'desserts': FoodCategory(id: 'desserts', name: 'Desserts', iconPath: ''),
    };

    // Add categories that match the restaurant's categories
    for (final catId in restaurantCategories) {
      if (categoryMap.containsKey(catId) &&
          !categories.any((cat) => cat.id == catId)) {
        categories.add(categoryMap[catId]!);
      }
    }

    return categories;
  }

  /// Get mock menu items for a restaurant based on its categories
  static List<MenuItem> getMockMenuItems(
    String restaurantId,
    List<String> restaurantCategories,
  ) {
    final menuItems = <MenuItem>[];

    // Generate menu items based on restaurant categories
    if (restaurantCategories.contains('pizza')) {
      menuItems.addAll(_getPizzaItems(restaurantId));
    }
    if (restaurantCategories.contains('pasta')) {
      menuItems.addAll(_getPastaItems(restaurantId));
    }
    if (restaurantCategories.contains('starters')) {
      menuItems.addAll(_getStarterItems(restaurantId));
    }
    if (restaurantCategories.contains('chicken')) {
      menuItems.addAll(_getChickenItems(restaurantId));
    }
    if (restaurantCategories.contains('burger')) {
      menuItems.addAll(_getBurgerItems(restaurantId));
    }
    if (restaurantCategories.contains('fries')) {
      menuItems.addAll(_getFriesItems(restaurantId));
    }
    if (restaurantCategories.contains('drinks')) {
      menuItems.addAll(_getDrinkItems(restaurantId));
    }
    if (restaurantCategories.contains('desserts')) {
      menuItems.addAll(_getDessertItems(restaurantId));
    }

    return menuItems;
  }

  // Pizza items
  static List<MenuItem> _getPizzaItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_pizza_1',
        name: 'Margherita Pizza',
        description:
            'San Marzano tomato sauce, fresh mozzarella di bufala, basil leaves, extra virgin olive oil',
        price: 14.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pizza',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_pizza_2',
        name: 'Pepperoni Feast',
        description: 'Double pepperoni, mozzarella, tomato sauce, oregano',
        price: 16.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pizza',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_pizza_3',
        name: 'Quattro Stagioni',
        description:
            'Tomato sauce, mozzarella, ham, mushrooms, artichokes, olives',
        price: 18.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pizza',
        isPopular: true,
      ),
    ];
  }

  // Pasta items
  static List<MenuItem> _getPastaItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_pasta_1',
        name: 'Spaghetti Carbonara',
        description: 'Creamy pasta with bacon, eggs, and parmesan',
        price: 15.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pasta',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_pasta_2',
        name: 'Fettuccine Alfredo',
        description: 'Rich and creamy pasta with parmesan cheese',
        price: 14.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pasta',
      ),
      MenuItem(
        id: '${restaurantId}_pasta_3',
        name: 'Penne Arrabbiata',
        description: 'Spicy tomato sauce with garlic and red chili',
        price: 13.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'pasta',
      ),
    ];
  }

  // Starter items
  static List<MenuItem> _getStarterItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_starter_1',
        name: 'Bruschetta',
        description: 'Toasted bread with fresh tomatoes, garlic, and basil',
        price: 8.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'starters',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_starter_2',
        name: 'Caprese Salad',
        description: 'Fresh mozzarella, tomatoes, basil, balsamic glaze',
        price: 10.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'starters',
      ),
      MenuItem(
        id: '${restaurantId}_starter_3',
        name: 'Garlic Bread',
        description: 'Freshly baked bread with garlic butter and herbs',
        price: 6.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'starters',
      ),
    ];
  }

  // Chicken items
  static List<MenuItem> _getChickenItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_chicken_1',
        name: 'Chickenjoy',
        description: 'Crispy fried chicken with our signature gravy',
        price: 12.00,
        imagePath: 'assets/images/book/leseat/Chicken.svg',
        categoryId: 'chicken',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_chicken_2',
        name: 'Spicy Chicken',
        description: 'Hot and spicy fried chicken with special seasoning',
        price: 13.50,
        imagePath: 'assets/images/book/leseat/Chicken.svg',
        categoryId: 'chicken',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_chicken_3',
        name: 'Chicken Tenders',
        description: 'Tender chicken strips with your choice of dipping sauce',
        price: 11.00,
        imagePath: 'assets/images/book/leseat/Chicken.svg',
        categoryId: 'chicken',
      ),
    ];
  }

  // Burger items
  static List<MenuItem> _getBurgerItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_burger_1',
        name: 'Classic Burger',
        description: 'Beef patty, lettuce, tomato, onion, special sauce',
        price: 10.50,
        imagePath: 'assets/images/book/leseat/Burger.svg',
        categoryId: 'burger',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_burger_2',
        name: 'Cheeseburger',
        description: 'Beef patty with cheese, pickles, lettuce, and sauce',
        price: 11.50,
        imagePath: 'assets/images/book/leseat/Burger.svg',
        categoryId: 'burger',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_burger_3',
        name: 'Bacon Burger',
        description: 'Beef patty with crispy bacon, cheese, and special sauce',
        price: 13.00,
        imagePath: 'assets/images/book/leseat/Burger.svg',
        categoryId: 'burger',
      ),
    ];
  }

  // Fries items
  static List<MenuItem> _getFriesItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_fries_1',
        name: 'Regular Fries',
        description: 'Crispy golden fries, perfectly seasoned',
        price: 5.00,
        imagePath: 'assets/images/book/leseat/Fries.svg',
        categoryId: 'fries',
        isPopular: true,
        sizeOptions: ['Small', 'Medium', 'Large', 'Family'],
      ),
      MenuItem(
        id: '${restaurantId}_fries_2',
        name: 'Cheese Fries',
        description: 'Fries topped with melted cheese and bacon bits',
        price: 7.50,
        imagePath: 'assets/images/book/leseat/Fries.svg',
        categoryId: 'fries',
        sizeOptions: ['Small', 'Medium', 'Large'],
      ),
      MenuItem(
        id: '${restaurantId}_fries_3',
        name: 'Curly Fries',
        description: 'Spiral-cut fries with special seasoning',
        price: 6.00,
        imagePath: 'assets/images/book/leseat/Fries.svg',
        categoryId: 'fries',
        sizeOptions: ['Small', 'Medium', 'Large'],
      ),
    ];
  }

  // Drink items
  static List<MenuItem> _getDrinkItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_drink_1',
        name: 'Italian Soda',
        description: 'Refreshing sparkling drink with your choice of flavor',
        price: 4.50,
        imagePath: 'assets/images/book/leseat/Drink.svg',
        categoryId: 'drinks',
        sizeOptions: ['Small', 'Medium', 'Large'],
      ),
      MenuItem(
        id: '${restaurantId}_drink_2',
        name: 'Iced Tea',
        description: 'Freshly brewed iced tea, sweetened to perfection',
        price: 3.50,
        imagePath: 'assets/images/book/leseat/Drink.svg',
        categoryId: 'drinks',
        sizeOptions: ['Regular', 'Large'],
      ),
      MenuItem(
        id: '${restaurantId}_drink_3',
        name: 'Soft Drinks',
        description: 'Coca-Cola, Sprite, or your favorite soft drink',
        price: 3.00,
        imagePath: 'assets/images/book/leseat/Drink.svg',
        categoryId: 'drinks',
        sizeOptions: ['Small', 'Medium', 'Large'],
      ),
    ];
  }

  // Dessert items
  static List<MenuItem> _getDessertItems(String restaurantId) {
    return [
      MenuItem(
        id: '${restaurantId}_dessert_1',
        name: 'Tiramisu',
        description: 'Classic Italian dessert with coffee and mascarpone',
        price: 9.00,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'desserts',
        isPopular: true,
      ),
      MenuItem(
        id: '${restaurantId}_dessert_2',
        name: 'Chocolate Cake',
        description: 'Rich chocolate cake with creamy frosting',
        price: 8.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'desserts',
      ),
      MenuItem(
        id: '${restaurantId}_dessert_3',
        name: 'Ice Cream',
        description: 'Vanilla, chocolate, or strawberry ice cream',
        price: 5.50,
        imagePath: 'assets/images/book/leseat/Pizza.svg',
        categoryId: 'desserts',
      ),
    ];
  }
}
