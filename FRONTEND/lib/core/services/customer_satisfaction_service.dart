import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';
import '../constants/routers/app_router.dart';
import '../../data/data_source/survey_remote_datasource.dart';
import '../../presentation/widgets/survey/customer_satisfaction_dialog.dart';

/// Tracks completed orders and shows a satisfaction survey after [surveyThreshold].
class CustomerSatisfactionService {
  static const surveyThreshold = 3;
  static const _completedOrdersKey = 'customer_completed_orders_count';
  static const _surveyCompletedKey = 'customer_survey_completed';

  final SharedPreferences _prefs;
  final SurveyRemoteDataSource _surveyDs = getIt<SurveyRemoteDataSource>();

  CustomerSatisfactionService(this._prefs);

  int get completedOrdersCount => _prefs.getInt(_completedOrdersKey) ?? 0;

  bool get hasCompletedSurvey => _prefs.getBool(_surveyCompletedKey) ?? false;

  bool get shouldShowSurvey =>
      completedOrdersCount >= surveyThreshold && !hasCompletedSurvey;

  Future<void> onOrderCompleted(BuildContext context) async {
    final next = completedOrdersCount + 1;
    await _prefs.setInt(_completedOrdersKey, next);

    if (next >= surveyThreshold && !hasCompletedSurvey && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (context.mounted) {
        await CustomerSatisfactionDialog.show(context, this);
      }
    }
  }

  /// Called from tracking when order reaches completed (all services).
  Future<void> onOrderCompletedFromTracking() async {
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await onOrderCompleted(context);
      return;
    }

    final next = completedOrdersCount + 1;
    await _prefs.setInt(_completedOrdersKey, next);
  }

  Future<void> markSurveyCompleted({int? rating, String? feedback}) async {
    if (rating != null) {
      try {
        await _surveyDs.submitCustomerSatisfaction(
          rating: rating,
          feedback: feedback,
          completedOrdersCount: completedOrdersCount,
        );
      } catch (_) {
        // Keep local completion even if backend sync fails offline.
      }
    }

    await _prefs.setBool(_surveyCompletedKey, true);
    if (rating != null) {
      await _prefs.setInt('customer_survey_rating', rating);
    }
    if (feedback != null && feedback.trim().isNotEmpty) {
      await _prefs.setString('customer_survey_feedback', feedback.trim());
    }
  }

  Future<void> resetSurveyState() async {
    await _prefs.remove(_completedOrdersKey);
    await _prefs.remove(_surveyCompletedKey);
    await _prefs.remove('customer_survey_rating');
    await _prefs.remove('customer_survey_feedback');
  }
}
