import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../../data/data_source/dto/address/address_dto.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
import '../../../provider/main/booking/lesgo_provider.dart';
import '../../../provider/main/address/address_provider.dart';
import '../../address/address_selector_widget.dart';
import '../../widgets.dart';

class LesgoDetailsPanel extends ConsumerWidget {
  const LesgoDetailsPanel({
    super.key,
    required this.locationState,
    required this.onChangeCurrent,
    required this.onChangeDestination,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.onBook,
    required this.itemLocationController,
    required this.itemWeightController,
    this.onItemLocationChanged,
    this.onItemWeightChanged,
    this.scrollController,
  });

  final LesgoLocationState locationState;
  final VoidCallback onChangeCurrent;
  final VoidCallback onChangeDestination;
  final String paymentMethod;
  final ValueChanged<String?> onPaymentChanged;
  final VoidCallback onBook;
  final TextEditingController itemLocationController;
  final TextEditingController itemWeightController;
  final ValueChanged<String>? onItemLocationChanged;
  final ValueChanged<String>? onItemWeightChanged;
  final ScrollController? scrollController;

  String _formatAddress(LocationAddress address) {
    // For the cityProvince field, we're now storing the full detailed address
    if (address.cityProvince != null && address.cityProvince!.isNotEmpty) {
      // If it contains commas, it's likely a detailed address
      if (address.cityProvince!.contains(',')) {
        return address.cityProvince!;
      }
      // Otherwise, try to build a more detailed address from parts
      final parts = <String>[];
      
      if (address.houseNumberStreet != null && address.houseNumberStreet!.isNotEmpty) {
        parts.add(address.houseNumberStreet!);
      }
      
      if (address.subdivisionBarangay != null && address.subdivisionBarangay!.isNotEmpty) {
        parts.add(address.subdivisionBarangay!);
      }
      
      parts.add(address.cityProvince!);
      
      return parts.join(', ');
    }

    // Fallback to building from parts
    final parts = <String>[];

    if (address.houseNumberStreet != null &&
        address.houseNumberStreet!.isNotEmpty) {
      parts.add(address.houseNumberStreet!);
    }

    if (address.subdivisionBarangay != null &&
        address.subdivisionBarangay!.isNotEmpty) {
      parts.add(address.subdivisionBarangay!);
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return 'Address not available';
  }

  void _showAddressSelector(
    BuildContext context,
    WidgetRef ref,
    bool isPickup,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPickup ? 'Select Pickup Location' : 'Select Dropoff Location',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Map selection button
                  ListTile(
                    leading: Icon(Icons.map, color: Color(0xFF5F2D82)),
                    title: Text('Select on Map'),
                    subtitle: Text('Tap on map to choose location'),
                    onTap: () {
                      Navigator.pop(context);
                      if (isPickup) {
                        onChangeCurrent();
                      } else {
                        onChangeDestination();
                      }
                    },
                  ),
                  Divider(),
                  Text(
                    'Or choose from saved addresses:',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Address selector
            Expanded(
              child: AddressSelectorWidget(
                title: '',
                showManageButton: false,
                onAddressSelected: (address) {
                  print('🔍 LesgoDetailsPanel: Address selected - isPickup: $isPickup, address: ${address.addressLine1} (${address.latitude}, ${address.longitude})');
                  if (isPickup) {
                    print('🔍 LesgoDetailsPanel: Calling selectPickupAddress');
                    ref.read(lesgoProvider.notifier).selectPickupAddress(address);
                  } else {
                    print('🔍 LesgoDetailsPanel: Calling selectDropoffAddress');
                    ref.read(lesgoProvider.notifier).selectDropoffAddress(address);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${isPickup ? "Pickup" : "Dropoff"} address updated'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesgoState = ref.watch(lesgoProvider);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.spacing(context, 16),
            ResponsiveUtils.spacing(context, 12),
            ResponsiveUtils.spacing(context, 16),
            ResponsiveUtils.spacing(context, 24),
          ),
          children: [
            const LesrideDragHandle(),
            LesrideLocationTile(
              title: 'Pick-up Location',
              subtitle: locationState.pickupAddress != null
                  ? _formatAddress(locationState.pickupAddress!)
                  : locationState.pickupLocation != null
                  ? 'Getting address...'
                  : 'Fetching current location...',
              trailing: LesrideChangeButton(
                onPressed: () => onChangeCurrent(),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            LesrideLocationTile(
              title: 'Drop-off Location',
              subtitle: locationState.destinationAddress != null
                  ? _formatAddress(locationState.destinationAddress!)
                  : locationState.destinationLocation != null
                  ? 'Getting address...'
                  : 'Tap "Change" or tap on map to select destination',
              trailing: LesrideChangeButton(
                onPressed: () => onChangeDestination(),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            LesgoItemDetailsSection(
              itemLocationController: itemLocationController,
              itemWeightController: itemWeightController,
              onItemLocationChanged: onItemLocationChanged,
              onItemWeightChanged: onItemWeightChanged,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            LesgoPaymentSection(
              paymentMethod: paymentMethod,
              onPaymentChanged: onPaymentChanged,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            PrimaryButton(text: 'Book', onPressed: onBook),
          ],
        ),
      ),
    );
  }
}
