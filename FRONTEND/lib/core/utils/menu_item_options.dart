/// Shared helpers for menu item sizes, flavors, and add-ons.
class MenuOptionChoice {
  final String label;
  final double price;

  const MenuOptionChoice({required this.label, this.price = 0});

  factory MenuOptionChoice.fromDynamic(dynamic value) {
    if (value is Map) {
      return MenuOptionChoice(
        label: value['label']?.toString() ?? '',
        price: (value['price'] as num?)?.toDouble() ?? 0,
      );
    }
    return MenuOptionChoice(label: value?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'price': price,
      };
}

class MenuItemOptionGroups {
  final List<MenuOptionChoice> sizes;
  final List<MenuOptionChoice> flavors;
  final List<MenuOptionChoice> addons;

  const MenuItemOptionGroups({
    this.sizes = const [],
    this.flavors = const [],
    this.addons = const [],
  });

  static const empty = MenuItemOptionGroups();

  bool get hasSizes => sizes.isNotEmpty;
  bool get hasFlavors => flavors.isNotEmpty;
  bool get hasAddons => addons.isNotEmpty;
  bool get hasAny => hasSizes || hasFlavors || hasAddons;

  factory MenuItemOptionGroups.fromApiMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return MenuItemOptionGroups.empty;
    return MenuItemOptionGroups(
      sizes: _parseList(map['sizes']),
      flavors: _parseList(map['flavors']),
      addons: _parseList(map['addons']),
    );
  }

  static List<MenuOptionChoice> _parseList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(MenuOptionChoice.fromDynamic)
        .where((choice) => choice.label.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toApiMap() {
    final map = <String, dynamic>{};
    if (sizes.isNotEmpty) {
      map['sizes'] = sizes.map((e) => e.toJson()).toList();
    }
    if (flavors.isNotEmpty) {
      map['flavors'] = flavors.map((e) => e.toJson()).toList();
    }
    if (addons.isNotEmpty) {
      map['addons'] = addons.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

class SelectedAddon {
  final MenuOptionChoice choice;
  final int quantity;

  const SelectedAddon({required this.choice, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'label': choice.label,
        'price': choice.price,
        'quantity': quantity,
      };
}

class SelectedMenuOptions {
  final MenuOptionChoice? size;
  final MenuOptionChoice? flavor;
  final List<SelectedAddon> addons;

  const SelectedMenuOptions({
    this.size,
    this.flavor,
    this.addons = const [],
  });

  bool get isEmpty =>
      size == null && flavor == null && addons.isEmpty;

  double get extrasTotal {
    var total = (size?.price ?? 0) + (flavor?.price ?? 0);
    for (final addon in addons) {
      total += addon.choice.price * addon.quantity;
    }
    return total;
  }

  double unitPriceForBase(double basePrice) => basePrice + extrasTotal;

  String cartKeySuffix() {
    final parts = <String>[
      if (size != null) 's:${size!.label}',
      if (flavor != null) 'f:${flavor!.label}',
      for (final addon in addons) 'a:${addon.choice.label}x${addon.quantity}',
    ];
    return parts.join('|');
  }

  String formatDisplay() {
    final parts = <String>[];

    if (size != null) {
      var segment = 'Size: ${size!.label}';
      if (size!.price > 0) {
        segment += ' (+₱${size!.price.toStringAsFixed(2)})';
      }
      parts.add(segment);
    }

    if (flavor != null) {
      var segment = 'Flavor: ${flavor!.label}';
      if (flavor!.price > 0) {
        segment += ' (+₱${flavor!.price.toStringAsFixed(2)})';
      }
      parts.add(segment);
    }

    if (addons.isNotEmpty) {
      final addonParts = addons.map((addon) {
        var segment = addon.quantity > 1
            ? '${addon.quantity}x ${addon.choice.label}'
            : addon.choice.label;
        final lineTotal = addon.choice.price * addon.quantity;
        if (lineTotal > 0) {
          segment += ' (+₱${lineTotal.toStringAsFixed(2)})';
        }
        return segment;
      }).toList();
      parts.add('Add-ons: ${addonParts.join(', ')}');
    }

    return parts.join(' | ');
  }

  Map<String, dynamic> toApiMap() {
    final map = <String, dynamic>{};
    if (size != null) map['size'] = size!.toJson();
    if (flavor != null) map['flavor'] = flavor!.toJson();
    if (addons.isNotEmpty) {
      map['addons'] = addons.map((e) => e.toJson()).toList();
    }
    return map;
  }

  factory SelectedMenuOptions.fromApiMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const SelectedMenuOptions();

    MenuOptionChoice? readChoice(dynamic value) {
      if (value is! Map) return null;
      final choice = MenuOptionChoice.fromDynamic(value);
      return choice.label.isEmpty ? null : choice;
    }

    final rawAddons = map['addons'];
    final addons = rawAddons is List
        ? rawAddons
            .whereType<Map>()
            .map((entry) {
              final choice = MenuOptionChoice.fromDynamic(entry);
              if (choice.label.isEmpty) return null;
              final qty = (entry['quantity'] as num?)?.toInt() ?? 1;
              return SelectedAddon(
                choice: choice,
                quantity: qty < 1 ? 1 : qty,
              );
            })
            .whereType<SelectedAddon>()
            .toList()
        : const <SelectedAddon>[];

    return SelectedMenuOptions(
      size: readChoice(map['size']),
      flavor: readChoice(map['flavor']),
      addons: addons,
    );
  }
}
