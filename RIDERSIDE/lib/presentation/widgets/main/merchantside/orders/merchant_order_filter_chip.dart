import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Status accent colors ─────────────────────────────────────────────────────
Color _accentForLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('all')) return const Color(0xFF5F2D82);
  if (l.contains('pending')) return const Color(0xFFF59E0B);
  if (l.contains('pick')) return const Color(0xFF2563EB);
  if (l.contains('ready')) return const Color(0xFF16A34A);
  if (l.contains('deliver')) return const Color(0xFF0891B2);
  if (l.contains('cancel')) return const Color(0xFFDC2626);
  return const Color(0xFF5F2D82);
}

class MerchantOrderFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const MerchantOrderFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<MerchantOrderFilterChip> createState() =>
      _MerchantOrderFilterChipState();
}

class _MerchantOrderFilterChipState extends State<MerchantOrderFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 85),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentForLabel(widget.label);
    final sel = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - .03 * _press.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(
                    colors: [
                      Color.lerp(accent, Colors.white, .15)!,
                      accent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel
                ? null
                : (isDark ? const Color(0xFF1E1730) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel
                  ? accent
                  : (isDark
                      ? const Color(0xFF2E2540)
                      : const Color(0xFFE8E0F0)),
              width: sel ? 0 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: -3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF9A85B8)
                      : const Color(0xFF776F80)),
            ),
          ),
        ),
      ),
    );
  }
}
