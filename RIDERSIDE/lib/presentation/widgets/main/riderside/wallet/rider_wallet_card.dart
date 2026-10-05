import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/rider_commission_utils.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderWalletCard extends ConsumerStatefulWidget {
  const RiderWalletCard({
    super.key,
    this.balanceVisible = true,
    this.onToggleVisibility,
  });
  final bool balanceVisible;
  final VoidCallback? onToggleVisibility;

  @override
  ConsumerState<RiderWalletCard> createState() => _RiderWalletCardState();
}

class _RiderWalletCardState extends ConsumerState<RiderWalletCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.stop();
      _light.value = .35;
    } else if (!_light.isAnimating) {
      _light.repeat();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(riderWalletProvider);
    final lang = ref.watch(appLanguageProvider);
    final package = RiderCommissionUtils.labelForPackage(
      ref.watch(riderAuthProvider).user?.packageTier,
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    String t(String key) => AppLocalization.translate(key, lang);
    final formatted = NumberFormat('#,##0.00', 'en_PH').format(wallet.balance);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A0870).withValues(alpha: .22),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _WalletLightPainter(_light)),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFAA70E0).withValues(alpha: .35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/images/Logo.svg',
                            width: 86,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFD8C3ED),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        tooltip: t(
                          widget.balanceVisible
                              ? 'wallet_hide_balance'
                              : 'wallet_show_balance',
                        ),
                        onPressed: widget.onToggleVisibility,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .08),
                          foregroundColor: const Color(0xFFE5D6F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          widget.balanceVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    t('wallet_available_balance'),
                    style: const TextStyle(
                      color: Color(0xFFC5ADDF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Hide immediately: an outgoing animation must not expose private amounts.
                  Semantics(
                    label: widget.balanceVisible
                        ? 'PHP $formatted'
                        : t('wallet_balance_hidden'),
                    excludeSemantics: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.balanceVisible ? '₱ $formatted' : '••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.4,
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFF664285)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              size: 20,
                              color: Color(0xFFD5B5F4),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('rider_package_type'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFC5ADDF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    package,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: t(
                          wallet.isLoading ? 'loading' : 'wallet_refresh',
                        ),
                        onPressed: wallet.isLoading
                            ? null
                            : () => ref
                                  .read(riderWalletProvider.notifier)
                                  .loadWallet(),
                        icon: wallet.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: reduced
                                    ? const Icon(
                                        Icons.hourglass_top_rounded,
                                        size: 20,
                                        color: Colors.white70,
                                      )
                                    : const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFFD8C3ED),
                                size: 22,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Repaints the decorative layer only; the balance and controls stay static.
class _WalletLightPainter extends CustomPainter {
  _WalletLightPainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0520), Color(0xFF2A0D55), Color(0xFF5B2A90)],
        ).createShader(rect),
    );
    final shift = math.sin(motion.value * math.pi * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(.75 + shift * .2, -.35),
          radius: 1.15,
          colors: [
            const Color(0xFF9F62CD).withValues(alpha: .22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0xFFD5A5FA).withValues(alpha: .08);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 1.04, size.height * .08),
        size.width * (.25 + i * .12),
        ring,
      );
    }
    final beam = Rect.fromLTWH(
      -size.width * .6 + size.width * 2 * motion.value,
      -size.height,
      size.width * .4,
      size.height * 3,
    );
    canvas.save();
    canvas.rotate(-.22);
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .055),
            Colors.transparent,
          ],
        ).createShader(beam),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WalletLightPainter oldDelegate) =>
      oldDelegate.motion != motion;
}
