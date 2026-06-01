import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/faq_remote_datasource.dart';
import '../../../../domain/entities/faq/faq.dart';

class FaqState {
  final List<Faq> faqs;
  final bool isLoading;
  final String? error;
  final String? infoMessage;

  FaqState({
    required this.faqs,
    this.isLoading = false,
    this.error,
    this.infoMessage,
  });

  FaqState copyWith({
    List<Faq>? faqs,
    bool? isLoading,
    String? error,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return FaqState(
      faqs: faqs ?? this.faqs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

List<Faq> _fallbackFaqs() {
  return [
    Faq(
      id: '1',
      question: 'How much are delivery rates?',
      answer:
          'Delivery fees depend on distance and service type. LesGo, LesRide, and LesEat '
          'show the estimated fee before you confirm your order. You can also check the '
          'order summary on checkout for the final amount.',
    ),
    Faq(
      id: '2',
      question: 'Where do you deliver?',
      answer:
          'LesGo currently serves Cagayan de Oro and nearby areas within our service radius. '
          'If your pickup or drop-off is outside coverage, the app will notify you before booking.',
    ),
    Faq(
      id: '3',
      question: 'What is LesGo?',
      answer:
          'LesGo is our on-demand delivery service for parcels, documents, and items you '
          'need picked up and dropped off around the city.',
    ),
    Faq(
      id: '4',
      question: 'What is LesBuy?',
      answer:
          'LesBuy lets you order items from partner stores or submit a manual shopping list. '
          'A rider will purchase the items and deliver them to you.',
    ),
    Faq(
      id: '5',
      question: 'What is LesEat?',
      answer:
          'LesEat is our food delivery service. Browse partner restaurants, add items to your '
          'cart, and track your order until it arrives.',
    ),
  ];
}

class FaqNotifier extends StateNotifier<FaqState> {
  FaqNotifier() : super(FaqState(faqs: [], isLoading: true)) {
    loadFaqs();
  }

  final FaqRemoteDataSource _faqDataSource = getIt<FaqRemoteDataSource>();

  Future<void> loadFaqs() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      final response = await _faqDataSource.getArticles();
      final articles = response.data
          .where((article) => article.isActive)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      if (articles.isEmpty) {
        state = state.copyWith(
          faqs: _fallbackFaqs(),
          isLoading: false,
          infoMessage: 'FAQ content is being updated.',
        );
        return;
      }

      state = state.copyWith(
        faqs: articles
            .map(
              (article) => Faq(
                id: article.id.toString(),
                question: article.title,
                answer: article.content,
              ),
            )
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        faqs: _fallbackFaqs(),
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load FAQs from server.',
          fallbackTl: 'Hindi ma-load ang FAQs mula sa server.',
        ),
        infoMessage: 'Showing saved answers while offline.',
      );
    }
  }

  Future<void> refreshFaqs() => loadFaqs();
}

final faqProvider = StateNotifierProvider<FaqNotifier, FaqState>((ref) {
  return FaqNotifier();
});
