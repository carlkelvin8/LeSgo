import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';

import '../../../core/utils/responsive_utils.dart';

class FilterSegment<T> {
  const FilterSegment(this.value, this.label);

  final T value;
  final String label;
}

/// A text-only filter with the sliding indicator used by Favorites.
class SegmentedFilterBar<T> extends StatefulWidget {
  const SegmentedFilterBar({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<FilterSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<SegmentedFilterBar<T>> createState() => _SegmentedFilterBarState<T>();
}

class _SegmentedFilterBarState<T> extends State<SegmentedFilterBar<T>>
    with TickerProviderStateMixin {
  late TabController _controller;

  int get _selectedIndex {
    final index = widget.segments.indexWhere((s) => s.value == widget.selected);
    return index < 0 ? 0 : index;
  }

  TabController _createController() => TabController(
    length: widget.segments.length,
    initialIndex: _selectedIndex,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(covariant SegmentedFilterBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.segments.length != _controller.length) {
      _controller.dispose();
      _controller = _createController();
    } else if (_controller.index != _selectedIndex) {
      _controller.animateTo(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FilterTabs(
    controller: _controller,
    labels: [for (final segment in widget.segments) segment.label],
    onTap: (index) => widget.onChanged(widget.segments[index].value),
  );
}

/// Shares the Favorites filter styling with screens that manage selection
/// independently from their content.
class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
  });

  final TabController controller;
  final List<String> labels;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    const labelPadding = EdgeInsets.symmetric(horizontal: 16);
    final style = TextStyle(
      fontFamily: 'TT Fors',
      fontSize: ResponsiveUtils.fontSize(context, 12),
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        );
        final widthPerTab = constraints.maxWidth / labels.length;
        final fits = labels.every((label) {
          painter.text = TextSpan(text: label, style: style);
          painter.layout();
          return painter.width + labelPadding.horizontal <= widthPerTab;
        });
        painter.dispose();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.grey[100]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: controller,
            onTap: onTap,
            isScrollable: !fits,
            tabAlignment: fits ? TabAlignment.fill : TabAlignment.start,
            labelPadding: labelPadding,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.accent(context, const Color(0xFF5F2D82)),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.foreground(
              context,
              Colors.grey[600]!,
            ),
            labelStyle: style,
            tabs: [for (final label in labels) Tab(text: label)],
          ),
        );
      },
    );
  }
}
