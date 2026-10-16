import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';

class MerchantEditProfileState {
  final String restaurantName;
  final String contactNumber;
  final String email;
  final String referralCode;
  final String? logoUrl;
  final String? logoPath;
  final int prepTime;
  final Map<String, dynamic>? openingHours;
  final bool isSubmitting;
  final String? errorMessage;

  MerchantEditProfileState({
    required this.restaurantName,
    required this.contactNumber,
    required this.email,
    required this.referralCode,
    this.logoUrl,
    this.logoPath,
    this.prepTime = 30,
    this.openingHours,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isValid =>
      restaurantName.isNotEmpty &&
      contactNumber.isNotEmpty &&
      email.isNotEmpty;

  MerchantEditProfileState copyWith({
    String? restaurantName,
    String? contactNumber,
    String? email,
    String? referralCode,
    String? logoUrl,
    String? logoPath,
    bool clearLogoPath = false,
    int? prepTime,
    Map<String, dynamic>? openingHours,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MerchantEditProfileState(
      restaurantName: restaurantName ?? this.restaurantName,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      referralCode: referralCode ?? this.referralCode,
      logoUrl: logoUrl ?? this.logoUrl,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      prepTime: prepTime ?? this.prepTime,
      openingHours: openingHours ?? this.openingHours,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class MerchantEditProfileNotifier extends StateNotifier<MerchantEditProfileState> {
  final Ref _ref;

  MerchantEditProfileNotifier(
    this._ref, {
    required String restaurantName,
    required String contactNumber,
    required String email,
    required String referralCode,
    String? logoUrl,
  }) : super(MerchantEditProfileState(
          restaurantName: restaurantName,
          contactNumber: contactNumber,
          email: email,
          referralCode: referralCode,
          logoUrl: logoUrl,
        ));

  void updateRestaurantName(String value) {
    state = state.copyWith(restaurantName: value);
  }

  void updateContactNumber(String value) {
    state = state.copyWith(contactNumber: value);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void setReferralCode(String value) {
    if (value.isEmpty || value == state.referralCode) return;
    state = state.copyWith(referralCode: value);
  }

  void updateLogoPath(String? path) {
    state = state.copyWith(logoPath: path);
  }

  void updatePrepTime(int minutes) {
    state = state.copyWith(prepTime: minutes.clamp(5, 180));
  }

  void updateOpeningHours(Map<String, dynamic> hours) {
    state = state.copyWith(openingHours: hours);
  }

  Future<bool> attemptSave() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please complete all required fields',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final authState = _ref.read(riderAuthProvider);
      final profile = _ref.read(merchantProfileProvider).value;
      final partnerId = authState.user?.partnerId ?? profile?.id;

      if (partnerId == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Partner ID not found. Please login again.',
        );
        return false;
      }

      final dataSource = _ref.read(merchantDataSourceProvider);
      final request = UpdatePartnerRequest(
        name: state.restaurantName,
        supportPhone: state.contactNumber,
        supportEmail: state.email,
        logoUrl: state.logoUrl,
        logoPath: state.logoPath,
        estimatedDeliveryMinutes: state.prepTime,
        openingHours: state.openingHours,
      );

      final updated = await dataSource.updatePartnerProfile(partnerId, request);
      // Confirm a newly selected logo is present on the persisted partner
      // record before reporting success to the merchant.
      final confirmed = state.logoPath != null
          ? await dataSource.getPartnerProfile(partnerId)
          : updated;
      if (state.logoPath != null &&
          (confirmed.logoUrl == null || confirmed.logoUrl!.isEmpty)) {
        throw Exception('Profile photo was not saved. Please try again.');
      }
      _ref.invalidate(merchantProfileProvider);

      state = state.copyWith(
        isSubmitting: false,
        logoUrl: confirmed.logoUrl ?? updated.logoUrl ?? state.logoUrl,
        clearLogoPath: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: ApiService.extractError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final merchantEditProfileProvider = StateNotifierProvider.autoDispose<
    MerchantEditProfileNotifier, MerchantEditProfileState>((ref) {
  // Only a different account/store should recreate this draft. Profile and
  // referral polling must not erase a selected photo or unsaved field edits.
  ref.watch(riderAuthProvider.select((auth) => (auth.user?.id, auth.user?.partnerId)));
  final profile = ref.read(merchantProfileProvider).value;
  final authState = ref.read(riderAuthProvider);
  final referralFromApi = ref.read(merchantReferralCodeProvider).value;
  final referralCode = (referralFromApi != null && referralFromApi.isNotEmpty)
      ? referralFromApi
      : (profile?.referralCode ?? '');

  // Fall back to user's registration data if partner profile fields are empty
  final contactNumber = (profile?.supportPhone != null && profile!.supportPhone!.isNotEmpty)
      ? profile.supportPhone!
      : (authState.user?.phone ?? '');
  final email = (profile?.supportEmail != null && profile!.supportEmail!.isNotEmpty)
      ? profile.supportEmail!
      : (authState.user?.email ?? '');

  final notifier = MerchantEditProfileNotifier(
    ref,
    restaurantName: profile?.name ?? '',
    contactNumber: contactNumber,
    email: email,
    referralCode: referralCode,
    logoUrl: profile?.logoUrl,
  );

  final initialPrepTime = profile?.estimatedDeliveryMinutes;
  if (initialPrepTime != null && initialPrepTime > 0) {
    notifier.updatePrepTime(initialPrepTime);
  }

  final initialHours = profile?.openingHours;
  if (initialHours != null && initialHours.isNotEmpty) {
    notifier.updateOpeningHours(Map<String, dynamic>.from(initialHours));
  }

  ref.listen<AsyncValue<String>>(merchantReferralCodeProvider, (previous, next) {
    next.whenData(notifier.setReferralCode);
  });

  return notifier;
});
