import 'package:flutter_riverpod/flutter_riverpod.dart';

class MerchantAddCategoryFormState {
  final String categoryName;
  final bool isSubmitting;
  final String? errorMessage;

  MerchantAddCategoryFormState({
    required this.categoryName,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isValid => categoryName.isNotEmpty && categoryName.length >= 2;

  MerchantAddCategoryFormState copyWith({
    String? categoryName,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MerchantAddCategoryFormState(
      categoryName: categoryName ?? this.categoryName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class MerchantAddCategoryFormNotifier extends StateNotifier<MerchantAddCategoryFormState> {
  MerchantAddCategoryFormNotifier({String? categoryName})
      : super(MerchantAddCategoryFormState(categoryName: categoryName ?? ''));

  void updateCategoryName(String value) {
    state = state.copyWith(categoryName: value);
  }

  Future<bool> attemptSubmit() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Category name must be at least 2 characters');
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
        errorMessage: 'Failed to create category. Please try again.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final merchantAddCategoryFormProvider =
    StateNotifierProvider<MerchantAddCategoryFormNotifier, MerchantAddCategoryFormState>((ref) {
  return MerchantAddCategoryFormNotifier();
});
