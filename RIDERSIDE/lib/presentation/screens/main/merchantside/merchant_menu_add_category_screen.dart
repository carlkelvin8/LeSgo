import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../controllers/merchantside/merchant_add_category_form_controller.dart';
import '../../../provider/main/merchantside/merchant_add_category_form_provider.dart';
import '../../../widgets/widgets.dart';

class MerchantMenuAddCategoryScreen extends ConsumerStatefulWidget {
  final MenuCategoryDto? editingCategory;

  const MerchantMenuAddCategoryScreen({
    super.key,
    this.editingCategory,
  });

  @override
  ConsumerState<MerchantMenuAddCategoryScreen> createState() =>
      _MerchantMenuAddCategoryScreenState();
}

class _MerchantMenuAddCategoryScreenState
    extends ConsumerState<MerchantMenuAddCategoryScreen> {
  late MerchantAddCategoryFormController _controller;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.editingCategory != null;

  @override
  void initState() {
    super.initState();
    final category = widget.editingCategory;
    _controller = MerchantAddCategoryFormController(
      initialCategoryName: category?.name,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(merchantAddCategoryFormProvider.notifier);
      if (category != null) {
        notifier.initForEdit(
          categoryId: category.id,
          name: category.name,
          iconEmoji: category.iconEmoji,
          imageUrl: category.imageUrl,
        );
      } else {
        notifier.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        ref
            .read(merchantAddCategoryFormProvider.notifier)
            .updateImagePath(image.path);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to pick image');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(merchantAddCategoryFormProvider);
    final notifier = ref.read(merchantAddCategoryFormProvider.notifier);
    final dishCount = widget.editingCategory?.availableItems?.length ?? 0;

    ref.listen(merchantAddCategoryFormProvider, (previous, next) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
      }
      if (next.isSubmitting == false &&
          previous?.isSubmitting == true &&
          next.errorMessage == null) {
        SnackBarUtils.showSuccess(
          context,
          _isEditMode
              ? 'Category updated successfully'
              : 'Category created successfully',
        );
        Navigator.pop(context);
      }
    });

    return MerchantFormLayout(
      formKey: _controller.formKey,
      stickyBottomAction: MerchantFormActionButtonsSection(
        onDiscard: () => Navigator.pop(context),
        onSubmit: () {
          if (_controller.formKey.currentState!.validate()) {
            notifier.updateCategoryName(_controller.categoryNameController.text);
            notifier.attemptSubmit();
          }
        },
        submitLabel: _isEditMode ? 'Save Changes' : 'Create Category',
        isSubmitting: formState.isSubmitting,
      ),
      children: [
        Text(
          _isEditMode ? 'Edit Category' : 'New Category',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SectionSpacer(units: 20),
        Text(
          'Category Name',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SectionSpacer(units: 8),
        CustomTextField(
          hintText: 'e.g., Coffee, Appetizers, Desserts',
          controller: _controller.categoryNameController,
        ),
        SectionSpacer(units: 28),
        MerchantCategoryImageUploadSection(
          uploadedImagePath: formState.previewImageSource,
          onTap: _pickImage,
        ),
        SectionSpacer(units: 24),
        MerchantCategoryLivePreviewSection(
          categoryName: _controller.categoryNameController.text,
          categoryImagePath: formState.previewImageSource,
          dishCount: dishCount,
        ),
        SectionSpacer(units: 32),
        MerchantProTipSection(
          tipText: _isEditMode
              ? 'Updating the category name or image will reflect across all menu items in this category.'
              : 'Use clear, descriptive category names so customers can quickly find what they\'re looking for.',
        ),
        SectionSpacer(units: 32),
        SectionSpacer(),
      ],
    );
  }
}
