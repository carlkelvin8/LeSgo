import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/token_refresh_service.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/media_url_utils.dart';
import '../../auth/rider_auth_provider.dart';

class RiderProfileState {
  final String name;
  final String contact;
  final String address;
  final String vehicle;
  final String plateNumber;
  final String referralCode;
  final String? profilePictureUrl;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const RiderProfileState({
    this.name = '',
    this.contact = '',
    this.address = '',
    this.vehicle = '',
    this.plateNumber = '',
    this.referralCode = '',
    this.profilePictureUrl,
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  RiderProfileState copyWith({
    String? name,
    String? contact,
    String? address,
    String? vehicle,
    String? plateNumber,
    String? referralCode,
    String? profilePictureUrl,
    bool? isLoading,
    bool? isUploading,
    String? error,
    bool clearError = false,
  }) {
    return RiderProfileState(
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      vehicle: vehicle ?? this.vehicle,
      plateNumber: plateNumber ?? this.plateNumber,
      referralCode: referralCode ?? this.referralCode,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

String? _resolveProfilePictureUrl(Map<String, dynamic> user) {
  final photoUrl = user['profile_photo_url']?.toString();
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return MediaUrlUtils.resolve(photoUrl) ?? photoUrl;
  }

  final picturePath = user['profile_picture']?.toString();
  if (picturePath != null && picturePath.isNotEmpty) {
    return MediaUrlUtils.resolve(picturePath);
  }

  return null;
}

class RiderProfileNotifier extends StateNotifier<RiderProfileState> {
  RiderProfileNotifier(this._ref) : super(const RiderProfileState());

  final Ref _ref;

  Future<Map<String, dynamic>> _fetchMe({bool allowRefresh = true}) async {
    try {
      return await ApiService.getMe();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (!allowRefresh || (code != 401 && code != 500)) rethrow;

      await TokenRefreshService.instance.refreshAccessToken();
      return await ApiService.getMe();
    }
  }

  void _applyAuthFallback({String? error}) {
    final authUser = _ref.read(riderAuthProvider).user;
    if (authUser == null) return;

    state = state.copyWith(
      name: authUser.name,
      contact: authUser.phone ?? '',
      profilePictureUrl:
          state.profilePictureUrl ?? authUser.profilePhotoUrl,
      isLoading: false,
      error: error,
    );
  }

  String _readPlateNumber(Map<String, dynamic>? driverProfile) {
    if (driverProfile == null) return '';
    final plate = driverProfile['plate_number']?.toString().trim();
    if (plate != null && plate.isNotEmpty) return plate;
    final legacy = driverProfile['vehicle_plate']?.toString().trim();
    return legacy ?? '';
  }

  Future<String> _resolveReferralCode(Map<String, dynamic> user) async {
    final direct = user['referral_code']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    try {
      final dashboard = await ApiService.getReferralDashboard();
      final data = dashboard['data'];
      if (data is Map) {
        final code = data['referral_code']?.toString().trim();
        if (code != null && code.isNotEmpty) return code;
      }
      final topLevel = dashboard['referral_code']?.toString().trim();
      if (topLevel != null && topLevel.isNotEmpty) return topLevel;
    } catch (_) {}

    return '';
  }

  Future<void> loadProfile({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final data = await _fetchMe();
      final u = (data['user'] ?? data['data'] ?? data) as Map<String, dynamic>;

      final dp = u['driver_profile'] as Map<String, dynamic>?;
      final profilePicUrl = _resolveProfilePictureUrl(u);
      final referralCode = await _resolveReferralCode(u);

      state = state.copyWith(
        name: u['name'] as String? ?? '',
        contact: u['phone_number'] as String? ?? '',
        address: u['address_line1'] as String? ?? '',
        vehicle: dp != null ? (dp['vehicle_type'] as String? ?? '') : '',
        plateNumber: _readPlateNumber(dp),
        referralCode: referralCode,
        profilePictureUrl: profilePicUrl,
        isLoading: false,
      );
    } catch (e) {
      final authUser = _ref.read(riderAuthProvider).user;
      if (authUser != null) {
        _applyAuthFallback(
          error:
              'Could not refresh profile details. Tap Retry below or reopen this tab.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: ApiService.extractError(e),
        );
      }
    }
  }

  Future<bool> uploadProfilePicture(XFile imageFile) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      await ApiService.uploadProfilePictureFromXFile(imageFile);
      await loadProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }
}

final riderProfileProvider =
    StateNotifierProvider<RiderProfileNotifier, RiderProfileState>(
      (ref) => RiderProfileNotifier(ref),
    );
