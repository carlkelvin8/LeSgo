import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/booking/lesride_vehicle_option.dart';

class LesrideVehicleSelector extends StatelessWidget {
  const LesrideVehicleSelector({
    super.key,
    required this.selectedVehicle,
    required this.onSelected,
  });

  final LesrideVehicleOption selectedVehicle;
  final ValueChanged<LesrideVehicleOption> onSelected;

  Widget _tile(LesrideVehicleOption vehicle) => _VehicleCard(
    key: ValueKey('lesride_vehicle_${vehicle.code}'),
    vehicle: vehicle,
    isSelected: vehicle == selectedVehicle,
    onTap: vehicle.isAvailable ? () => onSelected(vehicle) : null,
  );

  @override
  Widget build(BuildContext context) {
    final available = LesrideVehicleOption.values.where(
      (vehicle) => vehicle.isAvailable,
    );
    final upcoming = LesrideVehicleOption.values
        .where((vehicle) => !vehicle.isAvailable)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrderSectionHeading('Choose vehicle'),
        const SizedBox(height: 10),
        for (final vehicle in available) ...[
          _tile(vehicle),
          const SizedBox(height: 8),
        ],
        if (upcoming.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < upcoming.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _tile(upcoming[i])),
              ],
            ],
          ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    this.onTap,
  });

  final LesrideVehicleOption vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  IconData get _icon {
    switch (vehicle) {
      case LesrideVehicleOption.tricycle:
        return Icons.electric_rickshaw;
      case LesrideVehicleOption.sedan:
        return Icons.directions_car;
      case LesrideVehicleOption.sevenSeater:
        return Icons.airport_shuttle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = vehicle.isAvailable;
    final foreground = isSelected ? const Color(0xFFFFF7FF) : colors.onSurface;
    return Semantics(
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: isSelected ? const Color(0xFF38204E) : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: OrderDesign.cardRadius,
          side: BorderSide(
            color: isSelected ? Colors.transparent : OrderDesign.line(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: enabled ? 12 : 9,
            ),
            child: Row(
              children: [
                if (enabled)
                  OrderIcon(_icon, mint: isSelected)
                else
                  Icon(_icon, size: 19, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.label,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: enabled ? 16 : 12,
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      if (!enabled)
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFCFF9EB),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
