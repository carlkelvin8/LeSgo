import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_rating_provider.dart';
import '../../../widgets/main/riderside/earnings/earnings_design.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

class RiderRatingScreen extends ConsumerWidget {
  const RiderRatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final filipino = lang == AppLanguage.filipino;
    String copy(String en, String tl) => filipino ? tl : en;
    final rating = ref.watch(riderRatingProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > 648 ? (width - 600) / 2 : 20.0;
    return Scaffold(
      backgroundColor: earningsCanvas(context),
      appBar: AppBar(
        backgroundColor: profileDark(context)
            ? const Color(0xFF171320)
            : Colors.white,
        foregroundColor: profileText(context),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: Text(
          AppLocalization.translate('my_rating', lang),
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            horizontal,
            16,
            horizontal,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: rating.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, stack) => [
              EarningsPanel(
                child: Column(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 28,
                      color: Color(0xFF9562B9),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      copy(
                        'Could not load your rating',
                        'Hindi ma-load ang iyong rating',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w600,
                        color: profileText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy(
                        'Please check your connection and try again.',
                        'Pakisuri ang koneksyon at subukang muli.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        height: 1.5,
                        color: profileMuted(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(riderRatingProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppLocalization.translate('try_again', lang)),
                    ),
                  ],
                ),
              ),
            ],
            data: (state) => [
              _RatingSummary(summary: state.summary, copy: copy),
              const SizedBox(height: 16),
              _RatingBreakdown(summary: state.summary, copy: copy),
              if (state.weeklyScores.any((score) => score > 0)) ...[
                const SizedBox(height: 16),
                _ScoreTrend(scores: state.weeklyScores, copy: copy),
              ],
              const SizedBox(height: 24),
              Text(
                copy('Recent reviews', 'Mga bagong review'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: profileText(context),
                ),
              ),
              const SizedBox(height: 12),
              if (state.reviews.isEmpty)
                EarningsPanel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9562B9).withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF9562B9),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy('No reviews yet', 'Wala pang review'),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: profileText(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              copy(
                                'Customer feedback will appear here after your deliveries.',
                                'Lalabas dito ang feedback ng customer pagkatapos ng iyong deliveries.',
                              ),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 12,
                                height: 1.5,
                                color: profileMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...state.reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(review: review, copy: copy),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Copy = String Function(String english, String filipino);

class _RatingSummary extends StatelessWidget {
  final RiderRatingSummary summary;
  final _Copy copy;
  const _RatingSummary({required this.summary, required this.copy});
  @override
  Widget build(BuildContext context) {
    final rated = summary.totalReviews > 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29143F), Color(0xFF683990)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 20,
                color: Color(0xFFE2CBF5),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  copy('Overall rating', 'Kabuuang rating'),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(
                rated ? summary.overallRating.toStringAsFixed(1) : '—',
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 46,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (rated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ 5',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Stars(value: rated ? summary.overallRating : 0, onDark: true),
          const SizedBox(height: 12),
          Text(
            rated
                ? copy(
                    'Based on ${summary.totalReviews} customer reviews',
                    'Batay sa ${summary.totalReviews} review ng customer',
                  )
                : copy(
                    'Not rated yet · Your first review starts here',
                    'Wala pang rating · Dito magsisimula ang unang review',
                  ),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              height: 1.5,
              color: Colors.white.withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double value;
  final bool onDark;
  const _Stars({required this.value, this.onDark = false});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${value.toStringAsFixed(1)} out of 5 stars',
    child: Wrap(
      spacing: 4,
      children: List.generate(
        5,
        (index) => Icon(
          value >= index + 1
              ? Icons.star_rounded
              : value > index
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: 22,
          color: value > index
              ? const Color(0xFFF3C77B)
              : onDark
              ? const Color(0xFFBBA0CF)
              : const Color(0xFFB6A7C3),
        ),
      ),
    ),
  );
}

class _RatingBreakdown extends StatelessWidget {
  final RiderRatingSummary summary;
  final _Copy copy;
  const _RatingBreakdown({required this.summary, required this.copy});
  @override
  Widget build(BuildContext context) {
    final accent = profileDark(context)
        ? const Color(0xFFCFACED)
        : const Color(0xFF744499);
    return EarningsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy('Rating breakdown', 'Detalye ng rating'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: profileText(context),
            ),
          ),
          const SizedBox(height: 18),
          for (var star = 5; star >= 1; star--) ...[
            if (star < 5) const SizedBox(height: 16),
            Semantics(
              label:
                  '$star stars: ${summary.ratingBreakdown[star] ?? 0} reviews',
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$star',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: profileText(context),
                      ),
                    ),
                  ),
                  Icon(Icons.star_rounded, size: 15, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: summary.totalReviews > 0
                            ? ((summary.ratingBreakdown[star] ?? 0) /
                                      summary.totalReviews)
                                  .clamp(0.0, 1.0)
                            : 0,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: .08),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 42,
                    child: Text(
                      NumberFormat.compact().format(
                        summary.ratingBreakdown[star] ?? 0,
                      ),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: profileMuted(context),
                      ),
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

class _ScoreTrend extends StatelessWidget {
  final List<double> scores;
  final _Copy copy;
  const _ScoreTrend({required this.scores, required this.copy});
  @override
  Widget build(BuildContext context) => EarningsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy('Weekly rating trend', 'Lingguhang trend ng rating'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: profileText(context),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 5,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    scores.length,
                    (i) => FlSpot(i.toDouble(), scores[i]),
                  ),
                  isCurved: false,
                  color: const Color(0xFF9562B9),
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF9562B9).withValues(alpha: .07),
                  ),
                ),
              ],
            ),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
          ),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  final RiderReview review;
  final _Copy copy;
  const _ReviewCard({required this.review, required this.copy});
  @override
  Widget build(BuildContext context) => EarningsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF9562B9).withValues(alpha: .1),
              child: Text(
                review.customerName.trim().isEmpty
                    ? 'C'
                    : review.customerName.trim().characters.first.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9562B9),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: profileText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(review.date),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      color: profileMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Stars(value: review.rating.toDouble()),
        const SizedBox(height: 10),
        Text(
          review.comment.trim().isEmpty
              ? copy('No written comment', 'Walang isinulat na komento')
              : review.comment,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13,
            height: 1.6,
            color: profileMuted(context),
          ),
        ),
      ],
    ),
  );
}
