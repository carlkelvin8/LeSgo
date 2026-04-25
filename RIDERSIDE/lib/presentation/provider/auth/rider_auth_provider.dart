import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class RiderUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int? driverProfileId;

  RiderUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.driverProfileId,
  });

  bool get isDriver => role == 'driver';

  factory RiderUser.fromJson(Map<String, dynamic> json) {
    final dp = json['driver_profile'];
    return RiderUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'driver',
      driverProfileId: dp is Map ? dp['id'] as int? : null,
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
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final data = await ApiService.getMe();
      final userData = data['data'] ?? data['user'] ?? data;
      final user = RiderUser.fromJson(userData as Map<String, dynamic>);
      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );
    } catch (_) {
      await ApiService.clearToken();
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await ApiService.login(email, password);
      final token = data['token'] as String?;
      final userData = data['user'] ?? data['data'];

      if (token == null || userData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
        return false;
      }

      final user = RiderUser.fromJson(userData as Map<String, dynamic>);

      if (!user.isDriver) {
        state = state.copyWith(
          isLoading: false,
          error: 'This account is not a driver account.',
        );
        return false;
      }

      await ApiService.saveToken(token);
      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
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
