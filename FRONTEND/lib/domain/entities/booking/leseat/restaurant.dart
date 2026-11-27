class Restaurant {
  final String id;
  final String name;
  final String address;
  final String imagePath;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final bool isNew;
  final String? cuisine;
  final String? deliveryTime;
  final String? priceRange;
  final String? openingHours;

  /// Branch this card stands for (null = the store's default listing).
  final int? branchId;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.imagePath,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    this.isNew = false,
    this.cuisine,
    this.deliveryTime,
    this.priceRange,
    this.openingHours,
    this.branchId,
  });

  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? imagePath,
    double? rating,
    int? reviewCount,
    List<String>? categories,
    bool? isNew,
    String? cuisine,
    String? deliveryTime,
    String? priceRange,
    String? openingHours,
    int? branchId,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categories: categories ?? this.categories,
      isNew: isNew ?? this.isNew,
      cuisine: cuisine ?? this.cuisine,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      priceRange: priceRange ?? this.priceRange,
      openingHours: openingHours ?? this.openingHours,
      branchId: branchId ?? this.branchId,
    );
  }
}
