import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/booking/booking_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../domain/entities/booking/booking_service.dart';
import '../../../../core/constants/routers/app_router.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(bookingProvider.notifier).loadServices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 16),
                    ),
                    child: const AuthHeader(title: 'Book Now'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.spacing(context, 16),
                      ),
                      child: Column(
                        children: [
                          bookingState.error != null
                              ? BookingErrorPanel(message: bookingState.error!)
                              : BookingServicesSection(
                                  services: bookingState.services,
                                  horizontalPadding: horizontalPadding,
                                  onSelect: (serviceType) {
                                    ref
                                        .read(bookingProvider.notifier)
                                        .selectService(
                                          bookingState.services.firstWhere(
                                            (s) => s.type == serviceType,
                                          ),
                                        );

                                    String route;
                                    switch (serviceType) {
                                      case ServiceType.leseat:
                                        route = BookingRoutes.leseat;
                                        break;
                                      case ServiceType.lesbuy:
                                        route = BookingRoutes.lesbuy;
                                        break;
                                      case ServiceType.lesgo:
                                        route = BookingRoutes.lesgo;
                                        break;
                                      case ServiceType.lesport:
                                        route = BookingRoutes.lesport;
                                        break;
                                      case ServiceType.lesride:
                                        route = BookingRoutes.lesride;
                                        break;
                                    }
                                    AppRouter.push(context, route);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
