import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/receipt_generator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/rider_earnings_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../provider/main/riderside/rider_earnings_provider.dart';

class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  void _shareEarnings(BuildContext context, RiderEarningsState state) {
    final periodLabel = RiderEarningsUtils.periodLabel(state.period);
    final entries = state.entries
        .map((e) => {
              'order_id': e.orderId,
              'service_name': e.serviceName,
              'earnings': e.earnings,
              'completed_at': e.completedAt,
            })
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
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
                ? () => _shareEarnings(context, earningsAsync.value!)
                : null,
            tooltip: AppLocalization.translate('share_earnings_report', lang),
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
            SizedBox(
              height: ResponsiveUtils.spacing(context, 36),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                children: RiderEarningsPeriod.values.map((p) {
                  final selected = p == period;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.spacing(context, 8),
                    ),
                    child: ChoiceChip(
                      label: Text(RiderEarningsUtils.periodLabel(p)),
                      selected: selected,
                      onSelected: (_) {
                        ref.read(riderEarningsPeriodProvider.notifier).state =
                            p;
                      },
                      selectedColor: const Color(0xFF5F2D82),
                      labelStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            earningsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load earnings: $e',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              data: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(summary: state.summary),
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    Text(
                      'Completed Trips',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    if (state.entries.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.spacing(context, 32),
                        ),
                        child: Text(
                          'No completed trips for ${RiderEarningsUtils.periodLabel(period).toLowerCase()}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...state.entries.map(
                        (entry) => _TripTile(entry: entry),
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

class _SummaryCard extends StatelessWidget {
  final RiderEarningsSummary summary;

  const _SummaryCard({required this.summary});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Rider Earnings',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'PHP ${summary.totalEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 28),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Row(
            children: [
              _StatChip(
                label: '${summary.completedTrips} trips',
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              _StatChip(
                label:
                    'Avg PHP ${summary.averagePerTrip.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
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
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PHP ${entry.earnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: const Color(0xFF5F2D82),
            ),
          ),
        ],
      ),
    );
  }
}
