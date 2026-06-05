import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';
import 'merchant_menu_provider.dart';

class MerchantAddCategoryFormState {
  final String categoryName;
  final String iconEmoji;
  final String? imagePath;
  final bool isSubmitting;
  final String? errorMessage;

  MerchantAddCategoryFormState({
    required this.categoryName,
    this.iconEmoji = '🍴',
    this.imagePath,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isValid => categoryName.isNotEmpty && categoryName.length >= 2;

  MerchantAddCategoryFormState copyWith({
    String? categoryName,
    String? iconEmoji,
    String? imagePath,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MerchantAddCategoryFormState(
      categoryName: categoryName ?? this.categoryName,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      imagePath: imagePath ?? this.imagePath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class MerchantAddCategoryFormNotifier extends StateNotifier<MerchantAddCategoryFormState> {
  final Ref _ref;

  MerchantAddCategoryFormNotifier(this._ref, {String? categoryName, String? iconEmoji})
      : super(MerchantAddCategoryFormState(
          categoryName: categoryName ?? '',
          iconEmoji: iconEmoji ?? '🍴',
        ));

  void updateCategoryName(String value) {
    state = state.copyWith(categoryName: value);
  }

  void updateIconEmoji(String value) {
    state = state.copyWith(iconEmoji: value);
  }

  void updateImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  Future<bool> attemptSubmit() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Category name must be at least 2 characters');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
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

      print('🔍 Creating category for partner_id: $partnerId');
      
      final dataSource = _ref.read(merchantDataSourceProvider);
      final request = CreateMenuCategoryRequest(
        name: state.categoryName,
        iconEmoji: state.iconEmoji,
        imagePath: state.imagePath,
      );
      
      await dataSource.createMenuCategory(partnerId, request);
      print('✅ Menu category created successfully');
      
      // Refresh menu providers
      _ref.invalidate(merchantMenuProvider);
      _ref.invalidate(merchantMenuItemsProvider);

      // Success
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('❌ Error creating category: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create category: ${e.toString()}',
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
  return MerchantAddCategoryFormNotifier(ref);
});
