import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';

class RiderDutyToggle extends ConsumerWidget {
  const RiderDutyToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnDuty = ref.watch(riderDutyProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: isOnDuty,
          onChanged: (val) {
            ref.read(riderDutyProvider.notifier).state = val;
          },
          activeTrackColor: const Color(0xFF5F2D82), // Dark purple
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade400,
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Text(
          isOnDuty ? 'ON DUTY' : 'OFF DUTY',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w900, // Black/Heavy weight as seen in design
            color: Colors.black, // Adjust based on design feedback if needed
          ),
        ),
      ],
    );
  }
}
