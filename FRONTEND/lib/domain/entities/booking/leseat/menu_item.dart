class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String categoryId;
  final bool isPopular;
  final List<String>? sizeOptions;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.categoryId,
    this.isPopular = false,
    this.sizeOptions,
  });

  bool get hasSizeOptions => sizeOptions != null && sizeOptions!.isNotEmpty;

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    String? categoryId,
    bool? isPopular,
    List<String>? sizeOptions,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      isPopular: isPopular ?? this.isPopular,
      sizeOptions: sizeOptions ?? this.sizeOptions,
    );
  }
}

