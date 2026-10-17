import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/main/riderside/earnings/earnings_design.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/receipt_generator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/rider_earnings_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../provider/main/riderside/rider_earnings_provider.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key, this.embedded = false});
  final bool? embedded;

  static void shareEarnings(BuildContext context, RiderEarningsState state) {
    final periodLabel = RiderEarningsUtils.periodLabel(state.period);
    final entries = state.entries
        .map(
          (e) => {
            'order_id': e.orderId,
            'service_name': e.serviceName,
            'earnings': e.earnings,
            'completed_at': e.completedAt,
          },
        )
        .toList();

    final receipt = ReceiptGenerator.generateEarningSummaryReceipt(
      period: periodLabel,
      totalEarnings: state.summary.totalEarnings,
      completedTrips: state.summary.completedTrips,
      averagePerTrip: state.summary.averagePerTrip,
      entries: entries,
    );

    ShareUtils.saveAndShareReceipt(
      context,
      receipt,
      'LeSGo_Earnings_$periodLabel',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(riderEarningsPeriodProvider);
    final earningsAsync = ref.watch(riderEarningsProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: earningsCanvas(context),
      appBar: embedded == true
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
              title: Text(
                AppLocalization.translate('earnings', lang),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F2D82),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: earningsAsync is AsyncData
                      ? () => shareEarnings(context, earningsAsync.value!)
                      : null,
                  tooltip: AppLocalization.translate(
                    'share_earnings_report',
                    lang,
                  ),
                ),
              ],
            ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () async {
          ref.invalidate(riderEarningsProvider);
          await ref.read(riderEarningsProvider.future);
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RiderEarningsPeriod.values.map((p) {
                final selected = p == period;
                return ChoiceChip(
                  label: Text(RiderEarningsUtils.periodLabel(p)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) =>
                      ref.read(riderEarningsPeriodProvider.notifier).state = p,
                  selectedColor: const Color(0xFF5F2D82),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF5F2D82)
                        : const Color(0xFFEAE3F0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: 'TT Fors',
                    color: selected ? Colors.white : const Color(0xFF63576D),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            earningsAsync.when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Could not load earnings. Pull down to refresh or try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(riderEarningsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(summary: state.summary, period: state.period),
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    Text(
                      'Completed Trips',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: profileText(context),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    if (state.entries.isEmpty)
                      EarningsPanel(
                        child: EarningsEmptyState(
                          title: 'Ready for your next earning?',
                          message:
                              'No completed trips for ${RiderEarningsUtils.periodLabel(period).toLowerCase()}.\nYour completed trips will appear here.',
                        ),
                      )
                    else
                      ...state.entries.map((entry) => _TripTile(entry: entry)),
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

class _SummaryCard extends StatelessWidget {
  final RiderEarningsSummary summary;
  final RiderEarningsPeriod period;

  const _SummaryCard({required this.summary, required this.period});

  @override
  Widget build(BuildContext context) {
    return EarningsBalanceCard(
      title: 'Net earnings · ${RiderEarningsUtils.periodLabel(period)}',
      total: summary.totalEarnings,
      trips: summary.completedTrips,
      average: summary.averagePerTrip,
    );
  }
}

class _TripTile extends StatelessWidget {
  final RiderEarningsEntry entry;

  const _TripTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateLabel = entry.completedAt != null
        ? DateFormat('MMM d, h:mm a').format(entry.completedAt!)
        : 'Completed';

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: profileDark(context) ? const Color(0xFF241D30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profileDark(context)
              ? const Color(0xFF393044)
              : const Color(0xFFEFEAF4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8C5CB5).withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 20,
              color: Color(0xFF8C5CB5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.serviceName} • #${entry.orderId}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: profileMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'PHP ${entry.earnings.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
