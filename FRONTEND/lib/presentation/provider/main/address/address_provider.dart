import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/address_remote_datasource.dart';
import '../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../data/data_source/dto/address/create_address_request_dto.dart';
import '../../../../data/data_source/dto/address/update_address_request_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_utils.dart';

class AddressState {
  final List<AddressDto> addresses;
  final AddressDto? selectedAddress;
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final String? error;

  AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
  });

  AddressState copyWith({
    List<AddressDto>? addresses,
    AddressDto? selectedAddress,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
    );
  }

  AddressDto? get defaultAddress {
    try {
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}

class AddressNotifier extends StateNotifier<AddressState> {
  AddressNotifier() : super(AddressState());

  /// Load all addresses for the current user
  Future<void> loadAddresses(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final addressDataSource = getIt<AddressRemoteDataSource>();
      final response = await addressDataSource.getAddresses();

      if (response.success) {
        print('🔍 AddressProvider: Loaded ${response.data.length} addresses');
        for (var addr in response.data) {
          print('  - ${addr.label}: ${addr.addressLine1} (${addr.latitude}, ${addr.longitude})');
        }
        state = state.copyWith(
          addresses: response.data,
          isLoading: false,
        );

        // Auto-select default address if none selected
        if (state.selectedAddress == null && state.defaultAddress != null) {
          state = state.copyWith(selectedAddress: state.defaultAddress);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load addresses',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new address
  Future<bool> createAddress({
    required int userId,
    required String label,
    required String contactName,
    required String contactPhone,
    required String addressLine1,
    String? addressLine2,
    String? country,
    required double latitude,
    required double longitude,
    bool isDefault = false,
    BuildContext? context,
  }) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      print('🔵 AddressProvider: Creating address...');
      print('🔵 AddressProvider: - userId: $userId');
      print('🔵 AddressProvider: - label: $label');
      print('🔵 AddressProvider: - addressLine1: $addressLine1');
      print('🔵 AddressProvider: - addressLine2: $addressLine2');
      print('🔵 AddressProvider: - latitude: $latitude');
      print('🔵 AddressProvider: - longitude: $longitude');
      
      final addressDataSource = getIt<AddressRemoteDataSource>();
      final request = CreateAddressRequestDto(
        label: label,
        contactName: contactName,
        contactPhone: contactPhone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        country: country ?? 'Philippines',
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      print('🔵 AddressProvider: Calling API...');
      final response = await addressDataSource.createAddress(request);
      print('🔵 AddressProvider: Response - success: ${response.success}, error: ${response.error}');

      if (response.success && response.data != null) {
        print('🔵 AddressProvider: Address created successfully');
        // Reload addresses to get updated list
        await loadAddresses(userId);

        state = state.copyWith(isCreating: false);

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Address added successfully');
        }
        return true;
      } else {
        print('🔴 AddressProvider: Failed - ${response.error}');
        state = state.copyWith(
          isCreating: false,
          error: response.error ?? 'Failed to create address',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to create address',
          );
        }
        return false;
      }
    } catch (e) {
      print('🔴 AddressProvider: Exception - $e');
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error creating address: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Update an existing address
  Future<bool> updateAddress({
    required int userId,
    required int addressId,
    String? label,
    String? contactName,
    String? contactPhone,
    String? addressLine1,
    String? addressLine2,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
    BuildContext? context,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final addressDataSource = getIt<AddressRemoteDataSource>();
      final request = UpdateAddressRequestDto(
        label: label,
        contactName: contactName,
        contactPhone: contactPhone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        country: country,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      final response = await addressDataSource.updateAddress(addressId, request);

      if (response.success && response.data != null) {
        // Reload addresses to get updated list
        await loadAddresses(userId);

        state = state.copyWith(isUpdating: false);

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Address updated successfully');
        }
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: response.error ?? 'Failed to update address',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to update address',
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error updating address: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress({
    required int userId,
    required int addressId,
    BuildContext? context,
  }) async {
    state = state.copyWith(isDeleting: true, error: null);

    try {
      final addressDataSource = getIt<AddressRemoteDataSource>();
      final response = await addressDataSource.deleteAddress(addressId);

      if (response.success) {
        // Reload addresses to get updated list
        await loadAddresses(userId);

        state = state.copyWith(isDeleting: false);

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Address deleted successfully');
        }
        return true;
      } else {
        state = state.copyWith(
          isDeleting: false,
          error: response.error ?? 'Failed to delete address',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to delete address',
          );
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error deleting address: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Select an address
  void selectAddress(AddressDto address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Clear selected address
  void clearSelectedAddress() {
    state = state.copyWith(selectedAddress: null);
  }

  /// Set an address as default
  Future<bool> setAsDefault({
    required int userId,
    required int addressId,
    BuildContext? context,
  }) async {
    return await updateAddress(
      userId: userId,
      addressId: addressId,
      isDefault: true,
      context: context,
    );
  }
}

final addressProvider =
    StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier();
});
