import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';
import 'merchant_menu_provider.dart';

class MerchantMenuItemFormInput {
  final int? itemId; // For edit mode
  final String? itemName;
  final String? price;
  final String? description;
  final String? category;
  final String? selectedTags;
  final bool? liveOnMenu;

  // Backward-compatibility shim for hot-reload sessions that still look up this removed getter.
  @Deprecated('variationLabels has been removed')
  String? get variationLabels => null;

  const MerchantMenuItemFormInput({
    this.itemId,
    this.itemName,
    this.price,
    this.description,
    this.category,
    this.selectedTags,
    this.liveOnMenu,
  });

  const MerchantMenuItemFormInput.add()
      : itemId = null,
        itemName = '',
        price = '0.00',
        description = '',
        category = 'Pizza',
        selectedTags = null,
        liveOnMenu = null;

  factory MerchantMenuItemFormInput.edit(Map<String, String>? initialItem) {
    return MerchantMenuItemFormInput(
      itemId: initialItem?['id'] != null ? int.tryParse(initialItem!['id']!) : null,
      itemName: initialItem?['itemName'] ?? initialItem?['name'],
      price: initialItem?['price'],
      description: initialItem?['description'],
      category: initialItem?['category'],
    );
  }

  bool get isEditMode => itemId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantMenuItemFormInput &&
        other.itemId == itemId &&
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
  final bool isSubmitting;
  final String? errorMessage;

  MerchantMenuItemFormState({
    required this.itemName,
    required this.price,
    required this.description,
    required this.category,
    required this.selectedTags,
    required this.liveOnMenu,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isValid => itemName.isNotEmpty && price.isNotEmpty && price != '0.00';

  MerchantMenuItemFormState copyWith({
    String? itemName,
    String? price,
    String? description,
    String? category,
    List<String>? selectedTags,
    bool? liveOnMenu,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MerchantMenuItemFormState(
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      selectedTags: selectedTags ?? this.selectedTags,
      liveOnMenu: liveOnMenu ?? this.liveOnMenu,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class MerchantMenuItemFormNotifier extends StateNotifier<MerchantMenuItemFormState> {
  final Ref _ref;
  final int? _itemId; // For edit mode
  
  MerchantMenuItemFormNotifier(
    this._ref, {
    int? itemId,
    String? itemName,
    String? price,
    String? description,
    String? category,
    List<String>? selectedTags,
    bool? liveOnMenu,
  }) : _itemId = itemId,
       super(
    MerchantMenuItemFormState(
      itemName: itemName ?? '',
      price: price ?? '0.00',
      description: description ?? '',
      category: category ?? 'Pizza',
      selectedTags: selectedTags ?? [],
      liveOnMenu: liveOnMenu ?? true,
    ),
  );

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

  Future<bool> attemptSubmit() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // Parse price
      final priceValue = double.tryParse(state.price);
      if (priceValue == null || priceValue <= 0) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Invalid price value.',
        );
        return false;
      }
      
      final dataSource = _ref.read(merchantDataSourceProvider);
      
      if (_itemId != null) {
        // Edit mode - update existing item
        final request = UpdateMenuItemRequest(
          name: state.itemName,
          description: state.description.isEmpty ? null : state.description,
          price: priceValue,
          isAvailable: state.liveOnMenu,
        );
        
        await dataSource.updateMenuItem(_itemId!, request);
        print('✅ Menu item updated successfully');
      } else {
        // Add mode - create new item
        // Get partner_id from auth state
        final authState = _ref.read(riderAuthProvider);
        final partnerId = authState.user?.partnerId;
        
        if (partnerId == null) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Partner ID not found. Please login again.',
          );
          return false;
        }
        
        print('🔍 Using partner_id from auth: $partnerId');
        
        // Get menu to find category ID by name
        final menuAsync = await _ref.read(merchantMenuProvider.future);
        if (menuAsync == null) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to load menu categories.',
          );
          return false;
        }
        
        // Find category by name
        final category = menuAsync.categories.firstWhere(
          (cat) => cat.name == state.category,
          orElse: () => menuAsync.categories.first,
        );
        
        // Create request
        final request = CreateMenuItemRequest(
          menuCategoryId: category.id,
          name: state.itemName,
          description: state.description.isEmpty ? null : state.description,
          price: priceValue,
          isAvailable: state.liveOnMenu,
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
        errorMessage: 'Failed to save item: ${e.toString()}',
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
    itemName: initialInput.itemName,
    price: initialInput.price,
    description: initialInput.description,
    category: initialInput.category,
    selectedTags: initialInput.selectedTags?.split(',').toList(),
    liveOnMenu: initialInput.liveOnMenu,
  );
});
