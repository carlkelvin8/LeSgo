import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderSwipeAcceptButton extends StatefulWidget {
  final VoidCallback onAccepted;
  final String text;

  const RiderSwipeAcceptButton({
    super.key,
    required this.onAccepted,
    this.text = 'Swipe to get booking',
  });

  @override
  State<RiderSwipeAcceptButton> createState() => _RiderSwipeAcceptButtonState();
}

class _RiderSwipeAcceptButtonState extends State<RiderSwipeAcceptButton>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isAccepted = false;
  late AnimationController _slideBackController;
  late Animation<double> _slideBackAnimation;

  @override
  void initState() {
    super.initState();
    _slideBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideBackController.addListener(() {
      setState(() {
        _dragOffset = _slideBackAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _slideBackController.dispose();
    super.dispose();
  }

  void _onDragUpdate(
    DragUpdateDetails details,
    double maxWidth,
    double thumbWidth,
  ) {
    if (_isAccepted) return;

    setState(() {
      _dragOffset += details.primaryDelta!;
      // Constrain dragging: prevent moving left of start, or past max width (minus thumb size)
      if (_dragOffset < 0) {
        _dragOffset = 0;
      } else if (_dragOffset > maxWidth - thumbWidth) {
        _dragOffset = maxWidth - thumbWidth;
      }
    });
  }

  void _onDragEnd(DragEndDetails details, double maxWidth, double thumbWidth) {
    if (_isAccepted) return;

    // Threshold = 75% of the actual draggable range (not total width)
    final double maxDrag = maxWidth - thumbWidth;
    final double threshold = maxDrag * 0.75;
    if (_dragOffset >= threshold) {
      setState(() {
        _dragOffset = maxDrag;
        _isAccepted = true;
      });
      widget.onAccepted();
    } else {
      // Animate back to original position
      _slideBackAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _slideBackController, curve: Curves.easeOut),
      );
      _slideBackController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveUtils.spacing(context, 48);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF9035E3), // Primary purple from Lesgo scheme
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Centered Text - Clipped so the thumb naturally covers it as it moves right
              Positioned.fill(
                child: _isAccepted
                    ? const SizedBox.shrink()
                    : ClipRect(
                        // The text will slowly disappear as the thumb drags over it
                        clipper: _SwipeTextClipper(
                          dragOffset: _dragOffset,
                          thumbWidth:
                              (height * 1.5) +
                              8, // Accurate width representing thumb + margin
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: ResponsiveUtils.spacing(context, 24),
                            ),
                            child: Text(
                              widget.text,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              // "Accepted" label shown full-width when swiped
              if (_isAccepted)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Accepted',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Draggable Thumb
              Positioned(
                left: _dragOffset,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxWidth, (height * 1.5) + 8),
                  onHorizontalDragEnd: (details) =>
                      _onDragEnd(details, maxWidth, (height * 1.5) + 8),
                  child: Container(
                    width:
                        height *
                        1.5, // Make the width 1.5x the height for a capsule look
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      color: const Color.fromARGB(
                        255,
                        234,
                        215,
                        247,
                      ), // Light purple to match design
                    ),
                    child: Center(
                      child: Icon(
                        _isAccepted ? Icons.check : Icons.arrow_forward_rounded,
                        color: const Color(
                          0xFF9035E3,
                        ), // Dark purple arrow against light background
                        size: ResponsiveUtils.fontSize(context, 20),
                        weight: 400, // Explicitly requesting thinner weight
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom clipper to hide the text as the thumb slides over it
class _SwipeTextClipper extends CustomClipper<Rect> {
  final double dragOffset;
  final double thumbWidth;

  _SwipeTextClipper({required this.dragOffset, required this.thumbWidth});

  @override
  Rect getClip(Size size) {
    // We only show the text to the RIGHT of the thumb.
    // So the visible rectangle starts exactly after the thumb finishes.
    return Rect.fromLTRB(dragOffset + thumbWidth, 0.0, size.width, size.height);
  }

  @override
  bool shouldReclip(_SwipeTextClipper oldClipper) {
    return oldClipper.dragOffset != dragOffset;
  }
}
