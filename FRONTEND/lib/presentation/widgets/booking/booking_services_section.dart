import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../widgets.dart';
import '../../../../domain/entities/booking/booking_service.dart';

class BookingServicesSection extends StatelessWidget {
  const BookingServicesSection({
    super.key,
    required this.services,
    required this.horizontalPadding,
    required this.onSelect,
  });

  final List<BookingService> services;
  final double horizontalPadding;
  final void Function(ServiceType type) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          ...services.map(
            (service) => Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 16),
              ),
              child: ServiceCard(
                service: service,
                onTap: () => onSelect(service.type),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
      ),
    );
  }
}
