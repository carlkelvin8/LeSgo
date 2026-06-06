import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/token_refresh_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/remember_me_service.dart';
import '../../../core/utils/media_url_utils.dart';
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
  });

  bool get isDriver => role == 'driver';
  bool get isMerchant =>
      role == 'merchant' || role == 'partner' || role == 'partner_admin';

  RiderUser copyWith({int? partnerId, String? profilePhotoUrl, String? packageTier, double? commissionRate}) {
    return RiderUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      driverProfileId: driverProfileId,
      partnerId: partnerId ?? this.partnerId,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      packageTier: packageTier ?? this.packageTier,
      commissionRate: commissionRate ?? this.commissionRate,
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
    final dp = json['driver_profile'];
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
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'driver',
      driverProfileId: dp is Map ? dp['id'] as int? : null,
      partnerId: parsePartnerId(json),
      profilePhotoUrl: resolveProfilePhotoUrl(json),
      packageTier: packageTier,
      commissionRate: commissionRate,
    );
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

  Future<RiderUser> _ensureMerchantPartnerId(RiderUser user) async {
    if (!user.isMerchant || user.partnerId != null) return user;

    try {
      final data = await ApiService.getMe();
      final userData = data['data'] ?? data['user'] ?? data;
      if (userData is! Map<String, dynamic>) return user;

      final partnerId = RiderUser.parsePartnerId(userData);
      if (partnerId != null) return user.copyWith(partnerId: partnerId);
    } catch (e) {
      print('⚠️ Could not resolve merchant partner_id: $e');
    }
    return user;
  }

  Future<String?> _resolveAccessToken() async {
    var token = await ApiService.getToken();
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

      await ApiService.clearToken();

      if (RememberMeService.hasSavedCredentials) {
        final email = RememberMeService.savedEmail!;
        final password = RememberMeService.savedPassword!;
        final accountType = RememberMeService.savedAccountType ?? 'rider';

        final success = await _loginInternal(
          email,
          password,
          rememberMe: true,
          accountType: accountType,
        );
        if (!success) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        final user = state.user;
        if (accountType == 'merchant' && user != null && !user.isMerchant) {
          await ApiService.clearToken();
          state = state.copyWith(isLoading: false, isLoggedIn: false, user: null);
          return false;
        }
        if (accountType == 'rider' && user != null && !user.isDriver) {
          await ApiService.clearToken();
          state = state.copyWith(isLoading: false, isLoggedIn: false, user: null);
          return false;
        }

        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print('❌ Restore session failed: $e');
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
      print('⚠️ Token restore failed, will try saved credentials: $e');
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

      if (!user.isDriver && !user.isMerchant) {
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
        password: password,
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
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  /// Clears local session immediately and returns the login view to show next.
  Future<AuthViewTarget> logout(WidgetRef ref) async {
    final target = state.user?.isMerchant == true
        ? AuthViewTarget.merchant
        : AuthViewTarget.rider;

    state = state.copyWith(isLoading: true);

    try {
      ref.read(riderOrdersProvider.notifier).reset();
    } catch (_) {}

    try {
      await RememberMeService.clearSession();
      await ApiService.logout();
    } catch (e) {
      print('⚠️ Logout cleanup failed: $e');
      await ApiService.clearToken();
    } finally {
      state = RiderAuthState();
    }

    return target;
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final riderAuthProvider =
    StateNotifierProvider<RiderAuthNotifier, RiderAuthState>(
        (ref) => RiderAuthNotifier());
