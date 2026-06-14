import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/merchantside/merchant_menu_item_form_provider.dart';
import '../../../controllers/merchantside/merchant_menu_item_form_controller.dart';
import '../../../widgets/main/merchantside/menu/shared/merchant_dietary_preferences_section.dart';
import '../../../widgets/main/merchantside/menu/shared/merchant_item_options_section.dart';
import '../../../widgets/main/merchantside/menu/shared/merchant_item_inventory_section.dart';

import 'package:image_picker/image_picker.dart';

class MerchantMenuAddItemScreen extends ConsumerStatefulWidget {
  const MerchantMenuAddItemScreen({super.key});

  @override
  ConsumerState<MerchantMenuAddItemScreen> createState() =>
      _MerchantMenuAddItemScreenState();
}

class _MerchantMenuAddItemScreenState extends ConsumerState<MerchantMenuAddItemScreen> {
  static const _addInput = MerchantMenuItemFormInput.add();
  late MerchantMenuItemFormController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = MerchantMenuItemFormController();
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
        notifier.updateLocalImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to pick image');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = merchantMenuItemFormProvider(_addInput);
    final formState = ref.watch(formProvider);
    final notifier = ref.read(formProvider.notifier);

    ref.listen(
      formProvider,
      (previous, next) {
        if (next.errorMessage != null) {
          SnackBarUtils.showError(context, next.errorMessage!);
        }
        // Handle success - navigate when form state shows success
        if (next.isSubmitting == false && previous?.isSubmitting == true && next.errorMessage == null) {
          SnackBarUtils.showSuccess(context, 'Item added successfully');
          Navigator.pop(context);
        }
      },
    );

    return MerchantFormLayout(
      formKey: _controller.formKey,
      stickyBottomAction: MerchantFormActionButtonsSection(
        onDiscard: () => Navigator.pop(context),
        onSubmit: () {
          if (_controller.formKey.currentState!.validate()) {
            notifier.attemptSubmit();
          }
        },
        submitLabel: 'Add Item',
        isSubmitting: formState.isSubmitting,
      ),
      children: [
        // Image Upload Section
        MerchantItemImageUploadSection(
          uploadedImagePath: formState.displayImageSource,
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
        MerchantItemOptionsSection(
          optionGroups: formState.menuOptions,
          onChanged: notifier.updateMenuOptions,
        ),
        SectionSpacer(),
        MerchantItemInventorySection(
          trackStock: formState.trackStock,
          stock: formState.stock,
          autoHideWhenEmpty: formState.autoHideWhenEmpty,
          liveOnMenu: formState.liveOnMenu,
          onTrackStockChanged: notifier.toggleTrackStock,
          onStockChanged: notifier.updateStock,
          onAutoHideChanged: notifier.toggleAutoHideWhenEmpty,
          onLiveOnMenuChanged: notifier.toggleLiveOnMenu,
        ),
        SectionSpacer(),
      ],
    );
  }
}
