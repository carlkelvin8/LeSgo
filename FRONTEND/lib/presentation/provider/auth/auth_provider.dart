import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/promo_notification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/data_source/user_remote_datasource.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/auth/login/login_request.dart';
import '../../../domain/exceptions/two_factor_auth_required_exception.dart';
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
  final bool requiresTwoFactor;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.rememberMe = false,
    this.requiresTwoFactor = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? rememberMe,
    bool? requiresTwoFactor,
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
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
    );
  }

  bool get isAuthenticated => user != null;
}

@injectable
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final LocalStorageService _localStorageService;

  AuthNotifier(
    this._loginUseCase,
    this._logoutUseCase,
    this._localStorageService,
  ) : super(AuthState());

  Future<void> login(LoginRequest request) async {
    state = state.copyWith(
      isLoading: true,
      requiresTwoFactor: false,
      clearError: true,
    );

    if (request.email.isEmpty || request.password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter email and password',
      );
      return;
    }

    try {
      final user = await _loginUseCase(request);

      // ✅ Role validation for customer app
      if (user.role != null && user.role != 'customer') {
        state = state.copyWith(
          isLoading: false,
          error:
              'This account is for ${user.role}s. Please use the ${user.role} app to login.',
          clearSuccessMessage: true,
        );
        return;
      }

      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        clearError: true,
        successMessage: 'Login successful!',
        requiresTwoFactor: false,
      );

      await getIt<PromoNotificationService>().registerDeviceToken();
      await getIt<NotificationService>().refreshFromBackend();
    } on TwoFactorAuthRequiredException catch (e) {
      state = state.copyWith(
        isLoading: false,
        requiresTwoFactor: true,
        error: request.twoFactorCode == null ? null : e.message,
        clearError: request.twoFactorCode == null,
        clearSuccessMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        requiresTwoFactor: false,
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
      await _localStorageService.clearRememberMeSession();
      state = AuthState();
    }
    return message;
  }

  /// After Google OAuth, persist tokens and load the user profile into state.
  Future<bool> completeGoogleSignIn({
    required String token,
    String? refreshToken,
  }) async {
    await _localStorageService.saveToken(token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _localStorageService.saveRefreshToken(refreshToken);
    }

    try {
      final response = await getIt<UserRemoteDataSource>().getMe();
      final profile = response.data;

      if (response.success != true || profile == null) {
        return false;
      }

      state = state.copyWith(
        user: User(
          id: profile.id.toString(),
          email: profile.email,
          name: profile.name,
          token: token,
          role: profile.role,
        ),
        clearError: true,
      );

      // ✅ Role validation for customer app (allow null-role users same as regular login)
      if (profile.role != null && profile.role != 'customer') {
        state = AuthState(); // Clear state
        return false;
      }

      await getIt<PromoNotificationService>().registerDeviceToken();
      await getIt<NotificationService>().refreshFromBackend();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreSession() async {
    if (!_localStorageService.isRememberMeSessionValid()) {
      return false;
    }

    final token = _localStorageService.token;
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await getIt<UserRemoteDataSource>().getMe();
      final profile = response.data;

      if (response.success != true || profile == null) {
        return false;
      }

      state = state.copyWith(
        user: User(
          id: profile.id.toString(),
          email: profile.email,
          name: profile.name,
          token: token,
          role: profile.role,
        ),
        rememberMe: true,
        clearError: true,
      );

      // ✅ Role validation for customer app
      if (profile.role != 'customer') {
        state = AuthState(); // Clear state
        return false;
      }

      await _localStorageService.refreshRememberMeExpiry();
      await getIt<PromoNotificationService>().registerDeviceToken();
      await getIt<NotificationService>().refreshFromBackend();
      return true;
    } catch (_) {
      return false;
    }
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
    if (!value) {
      _localStorageService.clearRememberMePreference();
    }
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
