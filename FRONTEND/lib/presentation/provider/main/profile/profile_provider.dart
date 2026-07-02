import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/user_remote_datasource.dart';
import '../../../../data/data_source/dto/user/user_profile_dto.dart';
import '../../../../data/data_source/dto/user/update_user_request_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/referral_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

String? _resolveProfileImageUrl(UserProfileDto user) {
  final raw = (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
      ? user.profilePhoto
      : user.profilePicture;
  if (raw == null || raw.isEmpty) return null;
  return MediaUrlUtils.resolve(raw) ?? raw;
}

class ProfileState {
  final UserProfileDto? user;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  
  // UI fields for compatibility
  final String name;
  final String birthdate;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String address1;
  final String address2;
  final String referralCode;
  final int points;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.name = '',
    this.birthdate = '',
    this.email = '',
    this.phone = '',
    this.profileImageUrl,
    this.address1 = '',
    this.address2 = '',
    this.referralCode = '',
    this.points = 0,
  });

  ProfileState copyWith({
    UserProfileDto? user,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    String? name,
    String? birthdate,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? address1,
    String? address2,
    String? referralCode,
    int? points,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      referralCode: referralCode ?? this.referralCode,
      points: points ?? this.points,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    print('🔵 ProfileProvider: Starting loadProfile...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userDataSource = getIt<UserRemoteDataSource>();
      print('🔵 ProfileProvider: Calling getMe()...');
      final response = await userDataSource.getMe();
      print('🔵 ProfileProvider: Response - success: ${response.success}, data: ${response.data}');

      if (response.success && response.data != null) {
        final user = response.data!;
        print('🔵 ProfileProvider: User fields - id: ${user.id}, name: "${user.name}", email: ${user.email}, phone: ${user.phone}');
        print('🔵 ProfileProvider: Profile photo URL from API: ${user.profilePhoto}');
        state = state.copyWith(
          user: user,
          name: user.name,
          email: user.email,
          phone: user.phone ?? '',
          birthdate: user.dateOfBirth ?? '',
          profileImageUrl: _resolveProfileImageUrl(user),
          referralCode: ReferralUtils.displayCode(
            user.referralCode,
            user.id,
            name: user.name,
          ),
          points: user.points ?? 0,
          address1: user.addressLine1 ?? '',
          address2: user.addressLine2 ?? '',
          isLoading: false,
        );
        print('🔵 ProfileProvider: State updated - name: "${state.name}", email: ${state.email}, profileImageUrl: ${state.profileImageUrl}');
      } else {
        print('🔴 ProfileProvider: Failed - success: ${response.success}, data is null: ${response.data == null}');
        state = state.copyWith(isLoading: false, error: 'Failed to load profile');
      }
    } catch (e, stackTrace) {
      print('🔴 ProfileProvider: Error - $e');
      print('🔴 ProfileProvider: StackTrace - $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? profilePhoto,
    String? address1,
    String? address2,
    BuildContext? context,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final userDataSource = getIt<UserRemoteDataSource>();
      final request = UpdateUserRequestDto(
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profilePhoto: profilePhoto,
        addressLine1: address1,
        addressLine2: address2,
      );

      final response = await userDataSource.updateMe(request);

      if (response.success && response.data != null) {
        final userData = response.data!;
        print('🔵 ProfileProvider: Update successful - profilePhoto from API: ${userData.profilePhoto}');
        
        // Create a new state with all updated fields
        // IMPORTANT: Use null for profileImageUrl if API returns null
        final newState = state.copyWith(
          user: userData,
          name: userData.name,
          email: userData.email,
          phone: userData.phone ?? state.phone,
          birthdate: userData.dateOfBirth ?? state.birthdate,
          address1: userData.addressLine1 ?? address1 ?? state.address1,
          address2: userData.addressLine2 ?? address2 ?? state.address2,
          isUpdating: false,
        );
        
        // Handle profileImageUrl separately to allow setting it to null
        final resolvedPhoto = _resolveProfileImageUrl(userData);
        if (resolvedPhoto != null) {
          state = newState.copyWith(profileImageUrl: resolvedPhoto);
        } else {
          // Create a completely new state with null profileImageUrl
          state = ProfileState(
            user: newState.user,
            name: newState.name,
            email: newState.email,
            phone: newState.phone,
            birthdate: newState.birthdate,
            profileImageUrl: null, // Explicitly set to null
            address1: newState.address1,
            address2: newState.address2,
            referralCode: state.referralCode,
            points: state.points,
            isUpdating: false,
          );
        }
        
        print('🔵 ProfileProvider: State updated - profileImageUrl: ${state.profileImageUrl}');
        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Profile updated successfully');
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to update profile',
        );
        if (context != null && context.mounted) {
          SnackBarUtils.showError(context, 'Failed to update profile');
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error updating profile: ${e.toString()}',
        );
      }
      return false;
    }
  }

  Future<bool> updateProfileImage(dynamic imageFile) async {
    print('🔵 ProfileProvider: updateProfileImage called');
    print('🔵 ProfileProvider: imageFile type: ${imageFile.runtimeType}');
    
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final XFile xFile = imageFile is XFile
          ? imageFile
          : XFile(imageFile as String);

      print('🔵 ProfileProvider: XFile created - path: ${xFile.path}');

      final userDataSource = getIt<UserRemoteDataSource>();
      UserProfileDto? updatedUser;

      try {
        print('🔵 ProfileProvider: Attempting FileUploadService upload...');
        final uploaded = await getIt<FileUploadService>().uploadFile(
          xFile,
          context: 'profile',
        );
        print('✅ ProfileProvider: File uploaded! URL: ${uploaded.url}');
        
        final response = await userDataSource.updateMe(
          UpdateUserRequestDto(profilePhoto: uploaded.url),
        );
        print('🔵 ProfileProvider: updateMe response - success: ${response.success}');
        
        if (response.success && response.data != null) {
          updatedUser = response.data;
          print('✅ ProfileProvider: User updated via FileUploadService!');
        }
      } catch (mediaError) {
        print('⚠️ ProfileProvider: FileUploadService failed: $mediaError');
        print('🔵 ProfileProvider: Trying direct uploadProfilePicture...');
        
        final response = await userDataSource.uploadProfilePicture(xFile);
        print('🔵 ProfileProvider: uploadProfilePicture response - success: ${response.success}');
        
        if (response.success && response.data != null) {
          updatedUser = response.data;
          print('✅ ProfileProvider: User updated via uploadProfilePicture!');
        }
      }

      if (updatedUser != null) {
        final resolvedUrl = _resolveProfileImageUrl(updatedUser);
        print('✅ ProfileProvider: Profile updated! New URL: $resolvedUrl');
        
        state = state.copyWith(
          user: updatedUser,
          profileImageUrl: resolvedUrl,
          isUpdating: false,
          error: null,
        );
        return true;
      }

      print('❌ ProfileProvider: No updated user received');
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to upload profile picture',
      );
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileProvider: Profile image upload error: $e\n$stackTrace');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
