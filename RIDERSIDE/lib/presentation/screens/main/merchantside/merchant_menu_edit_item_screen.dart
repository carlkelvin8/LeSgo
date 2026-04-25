import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/merchantside/merchant_menu_item_form_provider.dart';
import '../../../controllers/merchantside/merchant_menu_item_form_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _formInput = MerchantMenuItemFormInput.edit(widget.initialItem);
    _controller = MerchantMenuItemFormController(
      initialItemName: widget.initialItem?['itemName'] ?? 'Sun Sets Pizza',
      initialPrice: widget.initialItem?['price'] ?? '300.00',
      initialDescription: widget.initialItem?['description'] ??
          'Pepperoni, Hawaiian, All Meat. Our signature sunset crust with a triple-meat blend and premium mozzarella.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        // Hero Section
        MerchantItemHeroSection(),
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
      ],
    );
  }
}
