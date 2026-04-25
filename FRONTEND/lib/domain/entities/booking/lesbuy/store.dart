class Store {
  final String id;
  final String name;
  final String address;
  final String imagePath;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final bool isNew;
  final String? storeType;
  final String? deliveryTime;
  final String? openingHours;
  final String? priceRange;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    this.isNew = false,
    this.storeType,
    this.deliveryTime,
    this.openingHours,
    this.priceRange,
  });

  Store copyWith({
    String? id,
    String? name,
    String? address,
    String? imagePath,
    double? rating,
    int? reviewCount,
    List<String>? categories,
    bool? isNew,
    String? storeType,
    String? deliveryTime,
    String? openingHours,
    String? priceRange,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categories: categories ?? this.categories,
      isNew: isNew ?? this.isNew,
      storeType: storeType ?? this.storeType,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      openingHours: openingHours ?? this.openingHours,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}
