import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../domain/entities/auth/register/register_request.dart';
import '../../../../domain/entities/user.dart';

const _unset = Object();

class RegisterState {
  final RegisterRequest data;
  final bool isLoading;
  final String? error;
  final User? registeredUser;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final String? locationName;
  final bool isTermsAccepted;
  final bool otpSent;

  RegisterState({
    RegisterRequest? data,
    this.isLoading = false,
    this.error,
    this.registeredUser,
    this.currentLocation,
    this.selectedLocation,
    this.locationName,
    this.isTermsAccepted = false,
    this.otpSent = false,
  }) : data = data ?? RegisterRequest();

  RegisterState copyWith({
    RegisterRequest? data,
    bool? isLoading,
    Object? error = _unset,
    Object? registeredUser = _unset,
    LatLng? currentLocation,
    LatLng? selectedLocation,
    String? locationName,
    bool? isTermsAccepted,
    bool? otpSent,
  }) {
    return RegisterState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      registeredUser: identical(registeredUser, _unset)
          ? this.registeredUser
          : registeredUser as User?,
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      locationName: locationName ?? this.locationName,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      otpSent: otpSent ?? this.otpSent,
    );
  }

  bool get isComplete => registeredUser != null;
}
