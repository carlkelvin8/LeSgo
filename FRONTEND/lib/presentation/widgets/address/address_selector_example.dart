import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/address/address_provider.dart';
import '../../provider/auth/auth_provider.dart';

/// Example widget showing how to use AddressProvider
/// This can be used in checkout screens for address selection
class AddressSelectorExample extends ConsumerStatefulWidget {
  final Function(int addressId)? onAddressSelected;

  const AddressSelectorExample({
    Key? key,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  ConsumerState<AddressSelectorExample> createState() =>
      _AddressSelectorExampleState();
}

class _AddressSelectorExampleState
    extends ConsumerState<AddressSelectorExample> {
  @override
  void initState() {
    super.initState();
    // Load addresses when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  void _loadAddresses() {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      ref.read(addressProvider.notifier).loadAddresses(int.parse(authState.user!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);
    final authState = ref.watch(authProvider);

    if (addressState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (addressState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${addressState.error}'),
            ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (addressState.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No saved addresses'),
            ElevatedButton(
              onPressed: () {
                // Navigate to add address screen
                _showAddAddressDialog(context, int.tryParse(authState.user?.id ?? '0') ?? 0);
              },
              child: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Address list
        Expanded(
          child: ListView.builder(
            itemCount: addressState.addresses.length,
            itemBuilder: (context, index) {
              final address = addressState.addresses[index];
              final isSelected =
                  addressState.selectedAddress?.id == address.id;

              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  leading: Icon(
                    address.isDefault ? Icons.star : Icons.location_on,
                    color: address.isDefault ? Colors.amber : null,
                  ),
                  title: Text(address.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.addressLine1),
                      if (address.addressLine2 != null)
                        Text(address.addressLine2!),
                      Text(
                        '${address.contactName} - ${address.contactPhone}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!address.isDefault)
                        IconButton(
                          icon: const Icon(Icons.star_border),
                          onPressed: () {
                            _setAsDefault(address.id);
                          },
                          tooltip: 'Set as default',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditAddressDialog(
                            context,
                            int.tryParse(authState.user?.id ?? '0') ?? 0,
                            address.id,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteAddress(address.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(addressProvider.notifier).selectAddress(address);
                    widget.onAddressSelected?.call(address.id);
                  },
                ),
              );
            },
          ),
        ),

        // Add new address button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddAddressDialog(context, int.tryParse(authState.user?.id ?? '0') ?? 0);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
          ),
        ),
      ],
    );
  }

  void _setAsDefault(int addressId) {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      ref.read(addressProvider.notifier).setAsDefault(
            userId: int.parse(authState.user!.id),
            addressId: addressId,
            context: context,
          );
    }
  }

  void _deleteAddress(int addressId) {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Address'),
          content: const Text('Are you sure you want to delete this address?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(addressProvider.notifier).deleteAddress(
                      userId: int.parse(authState.user!.id),
                      addressId: addressId,
                      context: this.context,
                    );
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddAddressDialog(BuildContext context, int userId) {
    // Navigate to address management screen
    Navigator.pushNamed(context, '/address-management');
  }

  void _showEditAddressDialog(
    BuildContext context,
    int userId,
    int addressId,
  ) {
    // Navigate to address management screen
    Navigator.pushNamed(context, '/address-management');
  }
}
