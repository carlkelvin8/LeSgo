import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/responsive_utils.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bgDeep = Color(0xFF0E0520); // near-black base
const _bgMid = Color(0xFF2A0D55); // deep indigo
const _bgLight = Color(0xFF5B2A90); // violet highlight
const _rimColor = Color(0xFFAA70E0); // border / accent
const _textWhite = Colors.white;
const _textSub = Color(0xFFB899D4); // subdued label
const _textFaint = Color(0xFF7A5FA0); // very faint

class WalletCard extends StatefulWidget {
  final double balance;
  final bool balanceVisible;
  final VoidCallback? onTap; // refresh
  final VoidCallback? onToggleVisibility;

  const WalletCard({
    super.key,
    required this.balance,
    this.balanceVisible = true,
    this.onTap,
    this.onToggleVisibility,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> with TickerProviderStateMixin {
  // Slow diagonal light sweep — 6 s, non-reverse
  late final AnimationController _sweep;
  // Gentle aurora shift — 5 s, reverse
  late final AnimationController _aurora;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final fmt = NumberFormat(
      '#,##0.00',
      'en_PH',
    ).format(widget.balance).split('.');

    return AnimatedBuilder(
      animation: Listenable.merge([_sweep, _aurora]),
      builder: (context, _) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3A0870).withValues(alpha: .55),
                blurRadius: 36,
                offset: const Offset(0, 18),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: _bgLight.withValues(alpha: .18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              painter: _BgPainter(sweep: _sweep.value, aurora: _aurora.value),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _rimColor.withValues(
                      alpha: .18 + .10 * _aurora.value,
                    ),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(26, 22, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top bar ──────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        SvgPicture.asset(
                          'assets/images/Logo.svg',
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            _textSub.withValues(alpha: .80),
                            BlendMode.srcIn,
                          ),
                        ),
                        const Spacer(),
                        // Eye toggle
                        _EyeButton(
                          visible: widget.balanceVisible,
                          aurora: _aurora.value,
                          onTap: widget.onToggleVisibility,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Balance label ────────────────────────────────────
                    Text(
                      tr(context, 'available_balance').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: _textFaint,
                        letterSpacing: 2.2,
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Balance number ───────────────────────────────────
                    widget.balanceVisible
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _BalanceDisplay(
                              integer: fmt.first,
                              decimal: fmt.last,
                            ),
                          )
                        : const _MaskedBalance(),

                    const SizedBox(height: 20),

                    // ── Thin accent line ─────────────────────────────────
                    _AccentLine(aurora: _aurora.value),
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

// ─── Eye button ───────────────────────────────────────────────────────────────
class _EyeButton extends StatelessWidget {
  final bool visible;
  final double aurora;
  final VoidCallback? onTap;

  const _EyeButton({required this.visible, required this.aurora, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: visible ? 'Hide balance' : 'Show balance',
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06 + .03 * aurora),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: .10 + .06 * aurora),
                width: .8,
              ),
            ),
            child: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _textSub,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Balance display ──────────────────────────────────────────────────────────
class _BalanceDisplay extends StatelessWidget {
  final String integer;
  final String decimal;

  const _BalanceDisplay({required this.integer, required this.decimal});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Currency
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '₱',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: _textSub,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 3),
        // Integer
        Text(
          integer,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 44,
            fontWeight: FontWeight.w600,
            color: _textWhite,
            letterSpacing: -1.5,
            height: 1.0,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        // Decimal
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '.$decimal',
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: _textSub,
              letterSpacing: -.5,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Masked balance ───────────────────────────────────────────────────────────
class _MaskedBalance extends StatelessWidget {
  const _MaskedBalance();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        6,
        (i) => Container(
          margin: const EdgeInsets.only(right: 10),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _textSub.withValues(alpha: .55),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Accent line ──────────────────────────────────────────────────────────────
class _AccentLine extends StatelessWidget {
  final double aurora;
  const _AccentLine({required this.aurora});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _rimColor.withValues(alpha: .40 + .20 * aurora),
            _rimColor.withValues(alpha: .08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─── Background painter ───────────────────────────────────────────────────────
// Three layers: gradient base → aurora orb → diagonal shimmer sweep
class _BgPainter extends CustomPainter {
  final double sweep; // 0→1
  final double aurora; // 0→1 (reverse)

  const _BgPainter({required this.sweep, required this.aurora});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1 ── Gradient base ───────────────────────────────────────────────────────
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgLight, _bgMid, _bgDeep],
          stops: [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    // 2 ── Aurora orb (drifts right↔left) ─────────────────────────────────────
    final orbX = size.width * (.10 + .35 * aurora);
    final orbY = -size.height * .15;
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF9040D0).withValues(alpha: .38),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(orbX, orbY),
                radius: size.width * .7,
              ),
            ),
    );

    // 3 ── Concentric rings (top-right, very subtle) ───────────────────────────
    final ringCenter = Offset(size.width * 1.05, size.height * .08);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (var i = 0; i < 6; i++) {
      ringPaint.color = const Color(
        0xFFCC99EE,
      ).withValues(alpha: .025 + i * .007 + .006 * aurora);
      canvas.drawCircle(ringCenter, size.width * (.20 + i * .10), ringPaint);
    }

    // 4 ── Diagonal shimmer sweep ──────────────────────────────────────────────
    // A narrow frosted-glass band glides across every 6 s
    final beamX = -size.width * .4 + size.width * 1.8 * sweep;
    canvas.save();
    canvas.transform(
      Matrix4(
        math.cos(math.pi / 10),
        math.sin(math.pi / 10),
        0,
        0,
        -math.sin(math.pi / 10),
        math.cos(math.pi / 10),
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        -size.height * .2,
        0,
        1,
      ).storage,
    );
    canvas.drawRect(
      Rect.fromLTWH(beamX, -20, size.width * .28, size.height * 1.6),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .06),
            Colors.white.withValues(alpha: .10),
            Colors.white.withValues(alpha: .06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(beamX, 0, size.width * .28, size.height)),
    );
    canvas.restore();

    // 5 ── Top-edge micro highlight ────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .20 + .08 * aurora),
            Colors.white.withValues(alpha: .12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1.2)),
    );
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.sweep != sweep || old.aurora != aurora;
}
