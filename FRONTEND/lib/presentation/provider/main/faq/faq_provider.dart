import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/faq_remote_datasource.dart';
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
    bool clearError = false,
  }) {
    return FaqState(
      faqs: faqs ?? this.faqs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FaqNotifier extends StateNotifier<FaqState> {
  FaqNotifier() : super(FaqState(faqs: [], isLoading: true)) {
    loadFaqs();
  }

  final FaqRemoteDataSource _faqDataSource = getIt<FaqRemoteDataSource>();

  Future<void> loadFaqs() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _faqDataSource.getArticles();
      final articles = response.data
          .where((article) => article.isActive)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      // Exclude the FAQ asking where we deliver (remove from list)
      final filtered = articles.where((article) {
        final title = article.title.toLowerCase();
        return !(title.contains('where') && title.contains('deliver'));
      }).toList();

      state = state.copyWith(
        faqs: filtered
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
        faqs: [],
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load FAQs from server.',
          fallbackTl: 'Hindi ma-load ang FAQs mula sa server.',
        ),
      );
    }
  }

  Future<void> refreshFaqs() => loadFaqs();
}

final faqProvider = StateNotifierProvider<FaqNotifier, FaqState>((ref) {
  return FaqNotifier();
});
