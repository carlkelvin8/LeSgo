import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
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
    this.appliedVoucher,
    this.onApplyVoucher,
    this.onRemoveVoucher,
    this.voucherEnabled = true,
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
  final String? appliedVoucher;
  final VoidCallback? onApplyVoucher;
  final VoidCallback? onRemoveVoucher;
  final bool voucherEnabled;
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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            VoucherSection(
              enabled: voucherEnabled,
              appliedVoucher: appliedVoucher,
              onApplyTap: onApplyVoucher,
              onRemoveTap: onRemoveVoucher,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            PrimaryButton(text: 'Book', onPressed: onBook),
          ],
        ),
      ),
    );
  }
}
