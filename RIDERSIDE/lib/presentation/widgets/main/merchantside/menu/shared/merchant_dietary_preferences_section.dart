import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantDietaryPreferencesSection extends StatefulWidget {
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggle;
  final List<String> availableTags;

  const MerchantDietaryPreferencesSection({
    super.key,
    required this.selectedTags,
    required this.onTagToggle,
    this.availableTags = const ['Vegan', 'Vegetarian', 'Gluten-Free', 'Dairy-Free', 'Spicy', 'Nut-Free'],
  });

  @override
  State<MerchantDietaryPreferencesSection> createState() =>
      _MerchantDietaryPreferencesSectionState();
}

class _MerchantDietaryPreferencesSectionState
    extends State<MerchantDietaryPreferencesSection> {
  final TextEditingController _customTagController = TextEditingController();

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final customTag = _customTagController.text.trim();
    if (customTag.isEmpty) return;

    if (!widget.selectedTags.contains(customTag)) {
      widget.onTagToggle(customTag);
    }
    _customTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mergedTags = <String>{...widget.availableTags, ...widget.selectedTags}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Preferences',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTagController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustomTag(),
                decoration: InputDecoration(
                  hintText: 'Add custom preference',
                  hintStyle: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade500,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 12),
                    vertical: ResponsiveUtils.spacing(context, 8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Color(0xFF5F2D82)),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            ElevatedButton(
              onPressed: _addCustomTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 12),
                  vertical: ResponsiveUtils.spacing(context, 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        Wrap(
          spacing: ResponsiveUtils.spacing(context, 8),
          runSpacing: ResponsiveUtils.spacing(context, 8),
          children: mergedTags.map((tag) {
            final isSelected = widget.selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              onSelected: (_) => widget.onTagToggle(tag),
              label: Text(
                tag,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF5F2D82),
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF5F2D82),
              side: BorderSide(
                color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
