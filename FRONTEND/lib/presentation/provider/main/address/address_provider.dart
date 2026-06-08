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

  AddressDto? get defaultAddress => AddressState.resolveDefaultAddress(addresses);

  /// Preferred delivery address: explicit selection, then default.
  AddressDto? get deliveryAddress => selectedAddress ?? defaultAddress;

  /// Human-readable label for the active delivery / current location.
  String get deliveryAddressLabel {
    final addr = deliveryAddress;
    if (addr == null || addr.addressLine1.isEmpty) {
      return 'Set your location';
    }
    return addr.addressLine1;
  }

  static AddressDto? resolveDefaultAddress(List<AddressDto> addresses) {
    if (addresses.isEmpty) return null;

    final sorted = List<AddressDto>.from(addresses)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final addr in sorted) {
      if (addr.isDefault) return addr;
    }

    for (final addr in sorted) {
      if (addr.label.toLowerCase() == 'my location') return addr;
    }

    return sorted.first;
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
        final defaultAddr =
            AddressState.resolveDefaultAddress(response.data);
        state = state.copyWith(
          addresses: response.data,
          isLoading: false,
          selectedAddress: defaultAddr,
        );
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

  AddressDto? _resolveLocationAddress(double latitude, double longitude) {
    const epsilon = 0.0005;
    final matches = state.addresses.where((addr) {
      return (addr.latitude - latitude).abs() < epsilon &&
          (addr.longitude - longitude).abs() < epsilon;
    }).toList();

    if (matches.isNotEmpty) {
      matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return matches.first;
    }

    final defaultAddr = state.defaultAddress;
    if (defaultAddr != null) return defaultAddr;

    for (final addr in state.addresses) {
      if (addr.label.toLowerCase() == 'my location') {
        return addr;
      }
    }

    return null;
  }

  static String inferCountry({
    required double latitude,
    required double longitude,
    required String cityProvince,
  }) {
    final inPhilippines =
        latitude >= 4 && latitude <= 21 && longitude >= 116 && longitude <= 127;
    if (inPhilippines) return 'Philippines';

    final lower = cityProvince.toLowerCase();
    if (lower.contains('philippines')) return 'Philippines';
    if (lower.contains('united states') ||
        lower.contains('usa') ||
        RegExp(
          r'\b(california|texas|new york|florida|washington)\b',
        ).hasMatch(lower)) {
      return 'United States';
    }

    return 'Philippines';
  }

  /// Update the user's saved default location, or create one if none exists.
  Future<bool> upsertDefaultLocation({
    required int userId,
    required String label,
    required String contactName,
    required String contactPhone,
    required String addressLine1,
    String? addressLine2,
    String? city,
    String? region,
    String? postalCode,
    String? country,
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    await loadAddresses(userId);

    final resolvedPhone = contactPhone.trim().isNotEmpty
        ? contactPhone.trim()
        : '09000000000';
    final resolvedCountry = country ??
        inferCountry(
          latitude: latitude,
          longitude: longitude,
          cityProvince: '$city $region',
        );

    final existing = _resolveLocationAddress(latitude, longitude);

    if (existing != null) {
      print('🔵 AddressProvider: Updating existing address id=${existing.id}');
      return updateAddress(
        userId: userId,
        addressId: existing.id,
        label: label,
        contactName: contactName,
        contactPhone: resolvedPhone,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        region: region,
        postalCode: postalCode,
        country: resolvedCountry,
        latitude: latitude,
        longitude: longitude,
        isDefault: true,
        context: context,
      );
    }

    print('🔵 AddressProvider: Creating new default location address');
    return createAddress(
      userId: userId,
      label: label,
      contactName: contactName,
      contactPhone: resolvedPhone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      region: region,
      postalCode: postalCode,
      country: resolvedCountry,
      latitude: latitude,
      longitude: longitude,
      isDefault: true,
      context: context,
    );
  }

  /// Create a new address
  Future<bool> createAddress({
    required int userId,
    required String label,
    required String contactName,
    required String contactPhone,
    required String addressLine1,
    String? addressLine2,
    String? city,
    String? region,
    String? postalCode,
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
        city: city,
        region: region,
        postalCode: postalCode,
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
    String? city,
    String? region,
    String? postalCode,
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
        city: city,
        region: region,
        postalCode: postalCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      final response = await addressDataSource.updateAddress(addressId, request);
      print(
        '🔵 AddressProvider: Update response - success: ${response.success}, error: ${response.error}',
      );

      if (response.success && response.data != null) {
        // Reload addresses to get updated list
        await loadAddresses(userId);

        state = state.copyWith(isUpdating: false);

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Address updated successfully');
        }
        return true;
      } else {
        final message = response.error ?? 'Failed to update address';
        print('🔴 AddressProvider: Update failed - $message');
        state = state.copyWith(
          isUpdating: false,
          error: message,
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(context, message);
        }
        return false;
      }
    } catch (e) {
      print('🔴 AddressProvider: Update exception - $e');
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
