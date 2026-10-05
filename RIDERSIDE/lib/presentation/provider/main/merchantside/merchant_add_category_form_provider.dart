import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';
import 'merchant_menu_provider.dart';

class MerchantAddCategoryFormState {
  final int? categoryId;
  final String categoryName;
  final String iconEmoji;
  final String? imagePath;
  final String? existingImageUrl;
  final bool isSubmitting;
  final String? errorMessage;

  MerchantAddCategoryFormState({
    this.categoryId,
    required this.categoryName,
    this.iconEmoji = '🍴',
    this.imagePath,
    this.existingImageUrl,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isEditMode => categoryId != null;

  String? get previewImageSource => imagePath ?? existingImageUrl;

  bool get isValid => categoryName.isNotEmpty && categoryName.length >= 2;

  MerchantAddCategoryFormState copyWith({
    int? categoryId,
    String? categoryName,
    String? iconEmoji,
    String? imagePath,
    String? existingImageUrl,
    bool? isSubmitting,
    String? errorMessage,
    bool clearImagePath = false,
  }) {
    return MerchantAddCategoryFormState(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class MerchantAddCategoryFormNotifier extends StateNotifier<MerchantAddCategoryFormState> {
  final Ref _ref;

  MerchantAddCategoryFormNotifier(this._ref)
      : super(MerchantAddCategoryFormState(categoryName: ''));

  void reset() {
    state = MerchantAddCategoryFormState(categoryName: '');
  }

  void initForEdit({
    required int categoryId,
    required String name,
    String? iconEmoji,
    String? imageUrl,
  }) {
    state = MerchantAddCategoryFormState(
      categoryId: categoryId,
      categoryName: name,
      iconEmoji: iconEmoji ?? '🍴',
      existingImageUrl: imageUrl,
    );
  }

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
      state = state.copyWith(
        errorMessage: 'Category name must be at least 2 characters',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final dataSource = _ref.read(merchantDataSourceProvider);

      if (state.isEditMode) {
        final request = UpdateMenuCategoryRequest(
          name: state.categoryName,
          iconEmoji: state.iconEmoji,
          imagePath: state.imagePath,
          iconUrl: state.imagePath == null ? state.existingImageUrl : null,
        );

        await dataSource.updateMenuCategory(state.categoryId!, request);
      } else {
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

        final request = CreateMenuCategoryRequest(
          name: state.categoryName,
          iconEmoji: state.iconEmoji,
          imagePath: state.imagePath,
        );

        await dataSource.createMenuCategory(partnerId, request);
      }

      _ref.invalidate(merchantMenuProvider);
      _ref.invalidate(merchantMenuItemsProvider);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: state.isEditMode
            ? 'Failed to update category: ${e.toString()}'
            : 'Failed to create category: ${e.toString()}',
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
