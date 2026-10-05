class ProductCategory {
  final String id;
  final String name;
  final String iconPath;

  ProductCategory({
    required this.id,
    required this.name,
    required this.iconPath,
  });

  ProductCategory copyWith({
    String? id,
    String? name,
    String? iconPath,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
