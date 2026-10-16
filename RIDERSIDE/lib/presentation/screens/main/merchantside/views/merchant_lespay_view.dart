import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/services/merchant_wallet_api.dart';
import '../../../../provider/main/merchantside/merchant_wallet_provider.dart';
import '../../../../widgets/widgets.dart';
import '../merchant_withdrawal_history_screen.dart';


class MerchantLespayView extends ConsumerStatefulWidget {
  const MerchantLespayView({super.key});

  @override
  ConsumerState<MerchantLespayView> createState() =>
      _MerchantLespayViewState();
}

class _MerchantLespayViewState extends ConsumerState<MerchantLespayView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(merchantWalletProvider.notifier).loadWallet(silent: true);
    }
  }

  Widget _reveal(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((i * .10).clamp(0.0, .5), 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: fade.drive(
          Tween(begin: const Offset(0, .04), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(merchantWalletProvider);
    final notifier = ref.read(merchantWalletProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0A18) : const Color(0xFFF4F2F8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: HomeHeader(
                backgroundColor: Colors.transparent,
                logoColor: isDark ? Colors.white : const Color(0xFF5F2D82),
                borderColor: Colors.transparent,
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5F2D82),
                backgroundColor: isDark ? const Color(0xFF1E1730) : Colors.white,
                onRefresh: () => notifier.loadWallet(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Page title ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: _reveal(
                          0,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LesPay',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.6,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A0A2E),
                                ),
                              ),
                              Text(
                                'Merchant wallet',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF9A85B8)
                                      : const Color(0xFFAA90C0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Balance card ──────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _reveal(
                          1,
                          _BalanceCard(
                            wallet: wallet,
                            onRefresh: () => notifier.loadWallet(),
                          ),
                        ),
                      ),
                    ),

                    // ── Error banner ──────────────────────────────────
                    if (wallet.error != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: .20),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    wallet.error!,
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Quick actions ─────────────────────────────────
                    if (notifier.canManageWallet)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _reveal(
                            2,
                            _QuickActions(
                              isDark: isDark,
                              onTopUp: () => _showTopUpSheet(context, ref),
                              onPayRider: () =>
                                  _showPayRiderSheet(context, ref),
                              onWithdraw: () =>
                                  _showWithdrawSheet(context, ref),
                            ),
                          ),
                        ),
                      ),

                    // ── Transaction history ───────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _reveal(
                          3,
                          Text(
                            'TRANSACTION HISTORY',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: isDark
                                  ? const Color(0xFF9A85B8)
                                  : const Color(0xFFAA90C0),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (wallet.isLoading && wallet.transactions.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF5F2D82)),
                          ),
                        ),
                      )
                    else if (wallet.transactions.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _EmptyTransactions(isDark: isDark),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          MediaQuery.of(context).padding.bottom + 32,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final itemAnim = CurvedAnimation(
                                parent: _entrance,
                                curve: Interval(
                                  (.35 + i * .06).clamp(0.0, .85),
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              );
                              return FadeTransition(
                                opacity: itemAnim,
                                child: SlideTransition(
                                  position: itemAnim.drive(Tween(
                                    begin: const Offset(0, .04),
                                    end: Offset.zero,
                                  )),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _TransactionTile(
                                      transaction:
                                          wallet.transactions[i],
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount:
                                wallet.transactions.take(20).length,
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
    );
  }

  void _showTopUpSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopUpSheet(parentContext: context),
    );
  }

  void _showPayRiderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayRiderSheet(parentContext: context),
    );
  }

  void _showWithdrawSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(parentContext: context),
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatefulWidget {
  final MerchantWalletState wallet;
  final VoidCallback onRefresh;
  const _BalanceCard({required this.wallet, required this.onRefresh});

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard>
    with TickerProviderStateMixin {
  late final AnimationController _bg = AnimationController(
    vsync: this, duration: const Duration(seconds: 5),
  )..repeat(reverse: true);
  late final AnimationController _shimmer = AnimationController(
    vsync: this, duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _counter = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _bg.dispose();
    _shimmer.dispose();
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bg, _shimmer]),
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onRefresh();
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A0D80)
                    .withValues(alpha: .35 + .10 * _bg.value),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -6,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _CardBgPainter(t: _bg.value, sweep: _shimmer.value),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .20),
                            width: .8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF34D399),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Merchant Wallet',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withValues(alpha: .45),
                        size: 16,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Balance
                  widget.wallet.isLoading
                      ? Container(
                          height: 52,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _counter,
                          builder: (_, __) {
                            final v = Curves.easeOutCubic
                                .transform(_counter.value);
                            final bal = widget.wallet.balance * v;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'PHP ',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withValues(alpha: .55),
                                          height: 1.8,
                                        ),
                                      ),
                                      TextSpan(
                                        text: bal.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -1.5,
                                          height: 1.0,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Divider
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: .20),
                                        Colors.white.withValues(alpha: .04),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Bottom stat row
                                Row(
                                  children: [
                                    _CardStat(
                                      label: 'Transactions',
                                      value: '${widget.wallet.transactions.length}',
                                      icon: Icons.receipt_outlined,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      color: Colors.white.withValues(alpha: .15),
                                    ),
                                    _CardStat(
                                      label: 'Last activity',
                                      value: widget.wallet.transactions.isNotEmpty
                                          ? _shortDate(widget.wallet.transactions.first['created_at']?.toString())
                                          : 'None yet',
                                      icon: Icons.access_time_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // View withdrawals link
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MerchantWithdrawalHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: .6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View Withdrawal History',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: .6),
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white.withValues(alpha: .4),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 10,
                                        color: Colors.white.withValues(alpha: .6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '–';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }
}

// ─── Card stat ────────────────────────────────────────────────────────────────
class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _CardStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: .50)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 9.5,
                color: Colors.white.withValues(alpha: .45),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Card bg painter ──────────────────────────────────────────────────────────
class _CardBgPainter extends CustomPainter {
  final double t;
  final double sweep;
  const _CardBgPainter({required this.t, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B3FC8), Color(0xFF5A1E88), Color(0xFF2A0850)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect),
    );
    final orbX = size.width * (.55 + .30 * t);
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(
        colors: [
          const Color(0xFFAA55EE).withValues(alpha: .28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(orbX, -size.height * .10), radius: size.width * .70)),
    );
    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final rc = Offset(size.width * 1.08, size.height * .08);
    for (var i = 0; i < 5; i++) {
      rp.color = Colors.white.withValues(alpha: .025 + i * .009);
      canvas.drawCircle(rc, size.width * (.20 + i * .11), rp);
    }
    final bx = -size.width * .3 + size.width * 1.6 * sweep;
    canvas.save();
    canvas.transform(Matrix4(
      math.cos(math.pi / 10), math.sin(math.pi / 10), 0, 0,
      -math.sin(math.pi / 10), math.cos(math.pi / 10), 0, 0,
      0, 0, 1, 0, 0, -size.height * .15, 0, 1,
    ).storage);
    canvas.drawRect(
      Rect.fromLTWH(bx, -20, size.width * .18, size.height * 1.6),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: .06),
          Colors.white.withValues(alpha: .09),
          Colors.white.withValues(alpha: .06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(bx, 0, size.width * .18, size.height)),
    );
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: .25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5)),
    );

    // Floating micro-particles
    final rng = math.Random(42);
    final pp = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 16; i++) {
      final bx2 = rng.nextDouble() * size.width;
      final by2 = rng.nextDouble() * size.height;
      final phase = rng.nextDouble() * math.pi * 2;
      final spd = .3 + rng.nextDouble() * .6;
      final r = .5 + rng.nextDouble() * 1.5;
      final px = bx2 + math.sin(t * math.pi * 2 * spd + phase) * 8;
      final py = by2 + math.cos(t * math.pi * 2 * spd + phase) * 6;
      final a = (.03 + rng.nextDouble() * .06) *
          (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase));
      pp.color = const Color(0xFFCC99EE).withValues(alpha: a);
      canvas.drawCircle(Offset(px, py), r, pp);
    }
  }

  @override
  bool shouldRepaint(covariant _CardBgPainter old) =>
      old.t != t || old.sweep != sweep;
}

// ─── Quick actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTopUp;
  final VoidCallback onPayRider;
  final VoidCallback onWithdraw;

  const _QuickActions({
    required this.isDark,
    required this.onTopUp,
    required this.onPayRider,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIONS',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: isDark
                ? const Color(0xFF9A85B8)
                : const Color(0xFFAA90C0),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1730) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2E2540)
                  : const Color(0xFFEDE9F2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5F2D82)
                    .withValues(alpha: isDark ? .08 : .04),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.add_rounded,
                iconBg: const Color(0xFF5F2D82),
                title: 'Top up',
                subtitle: 'Add funds via QR PH',
                isDark: isDark,
                isFirst: true,
                onTap: onTopUp,
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: isDark
                    ? const Color(0xFF2E2540)
                    : const Color(0xFFF0EBF6),
              ),
              _ActionRow(
                icon: Icons.send_rounded,
                iconBg: const Color(0xFF5F2D82),
                title: 'Pay Rider',
                subtitle: 'Send payment to a rider',
                isDark: isDark,
                onTap: onPayRider,
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: isDark
                    ? const Color(0xFF2E2540)
                    : const Color(0xFFF0EBF6),
              ),
              _ActionRow(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: const Color(0xFF2ECC71),
                title: 'Withdraw',
                subtitle: 'Request earnings withdrawal',
                isDark: isDark,
                isLast: true,
                onTap: onWithdraw,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: widget.isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: widget.isLast ? const Radius.circular(20) : Radius.zero,
    );
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(
        scale: 1.0 - .015 * _press.value,
        child: child,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        borderRadius: radius,
        splashColor: widget.iconBg.withValues(alpha: .08),
        highlightColor: widget.iconBg.withValues(alpha: .05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconBg.withValues(alpha: .30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF1A0A2E),
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        color: widget.isDark
                            ? const Color(0xFF9A85B8)
                            : const Color(0xFFAA90C0),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: widget.isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFCCB0E0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isDark;
  const _TransactionTile(
      {required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = transaction['type']?.toString() ?? '';
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final description =
        transaction['description']?.toString() ?? 'Transaction';
    final date = transaction['created_at']?.toString();
    final isCredit = type == 'credit';
    final color = isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1730) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E2540)
              : const Color(0xFFEDE9F2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF5F2D82).withValues(alpha: isDark ? .06 : .03),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? .18 : .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                  ),
                ),
                if (date != null)
                  Text(
                    date.length > 16 ? date.substring(0, 16) : date,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 10.5,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty transactions ───────────────────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  final bool isDark;
  const _EmptyTransactions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF5F2D82).withValues(alpha: .08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5F2D82).withValues(alpha: .12),
                width: 8,
              ),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 26, color: Color(0xFF6D3EA0)),
          ),
          const SizedBox(height: 14),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A0A2E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your wallet activity will appear here.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF9A85B8)
                  : const Color(0xFFAA90C0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top-up bottom sheet ──────────────────────────────────────────────────────
class _TopUpSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _TopUpSheet({required this.parentContext});

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  final _ctrl = TextEditingController();
  static const _quick = [100.0, 200.0, 500.0, 1000.0];
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_ctrl.text.trim()) ?? 0;
  double get _fee => _amount * 0.015;
  double get _total => _amount + _fee;

  Future<void> _submit() async {
    if (_amount < 50) {
      setState(() => _error = 'Minimum top-up is ₱50');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final result = await MerchantWalletApi.createTopUpInvoice(amount: _amount);
      if (!mounted) return;
      final invoiceUrl = result['invoice_url']?.toString() ??
          result['checkout_url']?.toString() ??
          result['payment_url']?.toString();
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        Navigator.of(context).pop();
        final uri = Uri.tryParse(invoiceUrl);
        if (uri != null) {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          }
          Future.delayed(const Duration(seconds: 5), () {
            ref.read(merchantWalletProvider.notifier).loadWallet();
          });
        }
      } else {
        setState(() {
          _processing = false;
          _error = 'No payment link received. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = MerchantWalletApi.extractError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1730) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .12)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top up wallet',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                      letterSpacing: -.3,
                    ),
                  ),
                  Text(
                    '1.5% processing fee applies',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount input
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_processing,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A0A2E),
            ),
            decoration: InputDecoration(
              labelText: 'Amount to add',
              prefixText: '₱ ',
              labelStyle: TextStyle(
                fontFamily: 'TT Fors',
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: .05)
                  : const Color(0xFFFAF7FD),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEAE0F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2540)
                      : const Color(0xFFEAE0F2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: Color(0xFF7B3FAA), width: 1.8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick amounts
          Row(
            children: _quick.map((v) {
              final sel = _ctrl.text == v.toStringAsFixed(0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(
                          () => _ctrl.text = v.toStringAsFixed(0));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 38,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF5F2D82)
                            : const Color(0xFF5F2D82)
                                .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF5F2D82)
                              : const Color(0xFF5F2D82)
                                  .withValues(alpha: .18),
                          width: sel ? 0 : .8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '₱${v.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Fee summary
          if (_amount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'To wallet', value: '₱${_amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _SummaryRow(
                      label: 'Fee (1.5%)', value: '₱${_fee.toStringAsFixed(2)}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: Color(0xFFE8E0F0)),
                  ),
                  _SummaryRow(
                    label: 'Total to pay',
                    value: '₱${_total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                    fontFamily: 'TT Fors', fontSize: 12, color: Colors.red),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Continue button
          GestureDetector(
            onTap: _processing ? null : _submit,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _processing
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF8B3FC8), Color(0xFF5F2D82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _processing ? const Color(0xFFE0D4EE) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _processing
                    ? []
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF5F2D82).withValues(alpha: .35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                          spreadRadius: -4,
                        ),
                      ],
              ),
              child: Center(
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Continue to payment',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pay rider bottom sheet ───────────────────────────────────────────────────
class _PayRiderSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _PayRiderSheet({required this.parentContext});

  @override
  ConsumerState<_PayRiderSheet> createState() => _PayRiderSheetState();
}

class _PayRiderSheetState extends ConsumerState<_PayRiderSheet> {
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final emailIsValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailIsValid) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: const Text('Enter the rider\'s registered email address.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid amount.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final wallet = ref.read(merchantWalletProvider);
    if (amount > wallet.availableBalance) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds your available balance of PHP ${wallet.availableBalance.toStringAsFixed(2)}.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm rider payment'),
        content: Text(
          'Send PHP ${amount.toStringAsFixed(2)} to\n$email?\n\n'
          'This will be deducted from your LesPay wallet. Check the email carefully before confirming.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            child: const Text('Confirm payment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(merchantWalletProvider.notifier);
    final success = await notifier.transferToRider(
      recipientEmail: email,
      amount: amount,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    final error = ref.read(merchantWalletProvider).error;
    if (success) {
      Navigator.of(context).pop();
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('₱${amount.toStringAsFixed(2)} sent to rider!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(error?.isNotEmpty == true
              ? error!
              : 'Payment failed. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(merchantWalletProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1730) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .12)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Rider',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                      letterSpacing: -.3,
                    ),
                  ),
                  Text(
                    'Transfer from your LesPay wallet',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A1D3D)
                  : const Color(0xFFF7F0FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF493260)
                    : const Color(0xFFE7D7F1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 18, color: const Color(0xFF7B3FAA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use the rider\'s registered email. Available balance: PHP ${wallet.availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11.5,
                      height: 1.3,
                      color: isDark
                          ? const Color(0xFFC5B1D8)
                          : const Color(0xFF765986),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SheetField(
            ctrl: _emailCtrl,
            label: 'Rider email',
            icon: Icons.person_outline_rounded,
            keyboard: TextInputType.emailAddress,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SheetField(
            ctrl: _amountCtrl,
            label: 'Amount (PHP)',
            prefix: '₱ ',
            icon: Icons.payments_outlined,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SheetField(
            ctrl: _noteCtrl,
            label: 'Note (optional)',
            icon: Icons.note_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: wallet.isTransferring ? null : _submit,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: wallet.isTransferring
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF8B3FC8), Color(0xFF5F2D82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: wallet.isTransferring ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: wallet.isTransferring
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF5F2D82).withValues(alpha: .35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                          spreadRadius: -4,
                        ),
                      ],
              ),
              child: Center(
                child: wallet.isTransferring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Send payment',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet field helper ───────────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? prefix;
  final IconData icon;
  final TextInputType keyboard;
  final bool isDark;

  const _SheetField({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.isDark,
    this.prefix,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1A0A2E),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9B70CC)),
        labelStyle: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          color: isDark
              ? const Color(0xFF9A85B8)
              : const Color(0xFFAA90C0),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: .05)
            : const Color(0xFFFAF7FD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2540)
                : const Color(0xFFEAE0F2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2E2540)
                : const Color(0xFFEAE0F2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7B3FAA), width: 1.8),
        ),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF9A85B8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: bold ? 14 : 12.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold
                ? const Color(0xFF5F2D82)
                : const Color(0xFF1A0A2E),
          ),
        ),
      ],
    );
  }
}


// ─── Withdraw bottom sheet ─────────────────────────────────────────────────────
class _WithdrawSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _WithdrawSheet({required this.parentContext});

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  String _selectedMethod = 'gcash';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final accountNumber = _accountNumberCtrl.text.trim();
    final accountName = _accountNameCtrl.text.trim();
    final bankName = _bankNameCtrl.text.trim();

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (accountNumber.isEmpty) {
      _showError('Please enter account number');
      return;
    }

    if (accountName.isEmpty) {
      _showError('Please enter account name');
      return;
    }

    if (_selectedMethod == 'bank_transfer' && bankName.isEmpty) {
      _showError('Please enter bank name');
      return;
    }

    final notifier = ref.read(merchantWalletProvider.notifier);
    final withdrawal = await notifier.requestWithdrawal(
      amount: amount,
      payoutMethod: _selectedMethod,
      payoutAccountNumber: accountNumber,
      payoutAccountName: accountName,
      payoutBankName: _selectedMethod == 'bank_transfer' ? bankName : null,
    );

    if (!mounted) return;

    final error = ref.read(merchantWalletProvider).error;
    if (withdrawal != null) {
      Navigator.of(context).pop();
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: const Text(
            'Withdrawal request submitted successfully!',
            style: TextStyle(fontFamily: 'TT Fors'),
          ),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (error != null) {
      _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'TT Fors')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(merchantWalletProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A0A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E2540)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF2ECC71),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Withdraw Earnings',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Available balance info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: .20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFF7A5A9A),
                          ),
                        ),
                        const Spacer(),
                        if (wallet.pendingWithdrawals > 0) ...[
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFF7A5A9A),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wallet.availableBalanceFormatted,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                        letterSpacing: -.5,
                      ),
                    ),
                    if (wallet.pendingWithdrawals > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pending: ${wallet.pendingWithdrawalsFormatted}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF9A85B8)
                              : const Color(0xFF7A5A9A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount field
              _SheetField(
                ctrl: _amountCtrl,
                label: 'Withdrawal Amount',
                icon: Icons.payments_rounded,
                prefix: 'PHP ',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Payout method selector
              Text(
                'Payout Method',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9A85B8)
                      : const Color(0xFF7A5A9A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PayoutMethodChip(
                      label: 'GCash',
                      icon: Icons.smartphone_rounded,
                      value: 'gcash',
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v!),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayoutMethodChip(
                      label: 'Maya',
                      icon: Icons.credit_card_rounded,
                      value: 'maya',
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v!),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PayoutMethodChip(
                      label: 'Bank',
                      icon: Icons.account_balance_rounded,
                      value: 'bank_transfer',
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v!),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Account number field
              _SheetField(
                ctrl: _accountNumberCtrl,
                label: _selectedMethod == 'bank_transfer'
                    ? 'Bank Account Number'
                    : '${_selectedMethod == 'gcash' ? 'GCash' : 'Maya'} Number',
                icon: Icons.numbers_rounded,
                keyboard: TextInputType.number,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Account name field
              _SheetField(
                ctrl: _accountNameCtrl,
                label: 'Account Name',
                icon: Icons.person_rounded,
                isDark: isDark,
              ),
              if (_selectedMethod == 'bank_transfer') ...[
                const SizedBox(height: 16),
                _SheetField(
                  ctrl: _bankNameCtrl,
                  label: 'Bank Name',
                  icon: Icons.account_balance_rounded,
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: 24),

              // Info text
              Text(
                'Your withdrawal request will be reviewed by our team. You will be notified once it\'s approved and processed.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF9A85B8)
                      : const Color(0xFF7A5A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2E2540)
                              : const Color(0xFFE5E5E5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: wallet.isWithdrawing ? null : _submitWithdrawal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: wallet.isWithdrawing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Payout method chip ────────────────────────────────────────────────────────
class _PayoutMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _PayoutMethodChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: .12)
              : (isDark
                  ? const Color(0xFF1E1730)
                  : const Color(0xFFF8F4FC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : (isDark
                    ? const Color(0xFF2E2540)
                    : const Color(0xFFE5E5E5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2ECC71)
                  : (isDark ? const Color(0xFF9A85B8) : const Color(0xFF7A5A9A)),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1A0A2E))
                    : (isDark ? const Color(0xFF9A85B8) : const Color(0xFF7A5A9A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
