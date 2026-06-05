import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/di/local_storage_service.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../data/data_source/dto/auth/register_request_dto.dart';
import '../../../../domain/entities/user.dart';
import 'register_state.dart';

mixin SubmitNotifier on StateNotifier<RegisterState> {
 
  Future<void> submitRegistration() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate required fields
      if (state.data.firstName.isEmpty ||
          state.data.lastName.isEmpty ||
          state.data.birthday.isEmpty ||
          state.data.email.isEmpty ||
          state.data.password.isEmpty ||
          state.data.phoneNumber.isEmpty ||
          !state.data.termsAccepted) {
        throw Exception('Please complete all required fields');
      }

      // Create registration request
      final registerRequest = RegisterRequestDto(
        name: '${state.data.firstName} ${state.data.lastName}',
        email: state.data.email,
        phone: state.data.phoneNumber,
        password: state.data.password,
        passwordConfirmation: state.data.confirmPassword,
        addressLine1: state.data.address != null 
            ? '${state.data.address!.houseNumber} ${state.data.address!.streetName}'.trim()
            : null,
        addressLine2: state.data.address?.subdivision,
        city: state.data.address?.city,
        province: state.data.address?.province,
        zipCode: state.data.address?.zipCode,
        latitude: state.data.address?.latitude,
        longitude: state.data.address?.longitude,
        termsAccepted: state.data.termsAccepted,
        privacyAccepted: state.data.termsAccepted, // Using same value for now
      );

      // Call registration API
      final authDataSource = getIt<AuthRemoteDataSource>();
      final response = await authDataSource.register(registerRequest);

      final localStorage = getIt<LocalStorageService>();
      if (response.token != null && response.token!.isNotEmpty) {
        await localStorage.saveToken(response.token!);
      }
      if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
        await localStorage.saveRefreshToken(response.refreshToken!);
      }

      // Create user from response
      final user = User(
        id: response.user?.id ?? '',
        email: response.user?.email ?? state.data.email,
        name: response.user?.name ?? '${state.data.firstName} ${state.data.lastName}',
        token: response.token ?? '',
      );

      state = state.copyWith(
        registeredUser: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = RegisterState();
  }
}
