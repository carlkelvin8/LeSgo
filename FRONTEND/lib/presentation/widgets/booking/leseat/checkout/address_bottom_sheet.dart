import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../provider/auth/auth_provider.dart';

/// Shows a bottom sheet with the user's saved addresses.
/// Returns the selected [AddressDto] or null if dismissed.
Future<AddressDto?> showAddressBottomSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<AddressDto>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _AddressBottomSheet(),
    ),
  );
}

class _AddressBottomSheet extends ConsumerStatefulWidget {
  const _AddressBottomSheet();

  @override
  ConsumerState<_AddressBottomSheet> createState() =>
      _AddressBottomSheetState();
}

class _AddressBottomSheetState extends ConsumerState<_AddressBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  void _loadAddresses() {
    final authState = ref.read(authProvider);
    final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
    if (userId > 0) {
      ref.read(addressProvider.notifier).loadAddresses(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Address list
          Expanded(
            child: addressState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                  )
                : addressState.addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved addresses.\nAdd one in your profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: addressState.addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final addr = addressState.addresses[i];
                      final isSelected =
                          addressState.selectedAddress?.id == addr.id;
                      return _AddressTile(
                        address: addr,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(context, addr),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressDto address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5F2D82).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5F2D82).withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                address.isDefault ? Icons.home : Icons.location_on_outlined,
                color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF5F2D82)
                              : Colors.black87,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F2D82),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.addressLine1,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((address.contactName?.isNotEmpty ?? false) ||
                      (address.contactPhone?.isNotEmpty ?? false))
                    Text(
                      '${address.contactName ?? ''} - ${address.contactPhone ?? ''}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF5F2D82),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
