import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(title: 'LesPay'),
            ),

            if (lespayState.isLoading && lespayState.balance == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              WalletCard(
                balance: lespayState.balance,
                onTap: () {
                  ref.read(lespayProvider.notifier).refreshBalance();
                },
              ),

            if (lespayState.error != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                child: Text(
                  lespayState.error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5F2D82),
                onRefresh: () async {
                  await ref.read(lespayProvider.notifier).refreshBalance();
                  await ref.read(lespayProvider.notifier).loadTransactions();
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.spacing(context, 24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CustomDivider(),
                    const LespayActionsSection(),
                    const CustomDivider(),
                    const SectionHeader(title: 'Link Account'),
                    const LinkAccountsSection(),
                    const CustomDivider(),
                    const SectionHeader(title: 'Transaction History'),
                    const WalletTransactionsSection(),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
