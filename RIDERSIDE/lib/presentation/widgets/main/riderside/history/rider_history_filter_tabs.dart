import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Pure presentational filter tabs — receives filter list and selection from outside.
class RiderHistoryFilterTabs extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const RiderHistoryFilterTabs({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 14),
                  vertical: ResponsiveUtils.spacing(context, 8),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5F2D82)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.spacing(context, 20),
                  ),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
