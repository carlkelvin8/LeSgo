import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
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
    return OrderBookingSheet(
      title: 'Where are you headed?',
      handle: const LesrideDragHandle(),
      controller: scrollController,
      action: PrimaryButton(
        text: onBook != null || isBooking
            ? 'Book'
            : (locationState.destinationAddress == null
                  ? 'Choose a destination to continue'
                  : 'Calculating fare…'),
        onPressed: onBook,
        isLoading: isBooking,
      ),
      children: [
        OrderRouteGroup(
          children: [
            LesrideLocationTile(
              title: 'Current Location',
              subtitle: locationState.pickupAddress != null
                  ? _formatAddress(locationState.pickupAddress!)
                  : 'Fetching current location...',
              trailing: LesrideChangeButton(onPressed: onChangeCurrent),
            ),
            LesrideLocationTile(
              title: 'Where are you going?',
              isDestination: true,
              subtitle: locationState.destinationAddress != null
                  ? _formatAddress(locationState.destinationAddress!)
                  : 'Tap on the map to update destination',
              trailing: LesrideChangeButton(onPressed: onChangeDestination),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
      ],
    );
  }
}
