class FoodCategory {
  final String id;
  final String name;
  final String iconPath;

  FoodCategory({
    required this.id,
    required this.name,
    required this.iconPath,
  });

  FoodCategory copyWith({
    String? id,
    String? name,
    String? iconPath,
  }) {
    return FoodCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
