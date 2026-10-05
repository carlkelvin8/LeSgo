class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String categoryId;
  final bool isPopular;
  final bool inStock;
  final int? stockCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.categoryId,
    this.isPopular = false,
    this.inStock = true,
    this.stockCount,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    String? categoryId,
    bool? isPopular,
    bool? inStock,
    int? stockCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      isPopular: isPopular ?? this.isPopular,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
    );
  }
}
