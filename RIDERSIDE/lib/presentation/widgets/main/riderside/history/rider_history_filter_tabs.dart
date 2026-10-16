import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/app_localization.dart';

class RiderHistoryFilterTabs extends ConsumerWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const RiderHistoryFilterTabs({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const _labels = {
    'All': 'Lahat',
    'Completed': 'Natapos',
    'Processing': 'Pinoproseso',
    'Cancelled': 'Kinansela',
  };

  static const _accents = {
    'All': Color(0xFF6D3EA0),
    'Completed': Color(0xFF16A34A),
    'Processing': Color(0xFFD97706),
    'Cancelled': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tl = ref.watch(appLanguageProvider) == AppLanguage.filipino;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final selected = filter == selectedFilter;
          final accent = _accents[filter] ?? const Color(0xFF6D3EA0);
          final label = tl ? (_labels[filter] ?? filter) : filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: label,
              selected: selected,
              accent: accent,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterChanged(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - .03 * _press.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(widget.accent, Colors.white, .15)!,
                        widget.accent,
                      ],
                    )
                  : null,
              color: widget.selected
                  ? null
                  : (widget.isDark
                      ? const Color(0xFF1E1730)
                      : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.selected
                    ? widget.accent
                    : (widget.isDark
                        ? const Color(0xFF2E2540)
                        : const Color(0xFFEDE9F2)),
                width: widget.selected ? 0 : 1,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: .35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -3,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: widget.selected
                    ? Colors.white
                    : (widget.isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFF776F80)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
