import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import 'rider_duty_toggle.dart';

class RiderBookingsHeader extends ConsumerWidget {
  final bool compact;
  const RiderBookingsHeader({super.key, this.compact = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onDuty = ref.watch(riderDutyProvider);
    final orders = ref.watch(riderOrdersProvider);
    final tl = ref.watch(appLanguageProvider) == AppLanguage.filipino;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF713894), Color(0xFF352044)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: Color(0xFFE2C5F3),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tl ? 'IYONG MGA BOOKING' : 'YOUR DELIVERY HUB',
                          style: const TextStyle(
                            color: Color(0xFFE2C5F3),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    orders.activeOrder != null
                        ? (tl ? 'May biyahe ka ngayon' : 'A delivery in motion')
                        : (tl
                              ? 'Handa sa susunod na biyahe'
                              : 'Ready for your next ride'),
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    onDuty
                        ? (tl
                              ? 'Tingnan ang mga booking at planuhin ang iyong ruta.'
                              : 'Find your next booking and plan your route.')
                        : (tl
                              ? 'Mag-on duty kapag handa ka nang bumiyahe.'
                              : 'Go on duty when you’re ready to deliver.'),
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      color: Color(0xFFE2D3EC),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: const RiderDutyToggle(),
          ),
        ],
      ),
    );
  }
}
