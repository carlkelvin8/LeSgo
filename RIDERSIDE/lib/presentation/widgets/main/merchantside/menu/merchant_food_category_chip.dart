import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/menu_image_widget.dart';

class MerchantFoodCategoryChip extends StatefulWidget {
  final String label;
  final String icon;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  const MerchantFoodCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.imageUrl,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<MerchantFoodCategoryChip> createState() =>
      _MerchantFoodCategoryChipState();
}

class _MerchantFoodCategoryChipState extends State<MerchantFoodCategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;

    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(
        scale: 1.0 - .03 * _press.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 72,
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0xFF8B3FC8), Color(0xFF5F2D82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: sel ? null : const Color(0xFFF4F0FA),
            borderRadius: BorderRadius.circular(18),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF5F2D82).withValues(alpha: .35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -3,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel
                      ? Colors.white.withValues(alpha: .22)
                      : Colors.white,
                  boxShadow: sel
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.imageUrl != null &&
                        widget.imageUrl!.trim().isNotEmpty
                    ? MenuImageWidget(
                        source: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: Center(
                          child: Text(widget.icon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      )
                    : Center(
                        child: Text(widget.icon,
                            style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 9.5,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel
                      ? Colors.white
                      : const Color(0xFF4A3060),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
