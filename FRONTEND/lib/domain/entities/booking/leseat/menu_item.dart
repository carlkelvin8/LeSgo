import '../../../../core/utils/menu_item_options.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String categoryId;
  final bool isPopular;
  final MenuItemOptionGroups optionGroups;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.categoryId,
    this.isPopular = false,
    this.optionGroups = MenuItemOptionGroups.empty,
  });

  bool get hasOptions => optionGroups.hasAny;

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imagePath,
    String? categoryId,
    bool? isPopular,
    MenuItemOptionGroups? optionGroups,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      isPopular: isPopular ?? this.isPopular,
      optionGroups: optionGroups ?? this.optionGroups,
    );
  }
}
