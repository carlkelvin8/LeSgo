import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/rider_package_api.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/rider_commission_utils.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_wallet_provider.dart';

class RiderPackageState {
  final RiderPackageCatalog? catalog;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  const RiderPackageState({
    this.catalog,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  RiderPackageState copyWith({
    RiderPackageCatalog? catalog,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    bool clearError = false,
  }) {
    return RiderPackageState(
      catalog: catalog ?? this.catalog,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderPackageNotifier extends StateNotifier<RiderPackageState> {
  RiderPackageNotifier(this.ref) : super(const RiderPackageState());

  final Ref ref;

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final catalog = await RiderPackageApi.fetchCatalog();
      state = state.copyWith(catalog: catalog, isLoading: false);
    } catch (e) {
      final user = ref.read(riderAuthProvider).user;
      final current = RiderCommissionUtils.normalizePackageTier(user?.packageTier);
      state = state.copyWith(
        catalog: _fallbackCatalog(current),
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Showing default package prices. Connect to the server for live admin pricing.',
          fallbackTl: 'Default package prices ang ipinapakita. Kailangan ng server para sa admin pricing.',
        ),
      );
    }
  }

  RiderPackageCatalog _fallbackCatalog(String currentTier) {
    bool canUpgrade(String target) {
      final ranks = {'basic': 1, 'advance': 2, 'pro': 3, 'employee': 4};
      final current = ranks[currentTier] ?? 1;
      final next = ranks[target] ?? 0;
      return next > current && target != 'employee' && target != 'basic';
    }

    return RiderPackageCatalog(
      currentTier: currentTier,
      currentLabel: RiderCommissionUtils.labelForPackage(currentTier),
      packages: [
        RiderPackageOption(
          tier: 'basic',
          label: 'Basic',
          commissionRate: RiderCommissionUtils.basicRate,
          commissionPercent: 70,
          profitShareLabel: RiderCommissionUtils.profitShareLabel('basic'),
          oneTimePrice: 0,
          isCurrent: currentTier == 'basic',
          isUpgradeable: false,
        ),
        RiderPackageOption(
          tier: 'advance',
          label: 'Advance',
          commissionRate: RiderCommissionUtils.advanceRate,
          commissionPercent: 80,
          profitShareLabel: RiderCommissionUtils.profitShareLabel('advance'),
          oneTimePrice: RiderCommissionUtils.advanceOneTimePrice,
          isCurrent: currentTier == 'advance',
          isUpgradeable: canUpgrade('advance'),
        ),
        RiderPackageOption(
          tier: 'pro',
          label: 'Pro',
          commissionRate: RiderCommissionUtils.proRate,
          commissionPercent: 90,
          profitShareLabel: RiderCommissionUtils.profitShareLabel('pro'),
          oneTimePrice: RiderCommissionUtils.proOneTimePrice,
          isCurrent: currentTier == 'pro',
          isUpgradeable: canUpgrade('pro'),
        ),
        RiderPackageOption(
          tier: 'employee',
          label: 'Employee',
          profitShareLabel: RiderCommissionUtils.profitShareLabel('employee'),
          isCurrent: currentTier == 'employee',
          isUpgradeable: false,
        ),
      ],
    );
  }

  Future<RiderPackageUpgradeCheckout?> upgradeWithLesPay(String tier) async {
    return _runUpgrade(tier: tier, paymentMethod: 'lespay');
  }

  Future<RiderPackageUpgradeCheckout?> startXenditUpgrade(String tier) async {
    return _runUpgrade(tier: tier, paymentMethod: 'xendit');
  }

  Future<RiderPackageUpgradeCheckout?> confirmXenditUpgrade(
    String invoiceId,
  ) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final checkout = await RiderPackageApi.confirmUpgrade(invoiceId: invoiceId);
      await _applyUpgradeResult(checkout);
      state = state.copyWith(isProcessing: false);
      return checkout;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not confirm package payment.',
          fallbackTl: 'Hindi ma-confirm ang bayad sa package.',
        ),
      );
      return null;
    }
  }

  Future<RiderPackageUpgradeCheckout?> _runUpgrade({
    required String tier,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final checkout = await RiderPackageApi.startUpgrade(
        tier: tier,
        paymentMethod: paymentMethod,
      );
      if (checkout.isCompleted) {
        await _applyUpgradeResult(checkout);
      }
      state = state.copyWith(isProcessing: false);
      return checkout;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Package upgrade failed. Please try again.',
          fallbackTl: 'Hindi natuloy ang package upgrade. Subukan muli.',
        ),
      );
      return null;
    }
  }

  Future<void> _applyUpgradeResult(RiderPackageUpgradeCheckout checkout) async {
    final tier = checkout.packageTier ?? checkout.targetTier;
    if (tier.isEmpty) return;

    ref.read(riderAuthProvider.notifier).updatePackageTier(
          packageTier: tier,
          commissionRate: checkout.commissionRate,
        );

    if (checkout.isCompleted) {
      await ref.read(riderWalletProvider.notifier).loadWallet();
      await loadCatalog();
    }
  }
}

final riderPackageProvider =
    StateNotifierProvider<RiderPackageNotifier, RiderPackageState>((ref) {
  return RiderPackageNotifier(ref);
});
