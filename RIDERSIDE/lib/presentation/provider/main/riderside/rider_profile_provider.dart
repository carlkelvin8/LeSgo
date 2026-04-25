import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/services/api_service.dart';

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

class RiderProfileNotifier extends StateNotifier<RiderProfileState> {
  RiderProfileNotifier() : super(const RiderProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await ApiService.getMe();
      // GET /v1/auth/me returns { success, user: {...} }
      final u = (data['user'] ?? data['data'] ?? data) as Map<String, dynamic>;

      // Driver profile may be nested
      final dp = u['driver_profile'] as Map<String, dynamic>?;

      // Build profile picture URL if exists
      String? profilePicUrl;
      if (u['profile_picture'] != null && u['profile_picture'].toString().isNotEmpty) {
        final picPath = u['profile_picture'].toString();
        if (picPath.startsWith('http://') || picPath.startsWith('https://')) {
          profilePicUrl = picPath;
        } else {
          profilePicUrl = 'http://127.0.0.1:8000/serve-image.php?path=$picPath';
        }
      }

      state = state.copyWith(
        name: u['name'] as String? ?? '',
        contact: u['phone_number'] as String? ?? '',
        address: u['address_line1'] as String? ?? '',
        vehicle: dp != null ? (dp['vehicle_type'] as String? ?? '') : '',
        plateNumber: dp != null ? (dp['plate_number'] as String? ?? '') : '',
        referralCode: u['referral_code'] as String? ?? '',
        profilePictureUrl: profilePicUrl,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> uploadProfilePicture(XFile imageFile) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      print('📤 Uploading profile picture: ${imageFile.name}');
      
      // Upload using the XFile directly
      final response = await ApiService.uploadProfilePictureFromXFile(imageFile);
      
      print('✅ Profile picture uploaded successfully');
      
      // Reload profile to get the new picture URL
      await loadProfile();
      
      return true;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
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
      (ref) => RiderProfileNotifier(),
    );
