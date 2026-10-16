import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../widgets/main/riderside/wallet/rider_wallet_card.dart';
import '../../../../widgets/main/riderside/wallet/rider_wallet_actions_section.dart';

class RiderWalletScreen extends ConsumerWidget {
  const RiderWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF171320) : const Color(0xFFF8F7FA),
      appBar: AppBar(
        backgroundColor: dark
            ? const Color(0xFF171320)
            : const Color(0xFFF8F7FA),
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppLocalization.translate('wallet', lang),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
      ),
      body: const SafeArea(top: false, child: RiderWalletView()),
    );
  }
}

class RiderWalletView extends ConsumerStatefulWidget {
  const RiderWalletView({super.key});

  @override
  ConsumerState<RiderWalletView> createState() => _RiderWalletViewState();
}

class _RiderWalletViewState extends ConsumerState<RiderWalletView>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final animation = _entrance.drive(
      CurveTween(curve: Interval(index * .14, 1, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, .05), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(riderWalletProvider);
    final lang = ref.watch(appLanguageProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppLocalization.translate(key, lang);
    return ColoredBox(
      color: dark ? const Color(0xFF171320) : const Color(0xFFF8F7FA),
      child: RefreshIndicator(
        color: const Color(0xFF6D3EA0),
        onRefresh: () => ref.read(riderWalletProvider.notifier).loadWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reveal(
                    0,
                    RiderWalletCard(
                      balanceVisible: _balanceVisible,
                      onToggleVisibility: () =>
                          setState(() => _balanceVisible = !_balanceVisible),
                    ),
                  ),
                  if (wallet.error != null) ...[
                    const SizedBox(height: 18),
                    _WalletNotice(
                      title: t('wallet_refresh_failed'),
                      // Avoid displaying raw responses that could reveal hidden balances.
                      message: t('wallet_refresh_hint'),
                      action: TextButton(
                        onPressed: wallet.isLoading
                            ? null
                            : () => ref
                                  .read(riderWalletProvider.notifier)
                                  .loadWallet(),
                        child: Text(t('try_again')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  _reveal(2, const RiderWalletActionsSection()),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: dark ? Colors.white54 : const Color(0xFF897D91),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t('wallet_pull_refresh'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: dark
                                ? Colors.white54
                                : const Color(0xFF897D91),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletNotice extends StatelessWidget {
  const _WalletNotice({
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? const Color(0xFFFFD397) : const Color(0xFF94601C);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 18, 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF241F2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? const Color(0xFF443A50) : const Color(0xFFE8E1ED),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF3D3020) : const Color(0xFFFFF2DC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? const Color(0xFFF5EFFA)
                          : const Color(0xFF302638),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: dark
                          ? const Color(0xFFCAC0D3)
                          : const Color(0xFF6A6073),
                    ),
                  ),
                  if (action == null) const SizedBox(height: 10),
                  ?action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
