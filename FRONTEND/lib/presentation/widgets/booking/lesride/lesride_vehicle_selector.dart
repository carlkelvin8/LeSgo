import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/lesride_vehicle_option.dart';

class LesrideVehicleSelector extends StatelessWidget {
  const LesrideVehicleSelector({
    super.key,
    required this.selectedVehicle,
    required this.onSelected,
  });

  final LesrideVehicleOption selectedVehicle;
  final ValueChanged<LesrideVehicleOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose vehicle',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w700,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        Row(
          children: LesrideVehicleOption.values.map((vehicle) {
            final isSelected = vehicle == selectedVehicle;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: vehicle == LesrideVehicleOption.sevenSeater
                      ? 0
                      : ResponsiveUtils.spacing(context, 8),
                ),
                child: _VehicleCard(
                  key: ValueKey('lesride_vehicle_${vehicle.code}'),
                  vehicle: vehicle,
                  isSelected: isSelected,
                  onTap: vehicle.isAvailable ? () => onSelected(vehicle) : null,
                ),
              ),
            );
          }).toList(),
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
    final enabled = vehicle.isAvailable;
    final borderColor = isSelected
        ? AppColors.accent(context, const Color(0xFF5F2D82))
        : AppColors.border(context, Colors.grey.shade300);

    return Material(
      color: isSelected
          ? AppColors.surface(context, Color(0xFFF5EEFA))
          : enabled
          ? AppColors.surface(context, Colors.white)
          : AppColors.surface(context, Colors.grey.shade100),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 6),
            vertical: ResponsiveUtils.spacing(context, 10),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icon,
                size: 28,
                color: enabled ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.foreground(context, Colors.grey),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 5)),
              Text(
                vehicle.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w700,
                  color: enabled ? AppColors.foreground(context, Colors.black87) : AppColors.foreground(context, Colors.grey.shade600),
                ),
              ),
              if (!enabled) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 10, color: AppColors.foreground(context, Colors.grey.shade600)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'Coming Soon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 8),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
