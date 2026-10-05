import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_rating_provider.dart';

class RiderRatingScreen extends ConsumerStatefulWidget {
  const RiderRatingScreen({super.key});

  @override
  ConsumerState<RiderRatingScreen> createState() => _RiderRatingScreenState();
}

class _RiderRatingScreenState extends ConsumerState<RiderRatingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _heroBg = AnimationController(
    vsync: this, duration: const Duration(seconds: 5),
  )..repeat(reverse: true);
  late final AnimationController _heroShimmer = AnimationController(
    vsync: this, duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _starAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _barAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starAnim.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _barAnim.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _heroBg.dispose();
    _heroShimmer.dispose();
    _starAnim.dispose();
    _barAnim.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((index * .09).clamp(0.0, .55), 1.0,
          curve: Curves.easeOut),
    );
    final slide = _entrance.drive(CurveTween(
      curve: Interval((index * .09).clamp(0.0, .55), 1.0,
          curve: Curves.easeOutCubic),
    ));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position:
            slide.drive(Tween(begin: const Offset(0, .05), end: Offset.zero)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final ratingAsync = ref.watch(riderRatingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF110E1A) : const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1E1730) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF5F2D82), size: 20),
            ),
          ),
        ),
        title: Text(
          AppLocalization.translate('my_rating', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A0A2E),
            letterSpacing: -.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: .06)
                : const Color(0xFFEDE9F2),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () async {
          ref.invalidate(riderRatingProvider);
          await ref.read(riderRatingProvider.future);
        },
        child: ratingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6D3EA0)),
          ),
          error: (e, _) => _ErrorState(
            error: '$e',
            lang: lang,
            onRetry: () => ref.invalidate(riderRatingProvider),
          ),
          data: (state) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Hero ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _reveal(
                  0,
                  _HeroCard(
                    summary: state.summary,
                    heroBg: _heroBg,
                    shimmer: _heroShimmer,
                    starAnim: _starAnim,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 20)),

              // ── Score trend ──────────────────────────────────────────
              if (state.weeklyScores.any((s) => s > 0))
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _reveal(
                      1,
                      _ScoreTrendCard(
                          weeklyScores: state.weeklyScores,
                          isDark: isDark),
                    ),
                  ),
                ),
              if (state.weeklyScores.any((s) => s > 0))
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Breakdown ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _reveal(
                    2,
                    _BreakdownCard(
                      summary: state.summary,
                      barAnim: _barAnim,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Reviews label ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _reveal(
                    3,
                    Text(
                      'RECENT REVIEWS',
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

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ── Reviews list ─────────────────────────────────────────
              if (state.reviews.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _reveal(4, _EmptyReviews(isDark: isDark)),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 32,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final itemAnim = CurvedAnimation(
                          parent: _entrance,
                          curve: Interval(
                            (0.35 + i * .06).clamp(0.0, .85),
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
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReviewCard(
                                review: state.reviews[i],
                                isDark: isDark,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: state.reviews.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final RiderRatingSummary summary;
  final AnimationController heroBg;
  final AnimationController shimmer;
  final AnimationController starAnim;

  const _HeroCard({
    required this.summary,
    required this.heroBg,
    required this.shimmer,
    required this.starAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([heroBg, shimmer]),
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F2D82)
                  .withValues(alpha: .35 + .10 * heroBg.value),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _HeroBgPainter(t: heroBg.value, sweep: shimmer.value),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rating number
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: summary.overallRating),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    v.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Animated stars
                AnimatedBuilder(
                  animation: starAnim,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final delay = i * .15;
                      final t = ((starAnim.value - delay) / .4)
                          .clamp(0.0, 1.0);
                      final scale = Curves.elasticOut
                          .transform(t);
                      final filled = i < summary.overallRating.floor();
                      final half = !filled &&
                          i < summary.overallRating.ceil();
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          half
                              ? Icons.star_half_rounded
                              : filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                          size: 28,
                          color: filled || half
                              ? const Color(0xFFFBBF24)
                              : Colors.white.withValues(alpha: .35),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .20),
                      width: .8,
                    ),
                  ),
                  child: Text(
                    '${summary.totalReviews} review${summary.totalReviews == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .85),
                    ),
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

// ─── Hero bg painter ──────────────────────────────────────────────────────────
class _HeroBgPainter extends CustomPainter {
  final double t;
  final double sweep;
  const _HeroBgPainter({required this.t, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B3FC8), Color(0xFF5A1E88), Color(0xFF2A0850)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect),
    );
    final orbX = size.width * (.55 + .30 * t);
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFFAA55EE).withValues(alpha: .28), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(orbX, -size.height * .1), radius: size.width * .7)),
    );
    final rp = Paint()..style = PaintingStyle.stroke..strokeWidth = .7;
    final rc = Offset(size.width * 1.1, size.height * .1);
    for (var i = 0; i < 5; i++) {
      rp.color = Colors.white.withValues(alpha: .03 + i * .008);
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
          Colors.transparent, Colors.white.withValues(alpha: .07),
          Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: .07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(bx, 0, size.width * .18, size.height)),
    );
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withValues(alpha: .28), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5)),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroBgPainter old) =>
      old.t != t || old.sweep != sweep;
}

// ─── Score trend card ─────────────────────────────────────────────────────────
class _ScoreTrendCard extends StatelessWidget {
  final List<double> weeklyScores;
  final bool isDark;
  const _ScoreTrendCard({required this.weeklyScores, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(label: 'SCORE TREND', isDark: isDark),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: .06)
                        : Colors.black.withValues(alpha: .05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= weeklyScores.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'W${i + 1}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 9,
                              color: isDark
                                  ? const Color(0xFF9A85B8)
                                  : const Color(0xFFAA90C0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyScores.length,
                        (i) => FlSpot(i.toDouble(), weeklyScores[i])),
                    isCurved: true,
                    color: const Color(0xFF8B55CC),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: const Color(0xFF8B55CC),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF8B55CC).withValues(alpha: .20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown card ───────────────────────────────────────────────────────────
// ─── Breakdown card ───────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final RiderRatingSummary summary;
  final AnimationController barAnim;
  final bool isDark;

  const _BreakdownCard({
    required this.summary,
    required this.barAnim,
    required this.isDark,
  });

  static const _barColors = {
    5: Color(0xFF34D399),
    4: Color(0xFF60A5FA),
    3: Color(0xFFFBBF24),
    2: Color(0xFFFB923C),
    1: Color(0xFFF87171),
  };

  @override
  Widget build(BuildContext context) {
    final hasData = summary.ratingBreakdown.values.any((c) => c > 0);
    final maxCount = hasData
        ? summary.ratingBreakdown.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final total = summary.totalReviews;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B55CC), Color(0xFF5F2D82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Rating Breakdown',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '$total total',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFFAA90C0),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Bars
          ...List.generate(5, (index) {
            final star = 5 - index;
            final count = summary.ratingBreakdown[star] ?? 0;
            final fraction = count / maxCount;
            final color = _barColors[star] ?? const Color(0xFF8B55CC);
            final delay = index * .10;
            final pct = total > 0
                ? '${((count / total) * 100).round()}%'
                : '–';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Star number
                  SizedBox(
                    width: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Star icon
                  Icon(Icons.star_rounded, size: 12, color: color),
                  const SizedBox(width: 10),
                  // Animated bar
                  Expanded(
                    child: AnimatedBuilder(
                      animation: barAnim,
                      builder: (_, __) {
                        final t =
                            ((barAnim.value - delay) / .6).clamp(0.0, 1.0);
                        final aF = hasData
                            ? Curves.easeOutCubic.transform(t) * fraction
                            : 0.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              // Track
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: .07)
                                      : color.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              // Fill
                              FractionallySizedBox(
                                widthFactor: aF.clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color,
                                        Color.lerp(color, Colors.white, .25)!,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: aF > 0
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(alpha: .30),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Count + pct
                  SizedBox(
                    width: 42,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                          ),
                        ),
                        Text(
                          pct,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 9.5,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFFAA90C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Empty state message
          if (!hasData) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withValues(alpha: .07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0)),
                  const SizedBox(width: 8),
                  Text(
                    'Ratings will appear here after deliveries.',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Review card ──────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final RiderReview review;
  final bool isDark;
  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, y').format(review.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B55CC), Color(0xFF5F2D82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: i < review.rating
                            ? const Color(0xFFFBBF24)
                            : Colors.grey.shade400,
                      )),
                    ),
                  ],
                ),
              ),
              Text(
                dateLabel,
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
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .05)
                    : const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFFD4C8E8)
                      : const Color(0xFF4A3060),
                  height: 1.55,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty reviews ────────────────────────────────────────────────────────────
class _EmptyReviews extends StatelessWidget {
  final bool isDark;
  const _EmptyReviews({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withValues(alpha: .08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF5F2D82).withValues(alpha: .12),
                  width: 8,
                ),
              ),
              child: const Icon(Icons.star_border_rounded,
                  size: 30, color: Color(0xFF6D3EA0)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A0A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Customer reviews will appear here after your deliveries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              height: 1.5,
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

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final AppLanguage lang;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.error, required this.lang, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalization.translate('error_occurred', lang),
              style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w700,
                  color: Colors.red),
            ),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(AppLocalization.translate('retry', lang)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
BoxDecoration _cardDecor(bool isDark) => BoxDecoration(
  color: isDark ? const Color(0xFF1E1730) : Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: isDark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2),
  ),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF5F2D82).withValues(alpha: isDark ? .08 : .04),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ],
);

class _CardLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _CardLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: isDark ? const Color(0xFF9A85B8) : const Color(0xFFAA90C0),
    ),
  );
}
