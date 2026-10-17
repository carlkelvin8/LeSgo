import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_earnings_provider.dart';
import '../../../provider/main/riderside/rider_earnings_insights_provider.dart';
import 'rider_earnings_screen.dart';
import 'rider_earnings_insights_screen.dart';
import '../../../widgets/main/riderside/earnings/earnings_design.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';

class RiderEarningsHubScreen extends ConsumerStatefulWidget {
  const RiderEarningsHubScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<RiderEarningsHubScreen> createState() =>
      _RiderEarningsHubScreenState();
}

class _RiderEarningsHubScreenState extends ConsumerState<RiderEarningsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_tabChanged);
  }

  void _tabChanged() {
    if (_tabs.index != _index) setState(() => _index = _tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final VoidCallback? share;
    if (_index == 0) {
      share = ref
          .watch(riderEarningsProvider)
          .whenOrNull(
            data: (data) =>
                () => RiderEarningsScreen.shareEarnings(context, data),
          );
    } else {
      share = ref
          .watch(riderEarningsInsightsProvider)
          .whenOrNull(
            data: (data) =>
                () => RiderEarningsInsightsScreen.shareReport(context, data),
          );
    }
    return Scaffold(
      backgroundColor: earningsCanvas(context),
      appBar: AppBar(
        title: Text(
          AppLocalization.translate('earnings', lang),
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: profileDark(context)
            ? const Color(0xFF171320)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: profileText(context),
        actions: [
          IconButton(
            tooltip: AppLocalization.translate('share_earnings_report', lang),
            onPressed: share,
            icon: const Icon(Icons.ios_share_rounded, size: 22),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: profileDark(context)
                  ? const Color(0xFF241D30)
                  : const Color(0xFFF4F0F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: profileDark(context)
                  ? const Color(0xFFE2CBF5)
                  : const Color(0xFF5F2D82),
              unselectedLabelColor: const Color(0xFF80748A),
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: profileDark(context)
                    ? const Color(0xFF393044)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelStyle: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  text: lang == AppLanguage.filipino ? 'Mga biyahe' : 'Trips',
                ),
                const Tab(text: 'Insights'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          RiderEarningsScreen(embedded: true),
          RiderEarningsInsightsScreen(embedded: true),
        ],
      ),
    );
  }
}
