import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import 'rider_bookings_map_view.dart';

class RiderBookingsView extends ConsumerStatefulWidget {
  const RiderBookingsView({super.key});

  @override
  ConsumerState<RiderBookingsView> createState() => _RiderBookingsViewState();
}

class _RiderBookingsViewState extends ConsumerState<RiderBookingsView> {
  bool _showMapView = false; // Default to list view for web compatibility

  @override
  Widget build(BuildContext context) {
    final isOnDuty = ref.watch(riderDutyProvider);

    return Column(
      children: [
        // Top Header + Duty toggle section with view switcher
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const RiderBookingsHeader(),
              
              // View Toggle (hide map option on web)
              if (!kIsWeb)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildViewToggleButton(
                          icon: Icons.map,
                          label: 'Map View',
                          isSelected: _showMapView,
                          onTap: () => setState(() => _showMapView = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildViewToggleButton(
                          icon: Icons.list,
                          label: 'List View',
                          isSelected: !_showMapView,
                          onTap: () => setState(() => _showMapView = false),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Content based on selected view
        Expanded(
          child: _showMapView && !kIsWeb
              ? const RiderBookingsMapView()
              : isOnDuty
                  ? RiderBookingsList(
                      onBookingTap: (booking) {
                        AppRouter.push(
                          context,
                          MainRoutes.riderBookingDetail,
                          arguments: booking,
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'You are currently OFF DUTY.\nTurn ON DUTY to receive bookings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
