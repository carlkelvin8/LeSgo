import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/models/location/location_address.dart';
import '../../../../domain/entities/booking/lesride_vehicle_option.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../widgets.dart';

class LesrideDetailsPanel extends StatelessWidget {
  const LesrideDetailsPanel({
    super.key,
    required this.locationState,
    required this.onChangeCurrent,
    required this.onChangeDestination,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.onBook,
    required this.selectedVehicle,
    required this.onVehicleSelected,
    required this.isBooking,
    this.scrollController,
  });

  final LesrideLocationState locationState;
  final VoidCallback onChangeCurrent;
  final VoidCallback onChangeDestination;
  final String paymentMethod;
  final ValueChanged<String?> onPaymentChanged;
  final VoidCallback? onBook;
  final LesrideVehicleOption selectedVehicle;
  final ValueChanged<LesrideVehicleOption> onVehicleSelected;
  final bool isBooking;
  final ScrollController? scrollController;

  String _formatAddress(LocationAddress address) {
    final parts = <String>[];

    if (address.houseNumberStreet != null &&
        address.houseNumberStreet!.isNotEmpty) {
      parts.add(address.houseNumberStreet!);
    }

    if (address.subdivisionBarangay != null &&
        address.subdivisionBarangay!.isNotEmpty) {
      parts.add(address.subdivisionBarangay!);
    }

    if (address.cityProvince != null && address.cityProvince!.isNotEmpty) {
      parts.add(address.cityProvince!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration:  BoxDecoration(
        color: AppColors.surface(context, Colors.white),
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
              title: 'Current Location',
              subtitle: locationState.pickupAddress != null
                  ? _formatAddress(locationState.pickupAddress!)
                  : 'Fetching current location...',
              trailing: LesrideChangeButton(onPressed: onChangeCurrent),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            LesrideLocationTile(
              title: 'Where are you going?',
              subtitle: locationState.destinationAddress != null
                  ? _formatAddress(locationState.destinationAddress!)
                  : 'Tap on the map to update destination',
              trailing: LesrideChangeButton(onPressed: onChangeDestination),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            LesrideVehicleSelector(
              selectedVehicle: selectedVehicle,
              onSelected: onVehicleSelected,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            const LesrideFareSummary(),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            LesridePaymentSection(
              paymentMethod: paymentMethod,
              onPaymentChanged: onPaymentChanged,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            PrimaryButton(
              text: 'Book',
              onPressed: onBook,
              isLoading: isBooking,
            ),
          ],
        ),
      ),
    );
  }
}
