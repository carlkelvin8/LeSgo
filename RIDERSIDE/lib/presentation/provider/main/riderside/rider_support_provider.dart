import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/support_api.dart';
import '../../../../core/services/api_service.dart';

class RiderSupportState {
  final List<RiderSupportTicket> tickets;
  final bool isLoading;
  final String? error;

  const RiderSupportState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  RiderSupportState copyWith({
    List<RiderSupportTicket>? tickets,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderSupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderSupportNotifier extends StateNotifier<RiderSupportState> {
  RiderSupportNotifier() : super(const RiderSupportState());

  Future<void> loadTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await SupportApi.getTickets();
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> createTicket({
    required String subject,
    required String description,
    String category = 'general',
    int? orderId,
  }) async {
    try {
      await SupportApi.createTicket(
        subject: subject,
        description: description,
        category: category,
        orderId: orderId,
      );
      await loadTickets();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }
}

final riderSupportProvider =
    StateNotifierProvider<RiderSupportNotifier, RiderSupportState>(
  (ref) => RiderSupportNotifier(),
);
