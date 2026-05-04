import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/merchant_remote_datasource.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';

class MerchantEditProfileState {
  final String restaurantName;
  final String contactNumber;
  final String email;
  final String referralCode;
  final bool isSubmitting;
  final String? errorMessage;

  MerchantEditProfileState({
    required this.restaurantName,
    required this.contactNumber,
    required this.email,
    required this.referralCode,
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
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return MerchantEditProfileState(
      restaurantName: restaurantName ?? this.restaurantName,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      referralCode: referralCode ?? this.referralCode,
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
  }) : super(MerchantEditProfileState(
          restaurantName: restaurantName,
          contactNumber: contactNumber,
          email: email,
          referralCode: referralCode,
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

  Future<bool> attemptSave() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please complete all required fields',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // Get partner_id from auth state
      final authState = _ref.read(riderAuthProvider);
      final partnerId = authState.user?.partnerId;

      if (partnerId == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Partner ID not found. Please login again.',
        );
        return false;
      }

      print('🔍 Updating profile for partner_id: $partnerId');

      final dataSource = _ref.read(merchantDataSourceProvider);
      final request = UpdatePartnerRequest(
        name: state.restaurantName,
        supportPhone: state.contactNumber,
        supportEmail: state.email,
      );

      await dataSource.updatePartnerProfile(partnerId, request);
      print('✅ Profile updated successfully');

      // Refresh profile provider
      _ref.invalidate(merchantProfileProvider);

      // Success
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
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
  // Get current profile data
  final profileAsync = ref.watch(merchantProfileProvider);
  
  final profile = profileAsync.value;
  
  return MerchantEditProfileNotifier(
    ref,
    restaurantName: profile?.name ?? '',
    contactNumber: profile?.supportPhone ?? '',
    email: profile?.supportEmail ?? '',
    referralCode: profile?.referralCode ?? '',
  );
});
