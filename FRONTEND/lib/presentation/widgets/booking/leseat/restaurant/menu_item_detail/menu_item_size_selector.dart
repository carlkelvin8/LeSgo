import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MenuItemSizeSelector extends StatelessWidget {
  final List<String> sizeOptions;
  final String? selectedSize;
  final Function(String) onSizeSelected;

  const MenuItemSizeSelector({
    super.key,
    required this.sizeOptions,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Size',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sizeOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final size = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < sizeOptions.length - 1 
                      ? ResponsiveUtils.spacing(context, 12) 
                      : 0,
                ),
                child: _SizeButton(
                  label: size.toUpperCase(),
                  isSelected: selectedSize == size,
                  onTap: () => onSizeSelected(size),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.spacing(context, 12),
          horizontal: ResponsiveUtils.spacing(context, 20),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
