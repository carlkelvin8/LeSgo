import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/rider_package_api.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../presentation/provider/main/riderside/rider_package_provider.dart';
import '../../../../presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'rider_package_payment_screen.dart';

class RiderPackageTierView extends ConsumerStatefulWidget {
  const RiderPackageTierView({super.key});

  @override
  ConsumerState<RiderPackageTierView> createState() =>
      _RiderPackageTierViewState();
}

class _RiderPackageTierViewState extends ConsumerState<RiderPackageTierView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(riderPackageProvider.notifier).loadCatalog(),
    );
  }

  Future<void> _handleUpgrade(RiderPackageOption option) async {
    final lang = ref.read(appLanguageProvider);
    final wallet = ref.read(riderWalletProvider);
    final price = option.oneTimePrice ?? 0;
    final canUseLesPay = wallet.balance >= price;

    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalization.translate('upgrade_to', lang)
              .replaceAll('{{tier}}', option.label),
        ),
        content: Text(
          '${option.priceLabel}\n${option.profitShareLabel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalization.translate('cancel', lang)),
          ),
          if (canUseLesPay)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'lespay'),
              child: const Text('Pay with LesPay'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'xendit'),
            child: const Text('Pay online'),
          ),
        ],
      ),
    );

    if (!mounted || paymentMethod == null) return;

    final notifier = ref.read(riderPackageProvider.notifier);
    final checkout = paymentMethod == 'lespay'
        ? await notifier.upgradeWithLesPay(option.tier)
        : await notifier.startXenditUpgrade(option.tier);

    if (!mounted || checkout == null) {
      final error = ref.read(riderPackageProvider).error;
      if (error != null) {
        SnackBarUtils.showError(context, error);
      }
      return;
    }

    if (checkout.isCompleted) {
      SnackBarUtils.showSuccess(
        context,
        'Upgraded to ${checkout.targetLabel}',
      );
      return;
    }

    if (checkout.needsPayment && checkout.invoiceUrl != null) {
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => RiderPackagePaymentScreen(checkout: checkout),
        ),
      );
      if (!mounted) return;
      if (success == true) {
        SnackBarUtils.showSuccess(
          context,
          'Upgraded to ${checkout.targetLabel}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final packageState = ref.watch(riderPackageProvider);
    final catalog = packageState.catalog;
    final hp = ResponsiveUtils.horizontalPadding(context);

    if (packageState.isLoading && catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (catalog == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(packageState.error ?? 'Could not load packages'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(riderPackageProvider.notifier).loadCatalog(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final currentPackage = catalog.packages.firstWhere(
      (p) => p.isCurrent,
      orElse: () => catalog.packages.first,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(riderPackageProvider.notifier).loadCatalog(),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: hp),
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _TierHeader(
            tier: catalog.currentLabel,
            profitShare: currentPackage.profitShareLabel,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _SectionTitle(title: AppLocalization.translate('features', lang)),
          ..._featuresForPackage(currentPackage).map(
            (f) => _FeatureTile(
              icon: f.icon,
              label: f.label,
              included: f.included,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _SectionTitle(
            title: AppLocalization.translate('upgrade_options', lang),
          ),
          ...catalog.packages.map(
            (option) => _UpgradeTile(
              option: option,
              lang: lang,
              isProcessing: packageState.isProcessing,
              onUpgrade: option.isUpgradeable
                  ? () => _handleUpgrade(option)
                  : null,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        ],
      ),
    );
  }

  List<_TierFeature> _featuresForPackage(RiderPackageOption option) {
    return [
      _TierFeature(Icons.trending_up, option.profitShareLabel, true),
      _TierFeature(Icons.directions_car, 'Booking access', true),
      _TierFeature(Icons.support_agent, 'Admin support', true),
      if (option.tier == 'pro')
        _TierFeature(Icons.local_offer, 'Exclusive promotions', true),
      if (option.tier == 'employee')
        _TierFeature(Icons.payments, 'Company-managed salary', true),
    ];
  }
}

class _TierHeader extends StatelessWidget {
  final String tier;
  final String profitShare;

  const _TierHeader({
    required this.tier,
    required this.profitShare,
  });

  @override
  Widget build(BuildContext context) {
    final isBasic = tier == 'Basic';
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBasic
              ? [Colors.grey.shade500, Colors.grey.shade600]
              : [const Color(0xFF5F2D82), const Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isBasic ? Icons.person_outline : Icons.workspace_premium,
            size: 56,
            color: Colors.white,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            tier,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            profitShare,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 16),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5F2D82),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool included;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.included,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: included ? const Color(0xFF5F2D82) : Colors.grey,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: included ? Colors.black87 : Colors.grey,
          ),
        ),
        trailing: Icon(
          included ? Icons.check_circle : Icons.cancel,
          color: included ? Colors.green : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  final RiderPackageOption option;
  final AppLanguage lang;
  final bool isProcessing;
  final VoidCallback? onUpgrade;

  const _UpgradeTile({
    required this.option,
    required this.lang,
    required this.isProcessing,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: option.isCurrent
              ? const Color(0xFF5F2D82)
              : Colors.grey.shade200,
          width: option.isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  option.priceLabel,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              option.profitShareLabel,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey.shade700,
              ),
            ),
            if (onUpgrade != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalization.translate('upgrade_to', lang)
                              .replaceAll('{{tier}}', option.label),
                        ),
                ),
              ),
            ] else if (option.isCurrent) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Text(
                'Current package',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierFeature {
  final IconData icon;
  final String label;
  final bool included;

  const _TierFeature(this.icon, this.label, this.included);
}
