import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class RiderUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int? driverProfileId;
  final int? partnerId;

  RiderUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.driverProfileId,
    this.partnerId,
  });

  bool get isDriver => role == 'driver';
  bool get isMerchant => role == 'merchant' || role == 'partner';

  factory RiderUser.fromJson(Map<String, dynamic> json) {
    final dp = json['driver_profile'];
    return RiderUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'driver',
      driverProfileId: dp is Map ? dp['id'] as int? : null,
      partnerId: json['partner_id'] as int?,
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
  RiderAuthNotifier() : super(RiderAuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) {
      print('🔐 No token found, skipping auto-login');
      return;
    }

    print('🔐 Auto-login: Token found, calling /me endpoint');
    state = state.copyWith(isLoading: true);
    try {
      final data = await ApiService.getMe();
      print('🔐 Auto-login response: $data');
      
      final userData = data['data'] ?? data['user'] ?? data;
      print('🔐 Auto-login user data: $userData');
      
      final user = RiderUser.fromJson(userData as Map<String, dynamic>);
      print('🔐 Auto-login parsed user - ID: ${user.id}, Role: ${user.role}, Partner ID: ${user.partnerId}');
      
      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );
      
      print('✅ Auto-login successful - Partner ID in state: ${state.user?.partnerId}');
    } catch (e) {
      print('❌ Auto-login failed: $e');
      await ApiService.clearToken();
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    print('🔐🔐🔐 LOGIN METHOD CALLED 🔐🔐🔐');
    print('🔐 Email: $email');
    print('🔐 Password length: ${password.length}');
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      print('🔐 Calling ApiService.login...');
      final data = await ApiService.login(email, password);
      print('🔐 Login response received: $data');
      
      final token = data['token'] as String?;
      final userData = data['user'] ?? data['data'];
      
      print('🔐 Token extracted: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
      print('🔐 User data extracted: $userData');

      if (token == null || userData == null) {
        print('❌ Token or user data is null');
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
        return false;
      }

      final user = RiderUser.fromJson(userData as Map<String, dynamic>);
      
      print('🔐 Parsed user - ID: ${user.id}, Role: ${user.role}, Partner ID: ${user.partnerId}');

      // Allow both drivers and merchants/partners
      if (!user.isDriver && !user.isMerchant) {
        print('❌ User role not authorized: ${user.role}');
        state = state.copyWith(
          isLoading: false,
          error: 'This account is not authorized for this app.',
        );
        return false;
      }

      print('🔐 Calling ApiService.saveToken...');
      await ApiService.saveToken(token);
      print('🔐 Token saved, verifying...');
      
      // Verify token was saved
      final savedToken = await ApiService.getToken();
      print('🔐 Token verification: ${savedToken != null ? "SUCCESS" : "FAILED"}');
      
      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );
      
      print('✅✅✅ LOGIN SUCCESSFUL ✅✅✅');
      print('✅ Partner ID in state: ${state.user?.partnerId}');
      return true;
    } catch (e) {
      print('❌❌❌ LOGIN ERROR ❌❌❌');
      print('❌ Error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await ApiService.logout();
    state = RiderAuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final riderAuthProvider =
    StateNotifierProvider<RiderAuthNotifier, RiderAuthState>(
        (ref) => RiderAuthNotifier());
