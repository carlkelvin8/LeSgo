import 'package:flutter_riverpod/flutter_riverpod.dart';

// LesPay State
class LespayState {
  final double balance;
  final bool isLoading;
  final String? error;

  LespayState({
    this.balance = 86.00,
    this.isLoading = false,
    this.error,
  });

  LespayState copyWith({
    double? balance,
    bool? isLoading,
    String? error,
  }) {
    return LespayState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LespayNotifier extends StateNotifier<LespayState> {
  LespayNotifier() : super(LespayState());

  Future<void> topUp(double amount) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(
        balance: state.balance + amount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> withdraw(double amount) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (state.balance >= amount) {
        state = state.copyWith(
          balance: state.balance - amount,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Insufficient balance',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void refreshBalance() {
    // Simulate refresh
    state = state.copyWith(isLoading: true);
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(isLoading: false);
    });
  }
}

final lespayProvider = StateNotifierProvider<LespayNotifier, LespayState>((ref) {
  return LespayNotifier();
});
