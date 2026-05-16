import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/booking/booking_service.dart';

class BookingState {
  final List<BookingService> services;
  final BookingService? selectedService;
  final bool isLoading;
  final String? error;

  BookingState({
    List<BookingService>? services,
    this.selectedService,
    this.isLoading = false,
    this.error,
  }) : services = services ?? _defaultServices;

  static final List<BookingService> _defaultServices = [
    BookingService(
      id: '1',
      name: 'LesEat',
      description: 'Order your favorite menu from different restaurants!',
      iconPath: 'assets/images/book/Leseat.svg',
      type: ServiceType.leseat,
    ),
    BookingService(
      id: '2',
      name: 'LesBuy',
      description:
          'Everything? Medicine? School supplies? Anything with LesBuy',
      iconPath: 'assets/images/book/Lesbuy.svg',
      type: ServiceType.lesbuy,
    ),
    BookingService(
      id: '3',
      name: 'LesGo',
      description: 'Deliver your goods with our quick service!',
      iconPath: 'assets/images/book/Lesgo.svg',
      type: ServiceType.lesgo,
    ),
    BookingService(
      id: '4',
      name: 'LesTransport',
      description: 'Deliver your goods with our quick service!',
      iconPath: 'assets/images/book/Lesport.svg',
      type: ServiceType.lesport,
    ),
    BookingService(
      id: '5',
      name: 'LesRide',
      description: 'Ride with us to your destination',
      iconPath: 'assets/images/book/Lesride.svg',
      type: ServiceType.lesride,
    ),
  ];

  BookingState copyWith({
    List<BookingService>? services,
    BookingService? selectedService,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      services: services ?? this.services,
      selectedService: selectedService ?? this.selectedService,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(BookingState());

  void selectService(BookingService service) {
    state = state.copyWith(selectedService: service);
  }

  void clearSelection() {
    state = state.copyWith(selectedService: null);
  }

  void reset() {
    state = BookingState();
  }

  Future<void> loadServices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier();
});
