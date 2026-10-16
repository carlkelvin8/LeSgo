import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/di/local_storage_service.dart';

import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../data/data_source/dto/auth/register_request_dto.dart';
import '../../../../domain/entities/user.dart';
import 'register_state.dart';

mixin SubmitNotifier on StateNotifier<RegisterState> {
  Future<bool> submitRegistration() async {
    print('🚀 DEBUG submitRegistration - START');

    state = state.copyWith(isLoading: true, error: null, registeredUser: null);

    try {
      print('🔍 DEBUG - Checking required fields...');
      print('  firstName: "${state.data.firstName}"');
      print('  lastName: "${state.data.lastName}"');
      print('  birthday: "${state.data.birthday}"');
      print('  email: "${state.data.email}"');
      print(
        '  password: ${state.data.password.isNotEmpty ? "***" : "(empty)"}',
      );
      print('  phoneNumber: "${state.data.phoneNumber}"');
      print('  termsAccepted: ${state.data.termsAccepted}');

      if (state.data.firstName.isEmpty ||
          state.data.lastName.isEmpty ||
          state.data.birthday.isEmpty ||
          state.data.email.isEmpty ||
          state.data.password.isEmpty ||
          state.data.phoneNumber.isEmpty ||
          !state.data.hasIdentityVerification ||
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
        phoneVerificationToken: state.data.phoneVerificationToken.isEmpty
            ? null
            : state.data.phoneVerificationToken,
        password: state.data.password,
        passwordConfirmation: state.data.confirmPassword,
        dateOfBirth: _toIsoDate(state.data.birthday),
        referralCode: referralCode.isEmpty ? null : referralCode,
        addressLine1: state.data.address != null
            ? '${state.data.address!.houseNumber} ${state.data.address!.streetName}'
                  .trim()
            : null,
        addressLine2: state.data.address?.deliveryDetails,
        isDefault: state.data.address?.isDefault ?? false,
        city: state.data.address?.city,
        province: state.data.address?.province,
        zipCode: state.data.address?.zipCode,
        latitude: state.data.address?.latitude,
        longitude: state.data.address?.longitude,
        termsAccepted: state.data.termsAccepted,
        privacyAccepted: state.data.termsAccepted,
        idType: state.data.idType,
        idNumber: state.data.idNumber.trim(),
        role: 'customer',
      );

      print('✅ RegisterRequestDto built successfully');
      print('🌐 DEBUG - Calling authDataSource.register()...');

      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.register(
        registerRequest,
        selfie: XFile(state.data.selfiePath),
        validIdFront: XFile(state.data.validIdFrontPath),
        validIdBack: XFile(state.data.validIdBackPath),
      );

      print('✅ API call completed');
      print('🔍 DEBUG - Response:');
      print('  success: ${response.success}');
      print('  message: "${response.message}"');
      print(
        '  token: ${response.token != null ? "present (${response.token!.length} chars)" : "null"}',
      );
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
        name:
            response.user?.name ??
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

      print('🎉 submitRegistration - SUCCESS, returning true');
      return true;
    } catch (e) {
      print('❌ EXCEPTION in submitRegistration: $e');
      print('  Exception type: ${e.runtimeType}');

      String errorMessage = 'Registration failed. Please try again.';

      // Extract detailed error message from DioException
      try {
        if (e is DioException) {
          print('🔍 DEBUG - DioException detected');
          print('  Response: ${e.response}');
          print('  Response data: ${e.response?.data}');
          print('  Response statusCode: ${e.response?.statusCode}');

          if (e.response != null && e.response!.data != null) {
            final responseData = e.response!.data;
            print('🔍 DEBUG - Response data type: ${responseData.runtimeType}');

            if (responseData is Map) {
              // Check for Laravel validation errors
              if (responseData.containsKey('errors')) {
                print('✅ Found validation errors in response');
                final errors = responseData['errors'];
                print('  Errors: $errors');
                final errorMessages = <String>[];
                if (errors is Map) {
                  errors.forEach((key, value) {
                    if (value is List) {
                      errorMessages.addAll(value.map((e) => e.toString()));
                    } else {
                      errorMessages.add(value.toString());
                    }
                  });
                }
                if (errorMessages.isNotEmpty) {
                  errorMessage = errorMessages.join('\n');
                }
              } else if (responseData.containsKey('message')) {
                print('✅ Found message in response');
                errorMessage = responseData['message'].toString();
              }
            } else if (responseData is String) {
              print('✅ Response data is string');
              errorMessage = responseData;
            }
          }
        }
      } catch (parseError) {
        print('⚠️ Could not parse error response: $parseError');
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        registeredUser: null,
      );
      print('🚫 submitRegistration - FAILED, returning false');
      print('📝 Error message shown to user: "$errorMessage"');
      return false;
    }
  }

  void reset() {
    state = RegisterState();
  }
}

String _toIsoDate(String value) {
  final parts = value.trim().split('/');
  if (parts.length == 3) {
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month != null && day != null && year != null) {
      return '${year.toString().padLeft(4, '0')}-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}';
    }
  }
  return value;
}
