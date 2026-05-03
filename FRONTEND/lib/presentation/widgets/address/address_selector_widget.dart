import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../data/data_source/dto/address/address_dto.dart';
import '../../provider/main/address/address_provider.dart';
import '../../provider/auth/auth_provider.dart';

/// Compact address selector widget for use in booking/checkout screens
class AddressSelectorWidget extends ConsumerStatefulWidget {
  final Function(AddressDto address)? onAddressSelected;
  final String? title;
  final bool showManageButton;

  const AddressSelectorWidget({
    Key? key,
    this.onAddressSelected,
    this.title,
    this.showManageButton = true,
  }) : super(key: key);

  @override
  ConsumerState<AddressSelectorWidget> createState() =>
      _AddressSelectorWidgetState();
}

class _AddressSelectorWidgetState extends ConsumerState<AddressSelectorWidget> {
  @override
  void initState() {
    super.initState();
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: const Color(0xFF5F2D82),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? 'Delivery Address',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (widget.showManageButton)
                  TextButton(
                    onPressed: () => AppRouter.push(context, MainRoutes.addressManagement),
                    child: Text(
                      'Manage',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          if (addressState.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5F2D82),
                ),
              ),
            )
          else if (addressState.addresses.isEmpty)
            _EmptyAddressState(
              onAdd: () => AppRouter.push(context, MainRoutes.addressManagement),
            )
          else
            _AddressList(
              addresses: addressState.addresses,
              selectedAddress: addressState.selectedAddress,
              onAddressSelected: (address) {
                ref.read(addressProvider.notifier).selectAddress(address);
                widget.onAddressSelected?.call(address);
              },
            ),
        ],
      ),
    );
  }
}

class _AddressList extends StatelessWidget {
  final List<AddressDto> addresses;
  final AddressDto? selectedAddress;
  final Function(AddressDto) onAddressSelected;

  const _AddressList({
    required this.addresses,
    required this.selectedAddress,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Default address (if exists)
        if (addresses.any((addr) => addr.isDefault)) ...[
          _AddressItem(
            address: addresses.firstWhere((addr) => addr.isDefault),
            isSelected: selectedAddress?.id == addresses.firstWhere((addr) => addr.isDefault).id,
            onTap: () => onAddressSelected(addresses.firstWhere((addr) => addr.isDefault)),
          ),
        ],

        // Other addresses
        ...addresses
            .where((addr) => !addr.isDefault)
            .take(2) // Show max 2 non-default addresses
            .map((addr) => _AddressItem(
                  address: addr,
                  isSelected: selectedAddress?.id == addr.id,
                  onTap: () => onAddressSelected(addr),
                )),

        // Show more button if there are more addresses
        if (addresses.length > 3)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, MainRoutes.addressManagement),
              child: Text(
                'View all ${addresses.length} addresses',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: const Color(0xFF5F2D82),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddressItem extends StatelessWidget {
  final AddressDto address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressItem({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82).withValues(alpha: 0.05) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF5F2D82) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF5F2D82) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: address.isDefault
                              ? const Color(0xFF5F2D82)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          address.label,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: address.isDefault ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.green.shade200, width: 0.5),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 8,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.addressLine1,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.contactName?.isNotEmpty == true)
                    Text(
                      '${address.contactName ?? ''} · ${address.contactPhone ?? ''}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAddressState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address to continue',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Add Address',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}