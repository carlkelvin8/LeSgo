import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/menu_image_widget.dart';

class MerchantOrderCard extends StatefulWidget {
  final String orderId;
  final String itemName;
  final String price;
  final String customerName;
  final String address;
  final String? imageUrl;
  final String? specialInstructionsPreview;
  final Widget? trailingBadge;

  const MerchantOrderCard({
    super.key,
    required this.orderId,
    required this.itemName,
    required this.price,
    required this.customerName,
    required this.address,
    this.imageUrl,
    this.specialInstructionsPreview,
    this.trailingBadge,
  });

  @override
  State<MerchantOrderCard> createState() => _MerchantOrderCardState();
}

class _MerchantOrderCardState extends State<MerchantOrderCard>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(
        scale: 1.0 - .012 * _press.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1730) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2E2540)
                  : const Color(0xFFEDE9F2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5F2D82)
                    .withValues(alpha: isDark ? .08 : .05),
                blurRadius: 14,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: MenuImageWidget(
                    source: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: const Color(0xFFEDD9FF),
                      child: const Icon(Icons.restaurant_rounded,
                          color: Color(0xFF9B70CC), size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID + price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.orderId,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF9A85B8)
                                  : const Color(0xFFAA90C0),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F2D82).withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PHP ${widget.price}',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5F2D82),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Item name
                    Text(
                      widget.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Customer + address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: Color(0xFF9B70CC)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFFD4C8E8)
                                  : const Color(0xFF4A3060),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Color(0xFF9B70CC)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF9A85B8)
                                  : const Color(0xFFAA90C0),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Special instructions
                    if (widget.specialInstructionsPreview != null &&
                        widget.specialInstructionsPreview!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: .40),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sticky_note_2_outlined,
                                size: 12, color: Color(0xFFB45309)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.specialInstructionsPreview!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (widget.trailingBadge != null) ...[
                      const SizedBox(height: 6),
                      widget.trailingBadge!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
