import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RiderHistoryBookingCard extends StatefulWidget {
  final String bookingId;
  final String restaurantName;
  final String address;
  final String price;
  final String status;
  final Color statusColor;
  final Color statusBackgroundColor;
  final int? proofImageCount;

  const RiderHistoryBookingCard({
    super.key,
    required this.bookingId,
    required this.restaurantName,
    required this.address,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.statusBackgroundColor,
    this.proofImageCount,
  });

  @override
  State<RiderHistoryBookingCard> createState() =>
      _RiderHistoryBookingCardState();
}

class _RiderHistoryBookingCardState extends State<RiderHistoryBookingCard>
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - .015 * _press.value,
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
            padding: const EdgeInsets.all(16),
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
                  color: const Color(0xFF5F2D82).withValues(
                      alpha: isDark ? .08 : .04),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82).withValues(
                        alpha: isDark ? .18 : .08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    size: 22,
                    color: Color(0xFF8B55B8),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ID + status row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.bookingId,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF9A85B8)
                                    : const Color(0xFFAA90C0),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.statusBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.status,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Price
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A0A2E),
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Name
                      Text(
                        widget.restaurantName,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF5F0FB)
                              : const Color(0xFF2E1A4A),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Address
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFFAA90C0),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF9A85B8)
                                    : const Color(0xFFAA90C0),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Proof images
                      if (widget.proofImageCount != null &&
                          widget.proofImageCount! > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F2D82)
                                .withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_rounded,
                                  size: 11, color: Color(0xFF8B55B8)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.proofImageCount} proof image${widget.proofImageCount! > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B55B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFFCCB0E0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
