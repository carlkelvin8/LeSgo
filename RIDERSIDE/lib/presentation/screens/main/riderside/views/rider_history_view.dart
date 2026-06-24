import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_history_provider.dart';
import '../../../../widgets/widgets.dart';

/// Thin view — zero logic, only assembles widgets with data from provider.
class RiderHistoryView extends ConsumerWidget {
  const RiderHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final state = ref.watch(riderHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dashboard card
        RiderHistoryDashboardCard(
          totalBookings: state.totalBookings,
          performanceStars: state.performanceStars,
          chartDataPoints: state.chartDataPoints,
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

        // Filter tabs
        RiderHistoryFilterTabs(
          filters: RiderHistoryState.filterOptions,
          selectedFilter: state.selectedFilter,
          onFilterChanged: (filter) {
            ref.read(riderHistoryProvider.notifier).updateFilter(filter);
          },
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Loading, Error, or Bookings list
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                  ),
                )
              : state.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                          Text(
                            'Failed to load history',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            state.error!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                          ElevatedButton(
                            onPressed: () => ref.read(riderHistoryProvider.notifier).refresh(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5F2D82),
                            ),
                            child: Text(AppLocalization.translate('retry', lang)),
                          ),
                        ],
                      ),
                    )
                  : state.filteredBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                              Text(
                                'No history yet',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 18),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                              Text(
                                'Active and completed orders will appear here',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(riderHistoryProvider.notifier).refresh(),
                          color: const Color(0xFF5F2D82),
                          child: RiderHistoryBookingsList(
                            bookings: state.filteredBookings,
                          ),
                        ),
        ),
      ],
    );
  }
}
