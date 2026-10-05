import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/biometric_unlock_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/dto/security/security_dto.dart';
import '../../../../data/data_source/security_remote_datasource.dart';

class SecuritySettingsState {
  final SecurityDashboardDto? dashboard;
  final List<BiometricDto> registeredBiometrics;
  final List<AuditLogDto> auditLogs;
  final TwoFactorSetupDto? twoFactorSetup;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final bool localBiometricEnabled;
  final bool deviceSupportsBiometrics;

  const SecuritySettingsState({
    this.dashboard,
    this.registeredBiometrics = const [],
    this.auditLogs = const [],
    this.twoFactorSetup,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.localBiometricEnabled = false,
    this.deviceSupportsBiometrics = false,
  });

  bool get twoFactorEnabled => dashboard?.twoFactorEnabled ?? false;

  SecuritySettingsState copyWith({
    SecurityDashboardDto? dashboard,
    List<BiometricDto>? registeredBiometrics,
    List<AuditLogDto>? auditLogs,
    TwoFactorSetupDto? twoFactorSetup,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    bool? localBiometricEnabled,
    bool? deviceSupportsBiometrics,
    bool clearError = false,
    bool clearSetup = false,
  }) {
    return SecuritySettingsState(
      dashboard: dashboard ?? this.dashboard,
      registeredBiometrics: registeredBiometrics ?? this.registeredBiometrics,
      auditLogs: auditLogs ?? this.auditLogs,
      twoFactorSetup: clearSetup
          ? null
          : (twoFactorSetup ?? this.twoFactorSetup),
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      localBiometricEnabled:
          localBiometricEnabled ?? this.localBiometricEnabled,
      deviceSupportsBiometrics:
          deviceSupportsBiometrics ?? this.deviceSupportsBiometrics,
    );
  }
}

class SecuritySettingsNotifier extends StateNotifier<SecuritySettingsState> {
  SecuritySettingsNotifier(
    this._biometrics, {
    SecurityRemoteDataSource? dataSource,
  }) : _securityDs = dataSource ?? getIt<SecurityRemoteDataSource>(),
       super(const SecuritySettingsState(isLoading: true)) {
    loadSecurity();
  }

  final SecurityRemoteDataSource _securityDs;
  AppPreferencesService get _prefs => _biometrics.preferences;
  final BiometricUnlockService _biometrics;

  Future<void> loadSecurity() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final supported = await _biometrics.isSupported();
      if (!mounted) return;
      state = state.copyWith(
        localBiometricEnabled: _prefs.biometricUnlockEnabled,
        deviceSupportsBiometrics: supported,
        isLoading: false,
      );

      final dashboard = await _securityDs.getSecurityDashboard();
      final biometrics = await _securityDs.listBiometrics();
      final logs = await _securityDs.getAuditLogs(perPage: 10);
      if (!mounted) return;

      state = state.copyWith(
        dashboard: dashboard,
        registeredBiometrics: biometrics,
        auditLogs: logs,
        localBiometricEnabled: _prefs.biometricUnlockEnabled,
        deviceSupportsBiometrics: supported,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        localBiometricEnabled: _prefs.biometricUnlockEnabled,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load security settings.',
          fallbackTl: 'Hindi ma-load ang security settings.',
        ),
      );
    }
  }

  Future<TwoFactorSetupDto?> startTwoFactorSetup() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final setup = await _securityDs.setup2FA();
      state = state.copyWith(isProcessing: false, twoFactorSetup: setup);
      return setup;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not start 2FA setup.',
          fallbackTl: 'Hindi masimulan ang 2FA setup.',
        ),
      );
      return null;
    }
  }

  Future<bool> verifyTwoFactor(String code) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _securityDs.verify2FA(code);
      await loadSecurity();
      state = state.copyWith(isProcessing: false, clearSetup: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Invalid verification code.',
          fallbackTl: 'Hindi valid ang verification code.',
        ),
      );
      return false;
    }
  }

  Future<bool> disableTwoFactor(String code) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _securityDs.disable2FA(code);
      await loadSecurity();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not disable 2FA.',
          fallbackTl: 'Hindi ma-disable ang 2FA.',
        ),
      );
      return false;
    }
  }

  Future<bool> toggleBiometricUnlock(bool enabled) async {
    if (state.isProcessing) return false;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final authenticated = await _biometrics.authenticate(enrolling: enabled);
      if (!mounted) return false;
      if (!authenticated) {
        state = state.copyWith(
          error: 'Authentication cancelled. The setting was not changed.',
        );
        return false;
      }
      await _prefs.setBiometricUnlockEnabled(enabled);
      if (!mounted) return false;
      state = state.copyWith(localBiometricEnabled: enabled);
      return true;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          error: BiometricUnlockService.errorMessage(error),
        );
      }
      return false;
    } finally {
      if (mounted) state = state.copyWith(isProcessing: false);
    }
  }
}

final securitySettingsProvider =
    StateNotifierProvider.autoDispose<
      SecuritySettingsNotifier,
      SecuritySettingsState
    >(
      (ref) =>
          SecuritySettingsNotifier(ref.read(biometricUnlockServiceProvider)),
    );
