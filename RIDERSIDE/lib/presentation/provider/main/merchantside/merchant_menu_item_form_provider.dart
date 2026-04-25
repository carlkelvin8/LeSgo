import 'package:flutter_riverpod/flutter_riverpod.dart';

class MerchantMenuItemFormInput {
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
    this.itemName,
    this.price,
    this.description,
    this.category,
    this.selectedTags,
    this.liveOnMenu,
  });

  const MerchantMenuItemFormInput.add()
      : itemName = '',
        price = '0.00',
        description = '',
        category = 'Pizza',
        selectedTags = null,
        liveOnMenu = null;

  factory MerchantMenuItemFormInput.edit(Map<String, String>? initialItem) {
    return MerchantMenuItemFormInput(
      itemName: initialItem?['itemName'] ?? initialItem?['name'],
      price: initialItem?['price'],
      description: initialItem?['description'],
      category: initialItem?['category'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantMenuItemFormInput &&
        other.itemName == itemName &&
        other.price == price &&
        other.description == description &&
        other.category == category &&
        other.selectedTags == selectedTags &&
        other.liveOnMenu == liveOnMenu;
  }

  @override
  int get hashCode => Object.hash(
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
  MerchantMenuItemFormNotifier({
    String? itemName,
    String? price,
    String? description,
    String? category,
    List<String>? selectedTags,
    bool? liveOnMenu,
  }) : super(
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      // Success
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save item. Please try again.',
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
    itemName: initialInput.itemName,
    price: initialInput.price,
    description: initialInput.description,
    category: initialInput.category,
    selectedTags: initialInput.selectedTags?.split(',').toList(),
    liveOnMenu: initialInput.liveOnMenu,
  );
});
