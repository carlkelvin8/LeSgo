import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/promo_notification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/state/user_session_epoch.dart';
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
  void Function()? _resetUserScopedState;

  AuthNotifier(
    this._loginUseCase,
    this._logoutUseCase,
    this._localStorageService,
  ) : super(AuthState());

  void setUserScopedStateReset(void Function() reset) {
    _resetUserScopedState = reset;
  }

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
      if (user.role != 'customer') {
        await _localStorageService.clearToken();
        state = state.copyWith(
          isLoading: false,
          error:
              'This account is for ${user.role}s. Please use the ${user.role} app to login.',
          clearSuccessMessage: true,
        );
        return;
      }

      getIt<FavoritesService>().setUserScope(user.id);
      await getIt<NotificationService>().clearAll();
      _resetUserScopedState?.call();

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
    } catch (_) {
      message = 'Logged out locally';
    } finally {
      await _clearSession(disableBiometric: true);
    }
    return message;
  }

  Future<void> clearLocalSession() async {
    await _clearSession(disableBiometric: true);
  }

  /// Failed restore / invalid session: drop the token but keep biometric unlock.
  Future<void> clearSessionKeepBiometric() async {
    await _clearSession(disableBiometric: false);
  }

  Future<void> _clearSession({required bool disableBiometric}) async {
    if (disableBiometric) {
      await _localStorageService.clearSessionAndBiometric();
    } else {
      await _localStorageService.clearSessionKeepBiometric();
    }
    getIt<FavoritesService>().setUserScope(null);
    await getIt<NotificationService>().clearAll();
    _resetUserScopedState?.call();
    state = AuthState();
  }

  /// After Google OAuth, persist tokens and load the user profile into state.
  Future<bool> completeGoogleSignIn({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? profilePayload,
  }) async {
    await _localStorageService.saveToken(token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _localStorageService.saveRefreshToken(refreshToken);
    }

    try {
      User? authenticatedUser;
      try {
        final response = await getIt<UserRemoteDataSource>().getMe();
        final profile = response.data;
        if (response.success == true && profile != null) {
          authenticatedUser = User(
            id: profile.id.toString(),
            email: profile.email,
            name: profile.name,
            token: token,
            role: profile.role,
          );
        }
      } catch (_) {
        // Google auth already returned a verified token and user payload. A
        // transient/profile endpoint failure should not discard that valid
        // login; use the trusted payload returned by the auth endpoint.
      }

      if (authenticatedUser == null && profilePayload != null) {
        final id = profilePayload['id'];
        final email = profilePayload['email']?.toString();
        final name = profilePayload['name']?.toString();
        final role = profilePayload['role']?.toString();
        if (id != null &&
            email != null &&
            email.isNotEmpty &&
            name != null &&
            name.isNotEmpty &&
            role != null &&
            role.isNotEmpty) {
          authenticatedUser = User(
            id: id.toString(),
            email: email,
            name: name,
            token: token,
            role: role,
          );
        }
      }

      if (authenticatedUser == null) {
        await _localStorageService.clearToken();
        return false;
      }

      getIt<FavoritesService>().setUserScope(authenticatedUser.id);
      await getIt<NotificationService>().clearAll();
      _resetUserScopedState?.call();

      state = state.copyWith(user: authenticatedUser, clearError: true);

      // Role validation for the customer app.
      if (authenticatedUser.role != 'customer') {
        await _localStorageService.clearToken();
        getIt<FavoritesService>().setUserScope(null);
        state = AuthState(); // Clear state
        return false;
      }

      // Notification registration is post-login housekeeping. It must not
      // turn a successful authenticated session into a failed login when
      // FCM permissions, network, or the notification endpoint is unavailable.
      try {
        await getIt<PromoNotificationService>().registerDeviceToken();
        await getIt<NotificationService>().refreshFromBackend();
      } catch (_) {}
      return true;
    } catch (_) {
      await _localStorageService.clearToken();
      state = AuthState();
      return false;
    }
  }

  Future<bool> restoreSession() async {
    if (!_localStorageService.canRestoreSession()) {
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
        await clearSessionKeepBiometric();
        return false;
      }

      getIt<FavoritesService>().setUserScope(profile.id.toString());
      await getIt<NotificationService>().clearAll();
      _resetUserScopedState?.call();

      state = state.copyWith(
        user: User(
          id: profile.id.toString(),
          email: profile.email,
          name: profile.name,
          token: token,
          role: profile.role,
        ),
        rememberMe: _localStorageService.isRememberMeEnabled(),
        clearError: true,
      );

      // ✅ Role validation for customer app
      if (profile.role != 'customer') {
        getIt<FavoritesService>().setUserScope(null);
        await clearSessionKeepBiometric();
        return false;
      }

      await _localStorageService.refreshRememberMeExpiry();
      await getIt<PromoNotificationService>().registerDeviceToken();
      await getIt<NotificationService>().refreshFromBackend();
      return true;
    } catch (_) {
      // Network / transient errors must not wipe the biometric preference.
      // Leave the stored session for the next attempt or an explicit logout.
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
  final notifier = getIt<AuthNotifier>();
  notifier.setUserScopedStateReset(() {
    ref.read(userSessionEpochProvider.notifier).state++;
  });
  return notifier;
});
