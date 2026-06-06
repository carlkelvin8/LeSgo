import 'package:flutter/material.dart';
import '../../../../../../core/utils/menu_item_options.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MenuItemOptionsSelector extends StatelessWidget {
  final MenuItemOptionGroups optionGroups;
  final MenuOptionChoice? selectedSize;
  final MenuOptionChoice? selectedFlavor;
  final Map<String, int> addonQuantities;
  final ValueChanged<MenuOptionChoice> onSizeSelected;
  final ValueChanged<MenuOptionChoice> onFlavorSelected;
  final void Function(MenuOptionChoice addon, int quantity) onAddonQuantityChanged;

  const MenuItemOptionsSelector({
    super.key,
    required this.optionGroups,
    required this.selectedSize,
    required this.selectedFlavor,
    required this.addonQuantities,
    required this.onSizeSelected,
    required this.onFlavorSelected,
    required this.onAddonQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (optionGroups.hasSizes) ...[
          _OptionGroupSection(
            title: 'Select Size',
            choices: optionGroups.sizes,
            selected: selectedSize,
            onSelected: onSizeSelected,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
        if (optionGroups.hasFlavors) ...[
          _OptionGroupSection(
            title: 'Select Flavor',
            choices: optionGroups.flavors,
            selected: selectedFlavor,
            onSelected: onFlavorSelected,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
        if (optionGroups.hasAddons) ...[
          Text(
            'Add-ons',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ...optionGroups.addons.map((addon) {
            final qty = addonQuantities[addon.label] ?? 0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 10),
              ),
              child: _AddonRow(
                choice: addon,
                quantity: qty,
                onChanged: (value) => onAddonQuantityChanged(addon, value),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _OptionGroupSection extends StatelessWidget {
  final String title;
  final List<MenuOptionChoice> choices;
  final MenuOptionChoice? selected;
  final ValueChanged<MenuOptionChoice> onSelected;

  const _OptionGroupSection({
    required this.title,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Wrap(
          spacing: ResponsiveUtils.spacing(context, 10),
          runSpacing: ResponsiveUtils.spacing(context, 10),
          children: choices.map((choice) {
            final isSelected = selected?.label == choice.label;
            return InkWell(
              onTap: () => onSelected(choice),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 10),
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5F2D82) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5F2D82)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  choice.price > 0
                      ? '${choice.label} (+₱${choice.price.toStringAsFixed(0)})'
                      : choice.label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AddonRow extends StatelessWidget {
  final MenuOptionChoice choice;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _AddonRow({
    required this.choice,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                choice.label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (choice.price > 0)
                Text(
                  '+₱${choice.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: const Color(0xFF5F2D82),
        ),
        Text(
          '$quantity',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: const Color(0xFF5F2D82),
        ),
      ],
    );
  }
}
