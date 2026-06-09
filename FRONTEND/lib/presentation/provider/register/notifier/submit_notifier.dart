import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/di/local_storage_service.dart';
import 'package:cross_file/cross_file.dart';

import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../data/data_source/dto/auth/register_request_dto.dart';
import '../../../../data/data_source/dto/user/update_user_request_dto.dart';
import '../../../../data/data_source/user_remote_datasource.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../domain/entities/user.dart';
import 'register_state.dart';

mixin SubmitNotifier on StateNotifier<RegisterState> {
  Future<bool> submitRegistration() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      registeredUser: null,
    );

    try {
      if (state.data.firstName.isEmpty ||
          state.data.lastName.isEmpty ||
          state.data.birthday.isEmpty ||
          state.data.email.isEmpty ||
          state.data.password.isEmpty ||
          state.data.phoneNumber.isEmpty ||
          !state.data.termsAccepted) {
        throw Exception('Please complete all required fields');
      }

      final referralCode = state.data.referralCode.trim();

      final registerRequest = RegisterRequestDto(
        name: '${state.data.firstName} ${state.data.lastName}',
        email: state.data.email,
        phone: state.data.phoneNumber,
        password: state.data.password,
        passwordConfirmation: state.data.confirmPassword,
        dateOfBirth: state.data.birthday,
        referralCode: referralCode.isEmpty ? null : referralCode,
        addressLine1: state.data.address != null
            ? '${state.data.address!.houseNumber} ${state.data.address!.streetName}'
                .trim()
            : null,
        addressLine2: state.data.address?.subdivision,
        city: state.data.address?.city,
        province: state.data.address?.province,
        zipCode: state.data.address?.zipCode,
        latitude: state.data.address?.latitude,
        longitude: state.data.address?.longitude,
        termsAccepted: state.data.termsAccepted,
        privacyAccepted: state.data.termsAccepted,
        role: 'customer',
      );

      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.register(registerRequest);

      if (!response.success) {
        throw Exception(
          response.message.isNotEmpty
              ? response.message
              : 'Registration failed. Please try again.',
        );
      }

      final localStorage = getIt<LocalStorageService>();
      if (response.token != null && response.token!.isNotEmpty) {
        await localStorage.saveToken(response.token!);
      }
      if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
        await localStorage.saveRefreshToken(response.refreshToken!);
      }

      final user = User(
        id: response.user?.id ?? '',
        email: response.user?.email ?? state.data.email,
        name: response.user?.name ??
            '${state.data.firstName} ${state.data.lastName}',
        token: response.token ?? '',
      );

      state = state.copyWith(
        registeredUser: user,
        isLoading: false,
        error: null,
      );

      final selfiePath = state.data.selfiePath;
      if (selfiePath.isNotEmpty && response.token != null) {
        await _uploadRegistrationSelfie(selfiePath);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        registeredUser: null,
      );
      return false;
    }
  }

  void reset() {
    state = RegisterState();
  }

  Future<void> _uploadRegistrationSelfie(String imagePath) async {
    try {
      final xFile = XFile(imagePath);
      final uploaded = await getIt<FileUploadService>().uploadFile(
        xFile,
        context: 'profile',
      );
      await getIt<UserRemoteDataSource>().updateMe(
        UpdateUserRequestDto(profilePhoto: uploaded.url),
      );
    } catch (_) {
      try {
        await getIt<UserRemoteDataSource>().uploadProfilePicture(XFile(imagePath));
      } catch (_) {}
    }
  }
}
