import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../data/data_source/user_remote_datasource.dart';
import '../../../../data/data_source/dto/user/user_profile_dto.dart';
import '../../../../data/data_source/dto/user/update_user_request_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_utils.dart';

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
        state = state.copyWith(
          user: user,
          name: user.name,
          email: user.email,
          phone: user.phone ?? '',
          birthdate: user.dateOfBirth ?? '',
          profileImageUrl: user.profilePhoto,
          referralCode: user.referralCode ?? '',
          points: user.points ?? 0,
          address1: user.addressLine1 ?? '',
          address2: user.addressLine2 ?? '',
          isLoading: false,
        );
        print('🔵 ProfileProvider: State updated - name: "${state.name}", email: ${state.email}');
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
        state = state.copyWith(
          user: response.data,
          name: response.data!.name,
          email: response.data!.email,
          phone: response.data!.phone ?? state.phone,
          birthdate: response.data!.dateOfBirth ?? state.birthdate,
          profileImageUrl: response.data!.profilePhoto,
          address1: response.data!.addressLine1 ?? address1 ?? state.address1,
          address2: response.data!.addressLine2 ?? address2 ?? state.address2,
          isUpdating: false,
        );
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

  Future<void> updateProfileImage(dynamic imageFile) async {
    state = state.copyWith(isUpdating: true);
    try {
      String base64Image;
      String localPath;

      // Handle both XFile (from image_picker) and String path
      if (imageFile is String) {
        localPath = imageFile;
        if (kIsWeb) {
          // If it's a string on web, it's a blob URL - can't upload
          state = state.copyWith(profileImageUrl: localPath, isUpdating: false);
          return;
        }
        final bytes = await File(imageFile).readAsBytes();
        final ext = imageFile.toLowerCase().split('.').last;
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
      } else {
        // XFile - works on both web and mobile
        localPath = imageFile.path;
        final bytes = await imageFile.readAsBytes();
        // Detect image type from name
        final name = imageFile.name.toLowerCase();
        final mime = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
        base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final userDataSource = getIt<UserRemoteDataSource>();
      final request = UpdateUserRequestDto(profilePhoto: base64Image);
      final response = await userDataSource.updateMe(request);

      if (response.success && response.data != null) {
        // Use the URL returned by the API (stored on server)
        state = state.copyWith(
          profileImageUrl: response.data!.profilePhoto ?? localPath,
          isUpdating: false,
        );
      } else {
        // Optimistically show local image even if upload failed
        state = state.copyWith(profileImageUrl: localPath, isUpdating: false);
      }
    } catch (e) {
      // On error, keep the current image
      state = state.copyWith(isUpdating: false);
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
