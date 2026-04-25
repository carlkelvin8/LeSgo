import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/faq/faq.dart';

class FaqState {
  final List<Faq> faqs;
  final bool isLoading;
  final String? error;

  FaqState({
    required this.faqs,
    this.isLoading = false,
    this.error,
  });

  FaqState copyWith({
    List<Faq>? faqs,
    bool? isLoading,
    String? error,
  }) {
    return FaqState(
      faqs: faqs ?? this.faqs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FaqNotifier extends StateNotifier<FaqState> {
  FaqNotifier() : super(FaqState(faqs: [])) {
    _loadFaqs();
  }

  void _loadFaqs() {
    // Mock data - replace with actual API call
    final faqs = [
      Faq(
        id: '1',
        question: 'How much is our delivery rates?',
        answer: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In id eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit. In id eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      ),
      Faq(
        id: '2',
        question: 'Where do you deliver?',
        answer: 'We deliver to all areas within Metro Manila and selected provinces. For specific delivery coverage, please contact our customer service.',
      ),
      Faq(
        id: '3',
        question: 'What is LeSgo',
        answer: 'LeSgo is a convenient delivery service that helps you send packages quickly and safely to your desired destination.',
      ),
      Faq(
        id: '4',
        question: 'What is LesBuy',
        answer: 'LesBuy is our shopping service that allows you to purchase items from various stores and have them delivered to your doorstep.',
      ),
      Faq(
        id: '5',
        question: 'What is LesSeat',
        answer: 'LesSeat is our transportation booking service that connects you with reliable drivers for your travel needs.',
      ),
    ];

    state = state.copyWith(faqs: faqs);
  }

  void refreshFaqs() {
    state = state.copyWith(isLoading: true);
    _loadFaqs();
    state = state.copyWith(isLoading: false);
  }
}

final faqProvider = StateNotifierProvider<FaqNotifier, FaqState>((ref) {
  return FaqNotifier();
});
