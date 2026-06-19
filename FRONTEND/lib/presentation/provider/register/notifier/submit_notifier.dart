import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/di/local_storage_service.dart';

import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../data/data_source/dto/auth/register_request_dto.dart';
import '../../../../data/data_source/dto/user/update_user_request_dto.dart';
import '../../../../data/data_source/user_remote_datasource.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../domain/entities/user.dart';
import 'register_state.dart';

mixin SubmitNotifier on StateNotifier<RegisterState> {
  Future<bool> submitRegistration() async {
    print('🚀 DEBUG submitRegistration - START');
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      registeredUser: null,
    );

    try {
      print('🔍 DEBUG - Checking required fields...');
      print('  firstName: "${state.data.firstName}"');
      print('  lastName: "${state.data.lastName}"');
      print('  birthday: "${state.data.birthday}"');
      print('  email: "${state.data.email}"');
      print('  password: ${state.data.password.isNotEmpty ? "***" : "(empty)"}');
      print('  phoneNumber: "${state.data.phoneNumber}"');
      print('  termsAccepted: ${state.data.termsAccepted}');
      
      if (state.data.firstName.isEmpty ||
          state.data.lastName.isEmpty ||
          state.data.birthday.isEmpty ||
          state.data.email.isEmpty ||
          state.data.password.isEmpty ||
          state.data.phoneNumber.isEmpty ||
          !state.data.termsAccepted) {
        print('❌ ERROR - Missing required fields!');
        throw Exception('Please complete all required fields');
      }
      
      print('✅ All required fields present');

      final referralCode = state.data.referralCode.trim();
      
      print('🔍 DEBUG - Building RegisterRequestDto...');
      print('  Address data:');
      print('    houseNumber: "${state.data.address?.houseNumber}"');
      print('    streetName: "${state.data.address?.streetName}"');
      print('    subdivision: "${state.data.address?.subdivision}"');
      print('    barangay: "${state.data.address?.barangay}"');
      print('    city: "${state.data.address?.city}"');
      print('    province: "${state.data.address?.province}"');
      print('    zipCode: "${state.data.address?.zipCode}"');
      print('    latitude: ${state.data.address?.latitude}');
      print('    longitude: ${state.data.address?.longitude}');

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
      
      print('✅ RegisterRequestDto built successfully');
      print('🌐 DEBUG - Calling authDataSource.register()...');

      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.register(registerRequest);
      
      print('✅ API call completed');
      print('🔍 DEBUG - Response:');
      print('  success: ${response.success}');
      print('  message: "${response.message}"');
      print('  token: ${response.token != null ? "present (${response.token!.length} chars)" : "null"}');
      print('  user: ${response.user != null ? "present" : "null"}');

      if (!response.success) {
        print('❌ ERROR - Registration failed');
        print('  Message: "${response.message}"');
        throw Exception(
          response.message.isNotEmpty
              ? response.message
              : 'Registration failed. Please try again.',
        );
      }
      
      print('✅ Registration successful!');
      print('💾 DEBUG - Saving tokens...');

      final localStorage = getIt<LocalStorageService>();
      if (response.token != null && response.token!.isNotEmpty) {
        await localStorage.saveToken(response.token!);
        print('✅ Token saved');
      }
      if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
        await localStorage.saveRefreshToken(response.refreshToken!);
        print('✅ Refresh token saved');
      }

      final user = User(
        id: response.user?.id ?? '',
        email: response.user?.email ?? state.data.email,
        name: response.user?.name ??
            '${state.data.firstName} ${state.data.lastName}',
        token: response.token ?? '',
      );
      
      print('👤 DEBUG - User created: ${user.name} (${user.email})');

      state = state.copyWith(
        registeredUser: user,
        isLoading: false,
        error: null,
      );
      
      print('✅ State updated with registered user');

      final selfiePath = state.data.selfiePath;
      if (selfiePath.isNotEmpty && response.token != null) {
        print('📸 DEBUG - Uploading selfie...');
        await _uploadRegistrationSelfie(selfiePath);
        print('✅ Selfie uploaded');
      }

      print('🎉 submitRegistration - SUCCESS, returning true');
      return true;
    } catch (e) {
      print('❌ EXCEPTION in submitRegistration: $e');
      print('  Stack trace:');
      print(e);
      
      String errorMessage = 'Registration failed. Please try again.';
      
      // Extract detailed error message from DioException
      if (e.toString().contains('DioException')) {
        try {
          final dioError = e as dynamic;
          if (dioError.response != null) {
            final responseData = dioError.response?.data;
            print('🔍 DEBUG - Response data: $responseData');
            
            if (responseData is Map) {
              // Check for validation errors
              if (responseData.containsKey('errors')) {
                final errors = responseData['errors'] as Map;
                final errorMessages = <String>[];
                errors.forEach((key, value) {
                  if (value is List) {
                    errorMessages.addAll(value.map((e) => e.toString()));
                  } else {
                    errorMessages.add(value.toString());
                  }
                });
                errorMessage = errorMessages.join('\n');
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'].toString();
              }
            }
          }
        } catch (parseError) {
          print('⚠️ Could not parse error response: $parseError');
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        registeredUser: null,
      );
      print('🚫 submitRegistration - FAILED, returning false');
      print('📝 Error message shown to user: $errorMessage');
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
