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
  Animation<double>? _slideBackAnimation;
  double _maxWidth = 0;
  double _height = 0;

  double get _thumbWidth => (_height * 1.5) + 8;

  @override
  void initState() {
    super.initState();
    _slideBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _slideBackController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAccepted) return;

    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset < 0) {
        _dragOffset = 0;
      } else if (_dragOffset > _maxWidth - _thumbWidth) {
        _dragOffset = _maxWidth - _thumbWidth;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAccepted) return;

    final double maxDrag = _maxWidth - _thumbWidth;
    final double threshold = maxDrag * 0.75;
    if (_dragOffset >= threshold) {
      setState(() => _dragOffset = maxDrag);
      _accept();
    } else {
      _slideBackAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _slideBackController, curve: Curves.easeOut),
      );
      _slideBackController.forward(from: 0.0);
    }
  }

  void _accept() {
    if (_isAccepted) return;
    setState(() => _isAccepted = true);
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    _height = ResponsiveUtils.spacing(context, 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _slideBackController,
          builder: (context, child) {
            final displayOffset = (_slideBackController.isAnimating && _slideBackAnimation != null)
                ? _slideBackAnimation!.value
                : _dragOffset;

            return LayoutBuilder(
              builder: (context, constraints) {
                _maxWidth = constraints.maxWidth;

                return Semantics(
                  label: widget.text,
                  hint: 'Swipe right to accept this booking',
                  child: Container(
                    width: double.infinity,
                    height: _height,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9035E3),
                      borderRadius: BorderRadius.circular(_height / 2),
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
                        Positioned.fill(
                          child: _isAccepted
                              ? const SizedBox.shrink()
                              : ClipRect(
                                  clipper: _SwipeTextClipper(
                                    dragOffset: displayOffset,
                                    thumbWidth: _thumbWidth,
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
                        Positioned(
                          left: displayOffset,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onHorizontalDragUpdate: _onDragUpdate,
                            onHorizontalDragEnd: _onDragEnd,
                            child: Container(
                              width: _height * 1.5,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(_height / 2),
                                color: const Color.fromARGB(255, 234, 215, 247),
                              ),
                              child: Center(
                                child: Icon(
                                  _isAccepted ? Icons.check : Icons.arrow_forward_rounded,
                                  color: const Color(0xFF9035E3),
                                  size: ResponsiveUtils.fontSize(context, 20),
                                  weight: 400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (!_isAccepted) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Semantics(
            button: true,
            label: 'Accept booking',
            child: TextButton(
              onPressed: _accept,
              child: Text(
                'Accept booking',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F2D82),
                ),
              ),
            ),
          ),
        ],
      ],
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
