import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/services/order_sound_alert_service.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../widgets/common/location_permission_banner.dart';
import 'rider_bookings_map_view.dart';
import '../../../../widgets/main/riderside/bookings/rider_bookings_state_panel.dart';

class RiderBookingsView extends ConsumerStatefulWidget {
  const RiderBookingsView({super.key});

  @override
  ConsumerState<RiderBookingsView> createState() => _RiderBookingsViewState();
}

class _RiderBookingsViewState extends ConsumerState<RiderBookingsView> {
  bool _showMapView = false;
  ProviderSubscription<RiderOrdersState>? _ordersSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Stop persistent notification sound when rider views bookings
      OrderSoundAlertService().acknowledgeOrderAlert();
      
      _ordersSub = ref.listenManual<RiderOrdersState>(riderOrdersProvider, (
        previous,
        next,
      ) {
        if (!mounted) return;
        if (next.activeOrder != null && previous?.activeOrder == null) {
          setState(() => _showMapView = true);
        }
      });
      if (ref.read(riderOrdersProvider).activeOrder != null) {
        setState(() => _showMapView = true);
      }
    });
  }

  @override
  void dispose() {
    _ordersSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final tl = lang == AppLanguage.filipino;
    final isOnDuty = ref.watch(riderDutyProvider);
    final colors = Theme.of(context).colorScheme;
    final map = _showMapView && !kIsWeb;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? colors.surface
          : const Color(0xFFF8F7FB),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * (map ? 0.35 : 0.54),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const LocationPermissionBanner(),
                    const RiderBookingsHeader(),
                    if (!kIsWeb)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildViewToggleButton(
                                  icon: Icons.map_outlined,
                                  label: AppLocalization.translate(
                                    'map_view',
                                    lang,
                                  ),
                                  isSelected: map,
                                  onTap: () =>
                                      setState(() => _showMapView = true),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildViewToggleButton(
                                  icon: Icons.view_list_rounded,
                                  label: AppLocalization.translate(
                                    'list_view',
                                    lang,
                                  ),
                                  isSelected: !map,
                                  onTap: () =>
                                      setState(() => _showMapView = false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                child: map
                    ? const RiderBookingsMapView(key: ValueKey('map'))
                    : isOnDuty
                    ? RiderBookingsList(
                        key: const ValueKey('list'),
                        onBookingTap: (booking) => AppRouter.push(
                          context,
                          MainRoutes.riderBookingDetail,
                          arguments: booking,
                        ),
                      )
                    : RiderBookingsStatePanel(
                        key: const ValueKey('off-duty'),
                        icon: Icons.nightlight_round,
                        title: tl ? 'Magpahinga muna' : 'Take a breather',
                        message: tl
                            ? 'Naka-off duty ka. Gamitin ang switch sa itaas kapag handa ka nang tumanggap ng booking.'
                            : 'You’re off duty. Use the switch above when you’re ready to receive bookings.',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: isSelected
                ? colors.primary
                : colors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
