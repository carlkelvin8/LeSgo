import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import 'merchant_profile_provider.dart';
import '../../../provider/auth/rider_auth_provider.dart';

/// Provider that exposes the current is_open state from the merchant profile.
final merchantIsOpenProvider = Provider<bool?>((ref) {
  final profile = ref.watch(merchantProfileProvider).valueOrNull;
  return profile?.isOpen;
});

/// Notifier to toggle the store open/close status.
final merchantStoreToggleProvider =
    StateNotifierProvider<MerchantStoreToggleNotifier, AsyncValue<void>>((ref) {
  return MerchantStoreToggleNotifier(ref);
});

class MerchantStoreToggleNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MerchantStoreToggleNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> toggle(bool isOpen) async {
    final authState = ref.read(riderAuthProvider);
    final partnerId = authState.user?.partnerId;
    if (partnerId == null) return;

    state = const AsyncValue.loading();
    try {
      final dataSource = ref.read(merchantDataSourceProvider);
      await dataSource.toggleStoreStatus(partnerId, isOpen);
      // Refresh the profile to reflect the new state
      ref.invalidate(merchantProfileProvider);
      state = const AsyncValue.data(null);
      AppLogger.debug('✅ Store toggled to ${isOpen ? "OPEN" : "CLOSED"}');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('Failed to toggle store status', e);
    }
  }
}
