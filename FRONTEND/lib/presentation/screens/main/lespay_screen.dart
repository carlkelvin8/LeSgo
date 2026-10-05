import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class LespayScreen extends ConsumerStatefulWidget {
  const LespayScreen({super.key});

  @override
  ConsumerState<LespayScreen> createState() => _LespayScreenState();
}

class _LespayScreenState extends ConsumerState<LespayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lespayProvider.notifier).refreshBalance();
      ref.read(lespayProvider.notifier).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);

    return Scaffold(
      backgroundColor: AppColors.surface(context, Color(0xFFF8F7FA)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent(context, Color(0xFF5F2D82)),
          displacement: 20,
          onRefresh: () async {
            await Future.wait([
              ref.read(lespayProvider.notifier).refreshBalance(),
              ref.read(lespayProvider.notifier).loadTransactions(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildBody(context, lespayState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 64.0 : 16.0;

    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      primary: false,
      toolbarHeight: 72,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: AppColors.surface(context, Color(0xFFF8F7FA)),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B3FA0), Color(0xFF5F2D82)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: ResponsiveUtils.fontSize(context, 22),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Text(
                  'LesPay',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(
                      context,
                      isDesktop ? 28 : 24,
                    ),
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground(context, Colors.black87),
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideX(begin: -0.2, end: 0),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LespayState state) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 64.0 : 16.0;
    final sectionSpacing = isDesktop ? 32.0 : 24.0;
    final bottomSpacing = isDesktop ? 60.0 : 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (state.isLoading && state.balance == 0)
          _buildLoadingWallet(context)
        else
          _buildWalletSection(context, state),

        if (state.error != null) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _buildErrorBanner(context, state.error!),
          ),
        ],

        SizedBox(height: sectionSpacing),

        const LespayActionsSection(),

        SizedBox(height: sectionSpacing),

        const WalletTransactionsSection(),

        SizedBox(height: bottomSpacing),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingWallet(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalMargin = isDesktop ? 64.0 : 16.0;

    return Container(
      height: ResponsiveUtils.imageHeight(context, 210),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.grey.withValues(alpha: 0.1),
            Colors.grey.withValues(alpha: 0.05),
            Colors.grey.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ).animate().shimmer(duration: 1200.ms, color: AppColors.foreground(context, Colors.grey[200]!));
  }

  Widget _buildWalletSection(BuildContext context, LespayState state) {
    return Column(
      children: [
        WalletCard(
          balance: state.balance,
          balanceVisible: state.balanceVisible,
          onTap: () => ref.read(lespayProvider.notifier).refreshBalance(),
          onToggleVisibility: () =>
              ref.read(lespayProvider.notifier).toggleBalanceVisibility(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: ResponsiveUtils.fontSize(context, 18),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Text(
              error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(lespayProvider.notifier).refreshBalance(),
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.orange.shade700,
              size: ResponsiveUtils.fontSize(context, 18),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().shake(duration: 500.ms).fadeIn(duration: 300.ms);
  }
}

