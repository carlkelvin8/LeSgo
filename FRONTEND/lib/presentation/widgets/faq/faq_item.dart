import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/faq/faq.dart';

class FaqItem extends StatefulWidget {
  final Faq faq;
  final int index;
  final bool isFirst;

  const FaqItem({
    super.key,
    required this.faq,
    required this.index,
    this.isFirst = false,
  });

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _rotate = Tween<double>(begin: 0, end: .5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    if (widget.isFirst) {
      _isOpen = true;
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  // Assign a subtle accent per item, cycling through a palette
  static const _accents = [
    Color(0xFF7B3FC8),
    Color(0xFF5F2D82),
    Color(0xFF9040C0),
    Color(0xFF6A2EA0),
    Color(0xFF4E2070),
  ];

  Color get _accent => _accents[widget.index % _accents.length];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final isOpen = _isOpen;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: isOpen ? .12 : .05),
                blurRadius: isOpen ? 20 : 10,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
            border: Border.all(
              color: isOpen
                  ? _accent.withValues(alpha: .20)
                  : AppColors.border(context, Color(0xFFF0EBF6)),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(18),
                splashColor: _accent.withValues(alpha: .06),
                highlightColor: _accent.withValues(alpha: .04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Question row ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number badge
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 1, right: 12),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? _accent
                                  : _accent.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.index + 1}',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isOpen
                                      ? Colors.white
                                      : _accent,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),

                          // Question text
                          Expanded(
                            child: Text(
                              widget.faq.question,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isOpen
                                    ? AppColors.foreground(context, Color(0xFF1A0A2E))
                                    : AppColors.foreground(context, Color(0xFF2E1A4A)),
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Animated chevron
                          RotationTransition(
                            turns: _rotate,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? _accent.withValues(alpha: .10)
                                    : AppColors.surface(context, Color(0xFFF3ECF9)),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Answer (animated) ───────────────────────────────
                    SizeTransition(
                      sizeFactor: _expand,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Column(
                          children: [
                            // Divider
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _accent.withValues(alpha: .15),
                                    _accent.withValues(alpha: .04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(56, 12, 16, 18),
                              child: Text(
                                widget.faq.answer,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.foreground(context, Color(0xFF4A3060)),
                                  height: 1.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
