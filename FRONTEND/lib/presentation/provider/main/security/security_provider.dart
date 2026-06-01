import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_preferences_service.dart';
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
      twoFactorSetup:
          clearSetup ? null : (twoFactorSetup ?? this.twoFactorSetup),
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
  SecuritySettingsNotifier()
      : super(const SecuritySettingsState(isLoading: true)) {
    loadSecurity();
  }

  final SecurityRemoteDataSource _securityDs =
      getIt<SecurityRemoteDataSource>();
  final AppPreferencesService _prefs = getIt<AppPreferencesService>();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> loadSecurity() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      final dashboard = await _securityDs.getSecurityDashboard();
      final biometrics = await _securityDs.listBiometrics();
      final logs = await _securityDs.getAuditLogs(perPage: 10);

      state = state.copyWith(
        dashboard: dashboard,
        registeredBiometrics: biometrics,
        auditLogs: logs,
        localBiometricEnabled: _prefs.biometricUnlockEnabled,
        deviceSupportsBiometrics: canCheck && supported,
        isLoading: false,
      );
    } catch (e) {
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

  Future<bool> toggleBiometricUnlock(bool enabled) async {
    if (enabled) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric unlock for LEZGO',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!authenticated) return false;
      } catch (e) {
        state = state.copyWith(
          error: ApiErrorMapper.message(
            e,
            fallbackEn: 'Biometric authentication failed.',
            fallbackTl: 'Hindi nag-authenticate ang biometric.',
          ),
        );
        return false;
      }
    }

    await _prefs.setBiometricUnlockEnabled(enabled);
    state = state.copyWith(localBiometricEnabled: enabled);
    return true;
  }
}

final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>(
  (ref) => SecuritySettingsNotifier(),
);
