import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/merchantside/merchant_menu_item_form_provider.dart';
import '../../../controllers/merchantside/merchant_menu_item_form_controller.dart';
import '../../../widgets/main/merchantside/menu/shared/merchant_dietary_preferences_section.dart';
import 'package:image_picker/image_picker.dart';

class MerchantMenuEditItemScreen extends ConsumerStatefulWidget {
  final Map<String, String>? initialItem;

  const MerchantMenuEditItemScreen({
    super.key,
    this.initialItem,
  });

  @override
  ConsumerState<MerchantMenuEditItemScreen> createState() =>
      _MerchantMenuEditItemScreenState();
}

class _MerchantMenuEditItemScreenState
    extends ConsumerState<MerchantMenuEditItemScreen> {
  late MerchantMenuItemFormController _controller;
  late MerchantMenuItemFormInput _formInput;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _formInput = MerchantMenuItemFormInput.edit(widget.initialItem);
    _controller = MerchantMenuItemFormController(
      initialItemName: widget.initialItem?['itemName'] ?? widget.initialItem?['name'] ?? 'Sun Sets Pizza',
      initialPrice: widget.initialItem?['price'] ?? '300.00',
      initialDescription: widget.initialItem?['description'] ??
          'Pepperoni, Hawaiian, All Meat. Our signature sunset crust with a triple-meat blend and premium mozzarella.',
    );
    
    // Defer the image path update until after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialItem?['imageUrl'] != null) {
        final formProvider = merchantMenuItemFormProvider(_formInput);
        ref.read(formProvider.notifier).updateImagePath(widget.initialItem!['imageUrl']);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(MerchantMenuItemFormNotifier notifier) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        notifier.updateImagePath(image.path);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to pick image');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = merchantMenuItemFormProvider(_formInput);
    final formState = ref.watch(formProvider);
    final notifier = ref.read(formProvider.notifier);

    ref.listen(formProvider, (previous, next) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
      }
      // Handle success - navigate when form state shows success
      if (next.isSubmitting == false && previous?.isSubmitting == true && next.errorMessage == null) {
        SnackBarUtils.showSuccess(context, 'Item updated successfully');
        Navigator.pop(context);
      }
    });

    return MerchantFormLayout(
      formKey: _controller.formKey,
      stickyBottomAction: MerchantFormActionButtonsSection(
        onDiscard: () => Navigator.pop(context),
        onSubmit: () {
          if (_controller.formKey.currentState!.validate()) {
            notifier.attemptSubmit();
          }
        },
        submitLabel: 'Save Item',
        isSubmitting: formState.isSubmitting,
      ),
      children: [
        // Image Upload Section
        MerchantItemImageUploadSection(
          uploadedImagePath: formState.imagePath,
          onTap: () => _pickImage(notifier),
        ),
        SectionSpacer(units: 20),
        // Item Name
        MerchantItemNameSection(
          controller: _controller.itemNameController,
          onChanged: notifier.updateItemName,
        ),
        SectionSpacer(),
        // Price
        MerchantItemPriceSection(
          controller: _controller.priceController,
          onChanged: notifier.updatePrice,
        ),
        SectionSpacer(),
        // Category Dropdown
        MerchantItemCategorySection(
          selectedCategory: formState.category,
          onChanged: (value) {
            if (value != null) {
              notifier.updateCategory(value);
            }
          },
        ),
        SectionSpacer(),
        // Description
        MerchantItemDescriptionSection(
          controller: _controller.descriptionController,
          onChanged: notifier.updateDescription,
        ),
        SectionSpacer(),
        MerchantDietaryPreferencesSection(
          selectedTags: formState.selectedTags.toSet(),
          onTagToggle: notifier.toggleTag,
        ),
        SectionSpacer(),
      ],
    );
  }
}
