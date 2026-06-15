import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/menu_item_options.dart';
import '../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';
import 'merchant_menu_provider.dart';

class MerchantMenuItemFormInput {
  final int? itemId; // For edit mode
  final int? menuCategoryId;
  final String? itemName;
  final String? price;
  final String? description;
  final String? category;
  final String? selectedTags;
  final bool? liveOnMenu;
  final bool? trackStock;
  final int? stock;
  final bool? autoHideWhenEmpty;
  final String? imageUrl;
  final String? optionsJson;

  // Backward-compatibility shim for hot-reload sessions that still look up this removed getter.
  @Deprecated('variationLabels has been removed')
  String? get variationLabels => null;

  const MerchantMenuItemFormInput({
    this.itemId,
    this.menuCategoryId,
    this.itemName,
    this.price,
    this.description,
    this.category,
    this.selectedTags,
    this.liveOnMenu,
    this.trackStock,
    this.stock,
    this.autoHideWhenEmpty,
    this.imageUrl,
    this.optionsJson,
  });

  const MerchantMenuItemFormInput.add()
      : itemId = null,
        menuCategoryId = null,
        itemName = '',
        price = '0.00',
        description = '',
        category = '',
        selectedTags = null,
        liveOnMenu = null,
        trackStock = null,
        stock = null,
        autoHideWhenEmpty = null,
        imageUrl = null,
        optionsJson = null;

  factory MerchantMenuItemFormInput.edit(Map<String, String>? initialItem) {
    return MerchantMenuItemFormInput(
      itemId: initialItem?['id'] != null ? int.tryParse(initialItem!['id']!) : null,
      menuCategoryId: initialItem?['menuCategoryId'] != null
          ? int.tryParse(initialItem!['menuCategoryId']!)
          : null,
      itemName: initialItem?['itemName'] ?? initialItem?['name'],
      price: initialItem?['price'],
      description: initialItem?['description'],
      category: initialItem?['category'],
      selectedTags: initialItem?['selectedTags'],
      liveOnMenu: initialItem?['isAvailable'] == null
          ? null
          : initialItem!['isAvailable'] == 'true',
      trackStock: initialItem?['trackStock'] == null
          ? null
          : initialItem!['trackStock'] == 'true',
      stock: initialItem?['stock'] == null
          ? null
          : int.tryParse(initialItem!['stock']!),
      autoHideWhenEmpty: initialItem?['autoHideWhenEmpty'] == null
          ? null
          : initialItem!['autoHideWhenEmpty'] == 'true',
      imageUrl: initialItem?['imageUrl'],
      optionsJson: initialItem?['optionsJson'],
    );
  }

  bool get isEditMode => itemId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantMenuItemFormInput &&
        other.itemId == itemId &&
        other.menuCategoryId == menuCategoryId &&
        other.itemName == itemName &&
        other.price == price &&
        other.description == description &&
        other.category == category &&
        other.selectedTags == selectedTags &&
        other.liveOnMenu == liveOnMenu;
  }

  @override
  int get hashCode => Object.hash(
        itemId,
        menuCategoryId,
        itemName,
        price,
        description,
        category,
        selectedTags,
        liveOnMenu,
      );
}

class MerchantMenuItemFormState {
  final String itemName;
  final String price;
  final String description;
  final String category;
  final List<String> selectedTags;
  final bool liveOnMenu;
  final bool trackStock;
  final int stock;
  final bool autoHideWhenEmpty;
  final bool isSubmitting;
  final String? errorMessage;
  final String? existingImageUrl;
  final String? localImagePath;
  final MenuItemOptionGroups menuOptions;

  String? get displayImageSource => localImagePath ?? existingImageUrl;

  MerchantMenuItemFormState({
    required this.itemName,
    required this.price,
    required this.description,
    required this.category,
    required this.selectedTags,
    required this.liveOnMenu,
    this.trackStock = false,
    this.stock = 0,
    this.autoHideWhenEmpty = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.existingImageUrl,
    this.localImagePath,
    this.menuOptions = MenuItemOptionGroups.empty,
  });

  bool get isValid =>
      itemName.isNotEmpty &&
      price.isNotEmpty &&
      price != '0.00' &&
      category.isNotEmpty;

  MerchantMenuItemFormState copyWith({
    String? itemName,
    String? price,
    String? description,
    String? category,
    List<String>? selectedTags,
    bool? liveOnMenu,
    bool? trackStock,
    int? stock,
    bool? autoHideWhenEmpty,
    bool? isSubmitting,
    String? errorMessage,
    String? existingImageUrl,
    String? localImagePath,
    MenuItemOptionGroups? menuOptions,
    bool clearLocalImage = false,
  }) {
    return MerchantMenuItemFormState(
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      selectedTags: selectedTags ?? this.selectedTags,
      liveOnMenu: liveOnMenu ?? this.liveOnMenu,
      trackStock: trackStock ?? this.trackStock,
      stock: stock ?? this.stock,
      autoHideWhenEmpty: autoHideWhenEmpty ?? this.autoHideWhenEmpty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
      localImagePath:
          clearLocalImage ? null : (localImagePath ?? this.localImagePath),
      menuOptions: menuOptions ?? this.menuOptions,
    );
  }
}

class MerchantMenuItemFormNotifier extends StateNotifier<MerchantMenuItemFormState> {
  final Ref _ref;
  final int? _itemId;
  final int? _initialMenuCategoryId;

  MerchantMenuItemFormNotifier(
    this._ref, {
    int? itemId,
    int? menuCategoryId,
    String? itemName,
    String? price,
    String? description,
    String? category,
    List<String>? selectedTags,
    bool? liveOnMenu,
    bool? trackStock,
    int? stock,
    bool? autoHideWhenEmpty,
    String? imageUrl,
    String? optionsJson,
  }) : _itemId = itemId,
       _initialMenuCategoryId = menuCategoryId,
       super(
    MerchantMenuItemFormState(
      itemName: itemName ?? '',
      price: price ?? '0.00',
      description: description ?? '',
      category: category ?? '',
      selectedTags: selectedTags ?? [],
      liveOnMenu: liveOnMenu ?? true,
      trackStock: _resolveTrackStock(trackStock, optionsJson),
      stock: _resolveStock(stock, optionsJson),
      autoHideWhenEmpty: autoHideWhenEmpty ?? true,
      existingImageUrl: imageUrl,
      menuOptions: _parseOptionsJson(optionsJson),
    ),
  );

  static bool _resolveTrackStock(bool? trackStock, String? optionsJson) {
    if (trackStock != null) return trackStock;
    return _inventoryFromOptionsJson(optionsJson).trackStock;
  }

  static int _resolveStock(int? stock, String? optionsJson) {
    if (stock != null) return stock;
    return _inventoryFromOptionsJson(optionsJson).stock ?? 0;
  }

  static MenuItemInventory _inventoryFromOptionsJson(String? optionsJson) {
    if (optionsJson == null || optionsJson.isEmpty) {
      return MenuItemInventory.unlimited;
    }
    try {
      final decoded = jsonDecode(optionsJson);
      if (decoded is Map<String, dynamic>) {
        return MenuItemInventory.fromOptionsMap(decoded);
      }
    } catch (_) {}
    return MenuItemInventory.unlimited;
  }

  static MenuItemOptionGroups _parseOptionsJson(String? raw) {
    if (raw == null || raw.isEmpty) return MenuItemOptionGroups.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return MenuItemOptionGroups.fromApiMap(decoded);
      }
    } catch (_) {}
    return MenuItemOptionGroups.empty;
  }

  void updateItemName(String value) {
    state = state.copyWith(itemName: value);
  }

  void updatePrice(String value) {
    state = state.copyWith(price: value);
  }

  void updateDescription(String value) {
    state = state.copyWith(description: value);
  }

  void updateCategory(String value) {
    state = state.copyWith(category: value);
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  void toggleLiveOnMenu(bool value) {
    state = state.copyWith(liveOnMenu: value);
  }

  void toggleTrackStock(bool value) {
    state = state.copyWith(trackStock: value, stock: value ? state.stock : 0);
  }

  void updateStock(int value) {
    state = state.copyWith(stock: value < 0 ? 0 : value);
  }

  void toggleAutoHideWhenEmpty(bool value) {
    state = state.copyWith(autoHideWhenEmpty: value);
  }

  void updateLocalImage(String? path) {
    if (path == null || path.isEmpty) {
      state = state.copyWith(clearLocalImage: true);
      return;
    }
    state = state.copyWith(localImagePath: path);
  }

  void updateMenuOptions(MenuItemOptionGroups options) {
    state = state.copyWith(menuOptions: options);
  }

  Future<int?> _resolveMenuCategoryId() async {
    final menuAsync = await _ref.read(merchantMenuProvider.future);
    if (menuAsync == null || menuAsync.categories.isEmpty) {
      return _initialMenuCategoryId;
    }

    if (state.category.isNotEmpty) {
      for (final category in menuAsync.categories) {
        if (category.name == state.category) {
          return category.id;
        }
      }
    }

    return _initialMenuCategoryId;
  }

  Future<bool> attemptSubmit() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: state.category.isEmpty
            ? 'Please select a category'
            : 'Please fill in all required fields',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final priceValue = double.tryParse(state.price.replaceAll(',', '').trim());
      if (priceValue == null || priceValue <= 0) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Invalid price value.',
        );
        return false;
      }

      final menuCategoryId = await _resolveMenuCategoryId();
      if (menuCategoryId == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please select a category',
        );
        return false;
      }
      
      final dataSource = _ref.read(merchantDataSourceProvider);
      
      final inventory = MenuItemInventory(
        stock: state.trackStock ? state.stock : null,
        trackStock: state.trackStock,
        autoHideWhenEmpty: state.autoHideWhenEmpty,
      );
      final resolvedAvailability = inventory.resolveAvailability(
        liveOnMenu: state.liveOnMenu,
      );
      final optionsMap = mergeInventoryIntoOptions(
        state.menuOptions.toApiMap(),
        inventory,
      );

      if (_itemId != null) {
        final request = UpdateMenuItemRequest(
          menuCategoryId: menuCategoryId,
          name: state.itemName,
          description: state.description.isEmpty ? null : state.description,
          price: priceValue,
          isAvailable: resolvedAvailability,
          stockCount: state.trackStock ? state.stock : null,
          imageUrl: state.existingImageUrl,
          imagePath: state.localImagePath,
          tags: state.selectedTags.isEmpty ? null : state.selectedTags,
          options: optionsMap.isEmpty ? null : optionsMap,
        );
        
        await dataSource.updateMenuItem(_itemId, request);
        print('✅ Menu item updated successfully');
      } else {
        // Add mode - create new item
        // Get partner_id from auth state
        final authState = _ref.read(riderAuthProvider);
        final profile = _ref.read(merchantProfileProvider).value;
        final partnerId = authState.user?.partnerId ?? profile?.id;
        
        if (partnerId == null) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Partner ID not found. Please login again.',
          );
          return false;
        }
        
        print('🔍 Using partner_id from auth: $partnerId');
        
        final request = CreateMenuItemRequest(
          menuCategoryId: menuCategoryId,
          name: state.itemName,
          description: state.description.isEmpty ? null : state.description,
          price: priceValue,
          isAvailable: resolvedAvailability,
          stockCount: state.trackStock ? state.stock : null,
          imageUrl: state.existingImageUrl,
          imagePath: state.localImagePath,
          tags: state.selectedTags.isEmpty ? null : state.selectedTags,
          options: optionsMap.isEmpty ? null : optionsMap,
        );
        
        await dataSource.createMenuItem(partnerId, request);
        print('✅ Menu item created successfully');
      }
      
      // Refresh menu providers
      _ref.invalidate(merchantMenuProvider);
      _ref.invalidate(merchantMenuItemsProvider);
      
      // Success
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('❌ Error saving menu item: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ApiService.extractError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final merchantMenuItemFormProvider =
    StateNotifierProvider.family<MerchantMenuItemFormNotifier, MerchantMenuItemFormState, MerchantMenuItemFormInput>((
  ref,
  initialInput,
) {
  return MerchantMenuItemFormNotifier(
    ref,
    itemId: initialInput.itemId,
    menuCategoryId: initialInput.menuCategoryId,
    itemName: initialInput.itemName,
    price: initialInput.price,
    description: initialInput.description,
    category: initialInput.category,
    selectedTags: initialInput.selectedTags?.split(',').toList(),
    liveOnMenu: initialInput.liveOnMenu,
    trackStock: initialInput.trackStock,
    stock: initialInput.stock,
    autoHideWhenEmpty: initialInput.autoHideWhenEmpty,
    imageUrl: initialInput.imageUrl,
    optionsJson: initialInput.optionsJson,
  );
});
