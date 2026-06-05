import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/merchantside/merchant_menu_item_form_provider.dart';
import '../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../controllers/merchantside/merchant_menu_item_form_controller.dart';
import '../../../widgets/main/merchantside/menu/shared/merchant_dietary_preferences_section.dart';
import '../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';
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
      initialItemName: widget.initialItem?['itemName'] ??
          widget.initialItem?['name'] ??
          '',
      initialPrice: widget.initialItem?['price'] ?? '0.00',
      initialDescription: widget.initialItem?['description'] ?? '',
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final formProvider = merchantMenuItemFormProvider(_formInput);
      final notifier = ref.read(formProvider.notifier);

      final categoryName = widget.initialItem?['category'] ?? '';
      if (categoryName.isEmpty && _formInput.menuCategoryId != null) {
        final menu = await ref.read(merchantMenuProvider.future);
        if (menu != null && mounted) {
          for (final category in menu.categories) {
            if (category.id == _formInput.menuCategoryId) {
              notifier.updateCategory(category.name);
              break;
            }
          }
        }
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

    final itemId = int.tryParse(widget.initialItem?['id'] ?? '');
    final itemName = widget.initialItem?['name'] ??
        widget.initialItem?['itemName'] ??
        'this item';

    return MerchantFormLayout(
      formKey: _controller.formKey,
      stickyBottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (itemId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: formState.isSubmitting
                    ? null
                    : () async {
                        final deleted = await confirmAndDeleteMerchantMenuItem(
                          context,
                          ref,
                          itemId: itemId,
                          itemName: itemName,
                        );
                        if (deleted && mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: Text(
                  'Delete Item',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          MerchantFormActionButtonsSection(
            onDiscard: () => Navigator.pop(context),
            onSubmit: () {
              if (_controller.formKey.currentState!.validate()) {
                notifier.attemptSubmit();
              }
            },
            submitLabel: 'Save Item',
            isSubmitting: formState.isSubmitting,
          ),
        ],
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
      ],
    );
  }
}
