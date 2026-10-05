import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_history_provider.dart';
import '../../../../widgets/widgets.dart';

class RiderHistoryView extends ConsumerStatefulWidget {
  const RiderHistoryView({super.key});

  @override
  ConsumerState<RiderHistoryView> createState() => _RiderHistoryViewState();
}

class _RiderHistoryViewState extends ConsumerState<RiderHistoryView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((index * .10).clamp(0.0, .5), 1.0, curve: Curves.easeOut),
    );
    final slide = _entrance.drive(
      CurveTween(
        curve: Interval(
          (index * .10).clamp(0.0, .5),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide.drive(
          Tween(begin: const Offset(0, .05), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tl = ref.watch(appLanguageProvider) == AppLanguage.filipino;
    final state = ref.watch(riderHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final filtered = state.selectedFilter != 'All';
    final notifier = ref.read(riderHistoryProvider.notifier);
    final bookings = state.filteredBookings;

    // Trigger re-entrance when filter changes
    ref.listen<RiderHistoryState>(riderHistoryProvider, (prev, _) {
      if (prev?.selectedFilter != state.selectedFilter) {
        _entrance.forward(from: 0);
      }
    });

    return ColoredBox(
      color: isDark ? const Color(0xFF110E1A) : const Color(0xFFF4F2F8),
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        color: const Color(0xFF5F2D82),
        backgroundColor: isDark ? const Color(0xFF1E1730) : Colors.white,
        displacement: 80,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Page header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _reveal(
                  0,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tl ? 'Kasaysayan ng booking' : 'Booking history',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A0A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tl
                            ? 'Balikan ang bawat biyahe.'
                            : 'Every delivery, all in one place.',
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

            // ── Dashboard card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _reveal(
                1,
                RiderHistoryDashboardCard(
                  totalBookings: state.totalBookings,
                  performanceStars: state.performanceStars,
                  chartDataPoints: state.chartDataPoints,
                  statusCounts: state.statusCounts,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Filter tabs ────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBarDelegate(
                extent: 44 + MediaQuery.textScalerOf(context).scale(14) * 1.5,
                child: _reveal(
                  2,
                  ColoredBox(
                    color: isDark
                        ? const Color(0xFF110E1A)
                        : const Color(0xFFF4F2F8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: RiderHistoryFilterTabs(
                            filters: RiderHistoryState.filterOptions,
                            selectedFilter: state.selectedFilter,
                            onFilterChanged: notifier.updateFilter,
                          ),
                        ),
                        Container(
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: .06)
                              : Colors.black.withValues(alpha: .04),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            if (state.isLoading)
              SliverFillRemaining(child: _LoadingState(tl: tl))
            else if (state.error != null || bookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  tl: tl,
                  isError: state.error != null,
                  isFiltered: filtered,
                  isDark: isDark,
                  onAction: state.error != null || !filtered
                      ? notifier.refresh
                      : () => notifier.updateFilter('All'),
                  reduced: reduced,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  12,
                  0,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Stagger each booking card
                    final start = (index * .06).clamp(0.0, .5);
                    final end = (start + .5).clamp(0.0, 1.0);
                    final itemAnim = CurvedAnimation(
                      parent: _entrance,
                      curve: Interval(start, end, curve: Curves.easeOutCubic),
                    );
                    return AnimatedBuilder(
                      animation: itemAnim,
                      builder: (_, child) => Opacity(
                        opacity: itemAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - itemAnim.value)),
                          child: child,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RiderHistoryBookingsList(
                          bookings: [bookings[index]],
                        ),
                      ),
                    );
                  }, childCount: bookings.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bar sliver delegate ───────────────────────────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;
  const _FilterBarDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(_, double shrink, bool overlap) => child;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) => old.child != child || old.extent != extent;
}

// ─── Loading state ────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  final bool tl;
  const _LoadingState({required this.tl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF6D3EA0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tl ? 'Kinukuha ang mga booking…' : 'Loading your bookings…',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: isDark ? const Color(0xFF9A85B8) : const Color(0xFFAA90C0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / error state ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool tl;
  final bool isError;
  final bool isFiltered;
  final bool isDark;
  final bool reduced;
  final VoidCallback onAction;

  const _EmptyState({
    required this.tl,
    required this.isError,
    required this.isFiltered,
    required this.isDark,
    required this.reduced,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isError ? Icons.cloud_off_rounded : Icons.receipt_long_rounded;
    final title = isError
        ? (tl ? 'Hindi makuha ang history' : 'Couldn\'t load history')
        : isFiltered
        ? (tl ? 'Walang booking sa filter na ito' : 'No bookings here')
        : (tl
              ? 'Dito magsisimula ang iyong mga biyahe'
              : 'Your journey starts here');
    final subtitle = isError
        ? (tl
              ? 'Subukang i-refresh para makita ang iyong mga booking.'
              : 'Refresh to try loading your bookings again.')
        : isFiltered
        ? (tl
              ? 'Pumili ng ibang filter o tingnan ang lahat ng booking.'
              : 'Try another filter or view all bookings.')
        : (tl
              ? 'Lalabas dito ang iyong mga aktibo at natapos na delivery.'
              : 'Your active and completed deliveries will appear here.');
    final actionLabel = isError || !isFiltered
        ? (tl ? 'I-refresh' : 'Refresh history')
        : (tl ? 'Lahat ng booking' : 'View all bookings');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .80, end: 1.0),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5F2D82).withValues(alpha: .08),
                  border: Border.all(
                    color: const Color(0xFF5F2D82).withValues(alpha: .12),
                    width: 8,
                  ),
                ),
                child: Icon(icon, size: 36, color: const Color(0xFF6D3EA0)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                height: 1.55,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF5F2D82).withValues(alpha: .20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFiltered && !isError
                          ? Icons.filter_alt_off_outlined
                          : Icons.refresh_rounded,
                      size: 16,
                      color: const Color(0xFF6D3EA0),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D3EA0),
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
}
