import '../../../domain/entities/booking/lesbuy/store.dart';
import '../../../domain/entities/booking/lesbuy/product.dart';

class LesbuyMockData {
  /// Get mock stores for LesBuy
  static List<Store> getMockStores() {
    return [
      Store(
        id: '1',
        name: 'Mercury Drug - Claveria',
        address: 'Main Street, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/pharmacy.svg',
        rating: 4.9,
        reviewCount: 500,
        categories: ['pharmacy', 'health', 'personal_care'],
        storeType: 'Pharmacy • Health • Personal Care',
        deliveryTime: '20-30 min',
        openingHours: '8:00 AM - 9:00 PM',
        priceRange: '\$\$',
      ),
      Store(
        id: '2',
        name: 'National Book Store',
        address: 'Station 2, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/books.svg',
        rating: 4.7,
        reviewCount: 350,
        categories: ['books', 'school_supplies', 'office'],
        isNew: true,
        storeType: 'Books • School Supplies • Office',
        deliveryTime: '25-35 min',
        openingHours: '9:00 AM - 8:00 PM',
        priceRange: '\$\$',
      ),
      Store(
        id: '3',
        name: 'Ace Hardware - Claveria',
        address: 'Commercial Area, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/hardware.svg',
        rating: 4.6,
        reviewCount: 280,
        categories: ['hardware', 'tools', 'home_improvement'],
        storeType: 'Hardware • Tools • Home',
        deliveryTime: '30-45 min',
        openingHours: '8:30 AM - 7:30 PM',
        priceRange: '\$\$\$',
      ),
      Store(
        id: '4',
        name: 'Watsons - Claveria',
        address: 'Town Center, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/beauty.svg',
        rating: 4.8,
        reviewCount: 420,
        categories: ['beauty', 'personal_care', 'health'],
        storeType: 'Beauty • Personal Care • Health',
        deliveryTime: '20-30 min',
        openingHours: '9:00 AM - 9:00 PM',
        priceRange: '\$\$',
      ),
      Store(
        id: '5',
        name: 'Pet Express - Claveria',
        address: 'Station 1, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/pets.svg',
        rating: 4.5,
        reviewCount: 180,
        categories: ['pets', 'pet_food', 'pet_supplies'],
        isNew: true,
        storeType: 'Pet Food • Pet Supplies • Accessories',
        deliveryTime: '25-40 min',
        openingHours: '10:00 AM - 8:00 PM',
        priceRange: '\$\$',
      ),
      Store(
        id: '6',
        name: 'Handyman - Claveria',
        address: 'Market Road, Claveria, Cagayan',
        imagePath: 'assets/images/book/lesbuy/hardware.svg',
        rating: 4.4,
        reviewCount: 220,
        categories: ['hardware', 'electrical', 'plumbing'],
        storeType: 'Hardware • Electrical • Plumbing',
        deliveryTime: '30-45 min',
        openingHours: '8:00 AM - 7:00 PM',
        priceRange: '\$\$',
      ),
    ];
  }

  /// Get mock products for a store
  static List<Product> getMockProducts(String storeId, List<String> categories) {
    final products = <Product>[];

    if (categories.contains('pharmacy') || categories.contains('health')) {
      products.addAll(_getPharmacyProducts(storeId));
    }
    if (categories.contains('books') || categories.contains('school_supplies')) {
      products.addAll(_getSchoolSuppliesProducts(storeId));
    }
    if (categories.contains('hardware') || categories.contains('tools')) {
      products.addAll(_getHardwareProducts(storeId));
    }
    if (categories.contains('beauty') || categories.contains('personal_care')) {
      products.addAll(_getBeautyProducts(storeId));
    }
    if (categories.contains('pets') || categories.contains('pet_food')) {
      products.addAll(_getPetProducts(storeId));
    }

    return products;
  }

  static List<Product> _getPharmacyProducts(String storeId) {
    return [
      Product(
        id: '${storeId}_med_1',
        name: 'Biogesic 500mg',
        description: 'Paracetamol for fever and headache relief. Box of 20 tablets.',
        price: 65.00,
        imagePath: 'assets/images/book/lesbuy/medicine.svg',
        categoryId: 'pharmacy',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_med_2',
        name: 'Neozep Forte',
        description: 'Cold and flu relief tablets. Box of 10 tablets.',
        price: 85.00,
        imagePath: 'assets/images/book/lesbuy/medicine.svg',
        categoryId: 'pharmacy',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_med_3',
        name: 'Strepsils Lozenges',
        description: 'Sore throat relief lozenges. Pack of 24.',
        price: 120.00,
        imagePath: 'assets/images/book/lesbuy/medicine.svg',
        categoryId: 'pharmacy',
      ),
      Product(
        id: '${storeId}_health_1',
        name: 'Face Mask (50pcs)',
        description: '3-ply disposable surgical face masks.',
        price: 250.00,
        imagePath: 'assets/images/book/lesbuy/health.svg',
        categoryId: 'health',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_health_2',
        name: 'Alcohol 70% (500ml)',
        description: 'Isopropyl alcohol for disinfection.',
        price: 95.00,
        imagePath: 'assets/images/book/lesbuy/health.svg',
        categoryId: 'health',
      ),
    ];
  }

  static List<Product> _getSchoolSuppliesProducts(String storeId) {
    return [
      Product(
        id: '${storeId}_book_1',
        name: 'Composition Notebook',
        description: '200 pages, ruled, high-quality paper.',
        price: 45.00,
        imagePath: 'assets/images/book/lesbuy/notebook.svg',
        categoryId: 'school_supplies',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_book_2',
        name: 'Ballpen (12pcs)',
        description: 'Blue ballpoint pens, smooth writing.',
        price: 65.00,
        imagePath: 'assets/images/book/lesbuy/pen.svg',
        categoryId: 'school_supplies',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_book_3',
        name: 'Scientific Calculator',
        description: 'Casio FX-991ES PLUS scientific calculator.',
        price: 850.00,
        imagePath: 'assets/images/book/lesbuy/calculator.svg',
        categoryId: 'school_supplies',
      ),
      Product(
        id: '${storeId}_book_4',
        name: 'Intermediate Pad',
        description: 'Quality writing pad, 80 leaves.',
        price: 25.00,
        imagePath: 'assets/images/book/lesbuy/notebook.svg',
        categoryId: 'school_supplies',
      ),
      Product(
        id: '${storeId}_book_5',
        name: 'Colored Pencils (24pcs)',
        description: 'Vibrant colored pencils for art projects.',
        price: 180.00,
        imagePath: 'assets/images/book/lesbuy/pen.svg',
        categoryId: 'school_supplies',
      ),
    ];
  }

  static List<Product> _getHardwareProducts(String storeId) {
    return [
      Product(
        id: '${storeId}_hw_1',
        name: 'Hammer',
        description: 'Steel claw hammer with rubber grip.',
        price: 280.00,
        imagePath: 'assets/images/book/lesbuy/tools.svg',
        categoryId: 'tools',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_hw_2',
        name: 'Screwdriver Set (6pcs)',
        description: 'Phillips and flathead screwdrivers.',
        price: 350.00,
        imagePath: 'assets/images/book/lesbuy/tools.svg',
        categoryId: 'tools',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_hw_3',
        name: 'LED Bulb 9W',
        description: 'Energy-saving LED bulb, daylight.',
        price: 85.00,
        imagePath: 'assets/images/book/lesbuy/electrical.svg',
        categoryId: 'electrical',
      ),
      Product(
        id: '${storeId}_hw_4',
        name: 'Extension Cord (5m)',
        description: '4-gang extension cord with surge protector.',
        price: 450.00,
        imagePath: 'assets/images/book/lesbuy/electrical.svg',
        categoryId: 'electrical',
      ),
      Product(
        id: '${storeId}_hw_5',
        name: 'Teflon Tape',
        description: 'Plumber\'s tape for pipe threading.',
        price: 35.00,
        imagePath: 'assets/images/book/lesbuy/plumbing.svg',
        categoryId: 'plumbing',
      ),
    ];
  }

  static List<Product> _getBeautyProducts(String storeId) {
    return [
      Product(
        id: '${storeId}_beauty_1',
        name: 'Facial Cleanser',
        description: 'Gentle foam cleanser for all skin types.',
        price: 299.00,
        imagePath: 'assets/images/book/lesbuy/beauty.svg',
        categoryId: 'beauty',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_beauty_2',
        name: 'Sunscreen SPF 50',
        description: 'Daily sun protection, lightweight formula.',
        price: 450.00,
        imagePath: 'assets/images/book/lesbuy/beauty.svg',
        categoryId: 'beauty',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_beauty_3',
        name: 'Shampoo 400ml',
        description: 'Anti-dandruff shampoo with conditioner.',
        price: 185.00,
        imagePath: 'assets/images/book/lesbuy/personal_care.svg',
        categoryId: 'personal_care',
      ),
      Product(
        id: '${storeId}_beauty_4',
        name: 'Toothpaste 150g',
        description: 'Whitening toothpaste with fluoride.',
        price: 95.00,
        imagePath: 'assets/images/book/lesbuy/personal_care.svg',
        categoryId: 'personal_care',
      ),
    ];
  }

  static List<Product> _getPetProducts(String storeId) {
    return [
      Product(
        id: '${storeId}_pet_1',
        name: 'Dog Food 3kg',
        description: 'Premium dry dog food for adult dogs.',
        price: 550.00,
        imagePath: 'assets/images/book/lesbuy/pet_food.svg',
        categoryId: 'pet_food',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_pet_2',
        name: 'Cat Food 1.5kg',
        description: 'Nutritious dry cat food for all ages.',
        price: 380.00,
        imagePath: 'assets/images/book/lesbuy/pet_food.svg',
        categoryId: 'pet_food',
        isPopular: true,
      ),
      Product(
        id: '${storeId}_pet_3',
        name: 'Pet Shampoo 500ml',
        description: 'Gentle shampoo for dogs and cats.',
        price: 220.00,
        imagePath: 'assets/images/book/lesbuy/pet_supplies.svg',
        categoryId: 'pet_supplies',
      ),
      Product(
        id: '${storeId}_pet_4',
        name: 'Dog Collar (Medium)',
        description: 'Adjustable nylon collar with buckle.',
        price: 150.00,
        imagePath: 'assets/images/book/lesbuy/pet_supplies.svg',
        categoryId: 'pet_supplies',
      ),
    ];
  }
}
