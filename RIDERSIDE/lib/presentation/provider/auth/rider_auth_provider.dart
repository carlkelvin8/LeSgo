import 'registration_fee_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_refresh_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/remember_me_service.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/media_url_utils.dart';
import '../../../domain/entities/auth/registration_fee_status.dart';
import '../main/riderside/rider_duty_provider.dart';
import '../main/riderside/rider_location_provider.dart';
import '../main/riderside/rider_orders_provider.dart';

enum AuthViewTarget { rider, merchant }

class RiderUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int? driverProfileId;
  final int? partnerId;
  final String? profilePhotoUrl;
  final String? packageTier;
  final double? commissionRate;
  final RegistrationFeeStatus? registrationFee;
  final PartnerStaffInfo? staffInfo;

  RiderUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.driverProfileId,
    this.partnerId,
    this.profilePhotoUrl,
    this.packageTier,
    this.commissionRate,
    this.registrationFee,
    this.staffInfo,
  });

  bool get isDriver => role == 'driver';
  bool get isMerchant =>
      role == 'merchant' || role == 'partner' || role == 'partner_admin';
  bool get isStaff => role == 'partner_staff';

  /// Rider/Merchant accounts are restricted until the registration fee is paid
  /// (or waived by an admin) AND the application is approved.
  bool get isRegistrationRestricted =>
      ((isMerchant || isDriver || isStaff) && registrationFee == null) ||
      (registrationFee != null &&
          (!registrationFee!.isActive || !registrationFee!.shouldBeActive));

  RiderUser copyWith({
    int? driverProfileId,
    int? partnerId,
    String? profilePhotoUrl,
    String? packageTier,
    double? commissionRate,
    RegistrationFeeStatus? registrationFee,
    bool clearRegistrationFee = false,
    PartnerStaffInfo? staffInfo,
  }) {
    return RiderUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      driverProfileId: driverProfileId ?? this.driverProfileId,
      partnerId: partnerId ?? this.partnerId,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      packageTier: packageTier ?? this.packageTier,
      commissionRate: commissionRate ?? this.commissionRate,
      registrationFee: clearRegistrationFee
          ? null
          : (registrationFee ?? this.registrationFee),
      staffInfo: staffInfo ?? this.staffInfo,
    );
  }

  static String? resolveProfilePhotoUrl(Map<String, dynamic> json) {
    final photoUrl = json['profile_photo_url']?.toString();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return MediaUrlUtils.resolve(photoUrl) ?? photoUrl;
    }
    final picturePath = json['profile_picture']?.toString();
    if (picturePath != null && picturePath.isNotEmpty) {
      return MediaUrlUtils.resolve(picturePath);
    }
    return null;
  }

  factory RiderUser.fromJson(Map<String, dynamic> json) {
    final dp = json['driver_profile'] ?? json['driverProfile'];
    String? packageTier;
    double? commissionRate;
    if (dp is Map) {
      packageTier = dp['package_tier']?.toString();
      final rawRate = dp['commission_rate'];
      if (rawRate is num) {
        commissionRate = rawRate.toDouble();
      } else if (rawRate is String) {
        commissionRate = double.tryParse(rawRate);
      }
    }

return RiderUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone_number']?.toString(),
      role: json['role']?.toString() ?? 'driver',
      driverProfileId: parseDriverProfileId(json),
      partnerId: parsePartnerId(json),
      profilePhotoUrl: resolveProfilePhotoUrl(json),
      packageTier: packageTier,
      commissionRate: commissionRate,
      registrationFee: RegistrationFeeStatus.fromJson(json['registration_fee']),
      staffInfo: PartnerStaffInfo.fromJson(json),
    );
  }

  static int? parseDriverProfileId(Map<String, dynamic> json) {
    final profile = json['driver_profile'] ?? json['driverProfile'];
    if (profile is Map) {
      final id = _parseInt(profile['id']);
      if (id != null) return id;
    }

    return _parseInt(
      json['driver_profile_id'] ??
          json['driverProfileId'] ??
          json['driver_id'],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? parsePartnerId(Map<String, dynamic> json) {
    final direct = json['partner_id'];
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct);

    final partner = json['partner'];
    if (partner is Map) {
      final id = partner['id'];
      if (id is num) return id.toInt();
      if (id is String) return int.tryParse(id);
    }
    return null;
  }
}

class PartnerStaffInfo {
  final int id;
  final String role;
  final List<String>? permissions;
  final bool isActive;
  final String? partnerName;

  PartnerStaffInfo({
    required this.id,
    required this.role,
    this.permissions,
    required this.isActive,
    this.partnerName,
  });

  bool get isAdmin => role == 'admin';
  bool get isCook => role == 'cook';
  bool get isCashier => role == 'cashier';

  static PartnerStaffInfo? fromJson(Map<String, dynamic> json) {
    final staff = json['staff'];
    if (staff is! Map) return null;
    return PartnerStaffInfo(
      id: staff['id'] as int? ?? 0,
      role: staff['role'] as String? ?? 'cashier',
      permissions: (staff['permissions'] as List?)?.cast<String>(),
      isActive: staff['is_active'] as bool? ?? true,
      partnerName: staff['partner_name'] as String?,
    );
  }
}

class RiderAuthState {
  final RiderUser? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  RiderAuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  RiderAuthState copyWith({
    RiderUser? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    bool clearError = false,
  }) {
    return RiderAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderAuthNotifier extends StateNotifier<RiderAuthState> {
  RiderAuthNotifier() : super(RiderAuthState());

  /// Update the session only with status returned by the registration-fee API.
  void applyRegistrationStatus(RegistrationFeeStatus status) {
    final user = state.user;
    if (!state.isLoggedIn || user == null) return;
    state = state.copyWith(user: user.copyWith(registrationFee: status));
  }

  Future<RiderUser> _ensureMerchantPartnerId(RiderUser user) async {
    if (!user.isMerchant || user.partnerId != null) return user;

    try {
      final data = await ApiService.getMe();
      final userData = data['data'] ?? data['user'] ?? data;
      if (userData is! Map<String, dynamic>) return user;

      final partnerId = RiderUser.parsePartnerId(userData);
      if (partnerId != null) return user.copyWith(partnerId: partnerId);
    } catch (e) {
      AppLogger.warn('Could not resolve merchant partner_id: $e');
    }
    return user;
  }

  /// Returns the authenticated driver's profile ID, refreshing stale login
  /// data and falling back to the driver listing used by older API releases.
  Future<int?> ensureDriverProfileId() async {
    final currentUser = state.user;
    if (currentUser == null || !currentUser.isDriver) return null;
    if (currentUser.driverProfileId != null) {
      return currentUser.driverProfileId;
    }

    try {
      final data = await ApiService.getMe();
      final rawUser = data['user'] ?? data['data'] ?? data;
      if (rawUser is Map) {
        final refreshed = RiderUser.fromJson(
          Map<String, dynamic>.from(rawUser),
        );
        if (refreshed.id == currentUser.id && refreshed.isDriver) {
          state = state.copyWith(user: refreshed);
          if (refreshed.driverProfileId != null) {
            return refreshed.driverProfileId;
          }
        }
      }
    } catch (e) {
      AppLogger.warn('Could not refresh driver profile from auth/me: $e');
    }

    try {
      final profile = await ApiService.getMyDriverProfile(currentUser.id);
      final profileId = RiderUser._parseInt(profile?['id']);
      if (profileId != null) {
        final latestUser = state.user ?? currentUser;
        state = state.copyWith(
          user: latestUser.copyWith(driverProfileId: profileId),
        );
        return profileId;
      }
    } catch (e) {
      AppLogger.warn('Could not resolve driver profile from drivers API: $e');
    }

    return null;
  }

  Future<String?> _resolveAccessToken() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) return token;

    if (!RememberMeService.isSessionValid()) return null;

    return TokenRefreshService.instance.refreshAccessToken();
  }

  Future<bool> restoreSession() async {
    if (!RememberMeService.isSessionValid()) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (await _restoreWithStoredTokens()) {
        return true;
      }

      // Don't clear refresh token on failure — preserve it for future attempts
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      AppLogger.error('Restore session failed', e);
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> _restoreWithStoredTokens() async {
    final token = await _resolveAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final data = await ApiService.getMe();
      final userData = data['data'] ?? data['user'] ?? data;
      if (userData is! Map<String, dynamic>) return false;

      var user = RiderUser.fromJson(userData);
      user = await _ensureMerchantPartnerId(user);

      await SecureStorageService.saveUserId(user.id);

      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );

      await RememberMeService.refreshExpiry();
      await PushNotificationService.registerWithBackend();
      return true;
    } catch (e) {
      AppLogger.warn('Token restore failed: $e');
      return false;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    required bool rememberMe,
    required String accountType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    return _loginInternal(
      email,
      password,
      rememberMe: rememberMe,
      accountType: accountType,
    );
  }

  Future<bool> _loginInternal(
    String email,
    String password, {
    required bool rememberMe,
    required String accountType,
  }) async {
    try {
      final data = await ApiService.login(email, password);

      final nested = data['data'];
      final payload = nested is Map<String, dynamic> ? nested : data;
      final token = payload['token'] as String? ?? data['token'] as String?;
      final refreshToken =
          payload['refresh_token'] as String? ?? data['refresh_token'] as String?;
      final userData = payload['user'] ?? data['user'];
      final expiresIn =
          payload['expires_in'] as int? ?? data['expires_in'] as int? ?? 3600;

      if (token == null || userData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
        return false;
      }

      var user = RiderUser.fromJson(userData as Map<String, dynamic>);
      user = await _ensureMerchantPartnerId(user);

      if (!user.isDriver && !user.isMerchant && !user.isStaff) {
        state = state.copyWith(
          isLoading: false,
          error: 'This account is not authorized for this app.',
        );
        return false;
      }

      await ApiService.saveToken(
        token,
        expiresIn: expiresIn,
        refreshToken: refreshToken,
        userId: user.id,
      );

      await RememberMeService.savePreference(
        enabled: rememberMe,
        email: email,
        accountType: accountType,
      );

      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );

      await PushNotificationService.registerWithBackend();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _loginErrorMessage(e),
      );
      return false;
    }
  }

  String _loginErrorMessage(Object e) {
    return ApiErrorMapper.message(
      e,
      fallbackEn: 'Cannot sign in right now. Please try again.',
      fallbackTl: 'Hindi makapag-sign in ngayon. Subukan muli.',
    );
  }

  /// Clears local session immediately and returns the login view to show next.
  Future<AuthViewTarget> logout(WidgetRef ref) async {
    ref.invalidate(registrationFeeProvider);
    final user = state.user;
    final target = (user?.isMerchant == true || user?.isStaff == true)
        ? AuthViewTarget.merchant
        : AuthViewTarget.rider;

    state = state.copyWith(isLoading: true);

    // Must run before the token is cleared: syncs is_available=false and stops
    // the foreground location service so tracking cannot outlive the session.
    await _endDutyOnLogout(ref);

    try {
      ref.read(riderOrdersProvider.notifier).reset();
    } catch (_) {}

    try {
      await RememberMeService.clearSession();
      await ApiService.logout();
    } catch (e) {
      AppLogger.warn('Logout cleanup failed: $e');
      await ApiService.clearToken();
    } finally {
      state = RiderAuthState();
    }

    return target;
  }

  /// Best-effort teardown of duty side effects so a logged-out device stops
  /// reporting availability and keeps running the location foreground service.
  Future<void> _endDutyOnLogout(WidgetRef ref) async {
    try {
      if (ref.read(riderDutyProvider)) {
        final error = await ref
            .read(riderDutyProvider.notifier)
            .setOnDuty(false)
            .timeout(const Duration(seconds: 5));
        if (error != null) {
          AppLogger.warn('Logout: off-duty sync failed: $error');
        }
      }
    } catch (e) {
      AppLogger.warn('Logout: off-duty sync failed: $e');
    }

    try {
      await ref.read(riderLocationProvider.notifier).stopTracking();
    } catch (e) {
      AppLogger.warn('Logout: stopping location tracking failed: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void updatePackageTier({
    required String packageTier,
    double? commissionRate,
  }) {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(
      user: user.copyWith(
        packageTier: packageTier,
        commissionRate: commissionRate,
      ),
    );
  }

  Future<bool> establishSession({
    required String token,
    required Map<String, dynamic> userData,
    int expiresIn = 3600,
    String? refreshToken,
  }) async {
    try {
      var user = RiderUser.fromJson(userData);
      user = await _ensureMerchantPartnerId(user);

      if (!user.isDriver && !user.isMerchant && !user.isStaff) {
        state = state.copyWith(
          isLoading: false,
          error: 'This account is not authorized for this app.',
        );
        return false;
      }

      await ApiService.saveToken(
        token,
        expiresIn: expiresIn,
        refreshToken: refreshToken,
        userId: user.id,
      );

      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
        clearError: true,
      );

      await PushNotificationService.registerWithBackend();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }
}

final riderAuthProvider =
    StateNotifierProvider<RiderAuthNotifier, RiderAuthState>(
        (ref) => RiderAuthNotifier());
