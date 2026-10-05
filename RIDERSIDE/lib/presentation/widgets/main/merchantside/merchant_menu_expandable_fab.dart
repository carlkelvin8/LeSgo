import 'package:flutter/material.dart';

class MerchantMenuExpandableFab extends StatefulWidget {
  final VoidCallback onAddMenu;
  final VoidCallback onAddCategory;

  const MerchantMenuExpandableFab({
    super.key,
    required this.onAddMenu,
    required this.onAddCategory,
  });

  @override
  State<MerchantMenuExpandableFab> createState() =>
      _MerchantMenuExpandableFabState();
}

class _MerchantMenuExpandableFabState extends State<MerchantMenuExpandableFab> {
  static const Color _brandPurple = Color(0xFF5F2D82);
  static const Color _brandLavender = Color(0xFFEAD3F7);

  bool _isExpanded = false;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  static const double _quickActionWidth = 168;

  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: _quickActionWidth,
      child: ElevatedButton.icon(
        onPressed: () {
          onPressed();
          setState(() {
            _isExpanded = false;
          });
        },
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: _brandLavender,
          foregroundColor: _brandPurple,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IgnorePointer(
                ignoring: !_isExpanded,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: _isExpanded ? Offset.zero : const Offset(0, 0.25),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _isExpanded ? 1 : 0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: _buildQuickAction(
                        label: 'Add Category',
                        icon: Icons.category_outlined,
                        onPressed: widget.onAddCategory,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !_isExpanded,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: _isExpanded ? Offset.zero : const Offset(0, 0.25),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _isExpanded ? 1 : 0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: _buildQuickAction(
                        label: 'Add Menu',
                        icon: Icons.restaurant_menu_outlined,
                        onPressed: widget.onAddMenu,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: _brandPurple,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isExpanded ? 0.125 : 0,
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
