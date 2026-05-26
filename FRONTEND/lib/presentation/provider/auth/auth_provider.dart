import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/auth/login/login_request.dart';
import '../../../data/data_source/user_remote_datasource.dart';
import '../../../data/data_source/auth_remote_datasource.dart';
import '../../../domain/repository/user_repository.dart';
import '../../../domain/use_cases/login_usecase.dart';
import '../../../domain/use_cases/logout_usecase.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final bool rememberMe;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.rememberMe = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? rememberMe,
    bool clearError = false,
    bool clearSuccessMessage = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  bool get isAuthenticated => user != null;
}

@injectable
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final LocalStorageService _localStorageService;

  AuthNotifier(this._loginUseCase, this._logoutUseCase, this._localStorageService)
    : super(AuthState());

  Future<void> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    if (request.email.isEmpty || request.password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter email and password',
      );
      return;
    }

    try {
      final user = await _loginUseCase(request);

      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        clearError: true,
        successMessage: 'Login successful!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Login failed. Check email and password.',
          fallbackTl: 'Hindi makapag-log in. Suriin ang email at password.',
        ),
        clearSuccessMessage: true,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccessMessage: true);
  }

  Future<String> logout() async {
    String message = 'Logged out successfully';
    try {
      message = await _logoutUseCase();
    } finally {
      await _localStorageService.clearToken();
      state = AuthState();
    }
    return message;
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }
}

// -----------------------------------------------------------------------------
// Dependency Injection Providers
// -----------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return getIt<AuthRemoteDataSource>();
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return getIt<UserRemoteDataSource>();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return getIt<UserRepository>();
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return getIt<LoginUseCase>();
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return getIt<LogoutUseCase>();
});

// Final Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return getIt<AuthNotifier>();
});
