import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/app_localization.dart';

class RiderHistoryDashboardCard extends ConsumerStatefulWidget {
  final int totalBookings;
  final int performanceStars;
  final List<double> chartDataPoints;
  final Map<String, int> statusCounts;

  const RiderHistoryDashboardCard({
    super.key,
    required this.totalBookings,
    required this.performanceStars,
    required this.chartDataPoints,
    this.statusCounts = const {},
  });

  @override
  ConsumerState<RiderHistoryDashboardCard> createState() =>
      _RiderHistoryDashboardCardState();
}

class _RiderHistoryDashboardCardState
    extends ConsumerState<RiderHistoryDashboardCard>
    with TickerProviderStateMixin {
  late final AnimationController _bg;
  late final AnimationController _shimmer;
  late final AnimationController _counters;

  @override
  void initState() {
    super.initState();
    final reduced = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;

    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _counters = AnimationController(
      vsync: this,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _bg.dispose();
    _shimmer.dispose();
    _counters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tl = ref.watch(appLanguageProvider) == AppLanguage.filipino;

    final stats = [
      _Stat(
        key: 'Completed',
        label: tl ? 'Natapos' : 'Completed',
        color: const Color(0xFF34D399),
        icon: Icons.check_circle_outline_rounded,
      ),
      _Stat(
        key: 'Processing',
        label: tl ? 'Pinoproseso' : 'Processing',
        color: const Color(0xFFFBBF24),
        icon: Icons.access_time_rounded,
      ),
      _Stat(
        key: 'Cancelled',
        label: tl ? 'Kinansela' : 'Cancelled',
        color: const Color(0xFFF87171),
        icon: Icons.cancel_outlined,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_bg, _shimmer]),
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF4A0D80,
              ).withValues(alpha: .35 + .12 * _bg.value),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _CardBgPainter(t: _bg.value, sweep: _shimmer.value),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Total counter ──────────────────────────────────────
                AnimatedBuilder(
                  animation: _counters,
                  builder: (_, __) {
                    final v = Curves.easeOutCubic.transform(_counters.value);
                    return Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          '${(widget.totalBookings * v).round()}',
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.white,
                            fontSize: 52,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 8),
                          child: Text(
                            tl ? 'booking' : 'deliveries',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              color: Colors.white.withValues(alpha: .50),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ── Status chips ──────────────────────────────────────
                Row(
                  children: stats.map((s) {
                    final count = widget.statusCounts[s.key] ?? 0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: s == stats.last ? 0 : 8,
                        ),
                        child: AnimatedBuilder(
                          animation: _counters,
                          builder: (_, __) {
                            final v = Curves.easeOutCubic.transform(
                              _counters.value,
                            );
                            return Container(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                10,
                                10,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: s.color.withValues(alpha: .22),
                                  width: .8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(s.icon, size: 11, color: s.color),
                                      const Spacer(),
                                      Text(
                                        '${(count * v).round()}',
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          color: s.color,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    s.label,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      color: Colors.white.withValues(
                                        alpha: .45,
                                      ),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Divider ──────────────────────────────────────────
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: .18),
                        Colors.white.withValues(alpha: .04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Performance row ──────────────────────────────────
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final filled = i < widget.performanceStars;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: filled
                              ? const Color(0xFFFBBF24)
                              : Colors.white.withValues(alpha: .25),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.performanceStars == 0
                            ? (tl
                                  ? 'Wala pang performance score'
                                  : 'No performance score yet')
                            : 'Performance · ${widget.performanceStars}/5',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.white.withValues(alpha: .55),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat {
  final String key;
  final String label;
  final Color color;
  final IconData icon;
  const _Stat({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
  });
}

// ─── Card background painter ──────────────────────────────────────────────────
class _CardBgPainter extends CustomPainter {
  final double t;
  final double sweep;
  const _CardBgPainter({required this.t, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A1E88), Color(0xFF3A0D60), Color(0xFF1A0535)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    final orbX = size.width * (.50 + .35 * t);
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFAA55EE).withValues(alpha: .25),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(orbX, -size.height * .10),
                radius: size.width * .72,
              ),
            ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF2A0850).withValues(alpha: .50),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * .5, size.height * 1.15),
                radius: size.width * .65,
              ),
            ),
    );

    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final rc = Offset(size.width * 1.08, size.height * .08);
    for (var i = 0; i < 5; i++) {
      rp.color = Colors.white.withValues(alpha: .025 + i * .008);
      canvas.drawCircle(rc, size.width * (.20 + i * .11), rp);
    }

    final bx = -size.width * .3 + size.width * 1.6 * sweep;
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
        -size.height * .15,
        0,
        1,
      ).storage,
    );
    canvas.drawRect(
      Rect.fromLTWH(bx, -20, size.width * .18, size.height * 1.6),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .05),
            Colors.white.withValues(alpha: .09),
            Colors.white.withValues(alpha: .05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(bx, 0, size.width * .18, size.height)),
    );
    canvas.restore();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5)),
    );
  }

  @override
  bool shouldRepaint(covariant _CardBgPainter old) =>
      old.t != t || old.sweep != sweep;
}
