import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_rating_provider.dart';

class RiderRatingScreen extends ConsumerWidget {
  const RiderRatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(riderRatingProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'My Rating',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () async {
          ref.invalidate(riderRatingProvider);
          await ref.read(riderRatingProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            hp,
            ResponsiveUtils.spacing(context, 16),
            hp,
            ResponsiveUtils.scrollBottomPaddingForBottomNav(context),
          ),
          children: [
            ratingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load ratings: $e',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              data: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverallRatingCard(summary: state.summary),
                    SizedBox(
                        height: ResponsiveUtils.spacing(context, 16)),
                    _ScoreTrendCard(
                        weeklyScores: state.weeklyScores),
                    SizedBox(
                        height: ResponsiveUtils.spacing(context, 16)),
                    _RatingBreakdownCard(summary: state.summary),
                    SizedBox(
                        height: ResponsiveUtils.spacing(context, 16)),
                    Text(
                      'Recent Reviews',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize:
                            ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveUtils.spacing(context, 12)),
                    if (state.reviews.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical:
                              ResponsiveUtils.spacing(context, 32),
                        ),
                        child: Text(
                          'No reviews yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...state.reviews.map(
                        (review) =>
                            _ReviewTile(review: review),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallRatingCard extends StatelessWidget {
  final RiderRatingSummary summary;

  const _OverallRatingCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2D82), Color(0xFF8E24AA)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            summary.overallRating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 48),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starFill = index < summary.overallRating.floor();
              final half =
                  !starFill && index < summary.overallRating.ceil();
              return Icon(
                half
                    ? Icons.star_half_rounded
                    : starFill
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                size: ResponsiveUtils.fontSize(context, 24),
                color: Colors.amber,
              );
            }),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            '${summary.totalReviews} reviews',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTrendCard extends StatelessWidget {
  final List<double> weeklyScores;

  const _ScoreTrendCard({required this.weeklyScores});

  @override
  Widget build(BuildContext context) {
    if (weeklyScores.every((s) => s == 0)) return const SizedBox.shrink();

    final maxY = 5.0;
    final minY = 0.0;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Trend',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          SizedBox(
            height: ResponsiveUtils.spacing(context, 160),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklyScores.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'W${index + 1}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 9),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toStringAsFixed(1),
                          const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyScores.length,
                        (i) => FlSpot(i.toDouble(), weeklyScores[i])),
                    isCurved: true,
                    color: const Color(0xFF5F2D82),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF5F2D82),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF5F2D82)
                          .withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBreakdownCard extends StatelessWidget {
  final RiderRatingSummary summary;

  const _RatingBreakdownCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final int maxCount;
    if (summary.ratingBreakdown.values.every((c) => c == 0)) {
      maxCount = 1;
    } else {
      maxCount = summary.ratingBreakdown.values
          .reduce((a, b) => a > b ? a : b);
    }

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ...List.generate(5, (index) {
            final star = 5 - index;
            final count =
                summary.ratingBreakdown[star] ?? 0;
            final fraction =
                maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: ResponsiveUtils.spacing(context, 32),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(
                                context, 13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8D9F5),
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtils.spacing(context, 36)),
                  Text(
                    '$count',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize:
                          ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RiderReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('MMM d, y').format(review.date);

    return Container(
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.spacing(context, 10)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.spacing(context, 16),
                backgroundColor: const Color(0xFF5F2D82)
                    .withValues(alpha: 0.1),
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveUtils.fontSize(context, 13),
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
              SizedBox(
                  width:
                      ResponsiveUtils.spacing(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtils.fontSize(
                            context, 14),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: ResponsiveUtils.fontSize(
                              context, 14),
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                dateLabel,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize:
                      ResponsiveUtils.fontSize(context, 11),
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(
                height:
                    ResponsiveUtils.spacing(context, 8)),
            Text(
              review.comment,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize:
                    ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
