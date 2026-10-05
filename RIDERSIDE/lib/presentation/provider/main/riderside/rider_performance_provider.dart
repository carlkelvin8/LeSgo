import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Performance metrics provider
final riderPerformanceProvider = StateNotifierProvider.autoDispose<RiderPerformanceNotifier, RiderPerformanceState>(
  (ref) => RiderPerformanceNotifier(),
);

class RiderPerformanceNotifier extends StateNotifier<RiderPerformanceState> {
  RiderPerformanceNotifier() : super(const RiderPerformanceState());

  Future<void> loadPerformanceMetrics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.dio.get('/v1/drivers/me/performance');
      final data = response.data['data'] ?? response.data;

      final acceptanceRate = (data['acceptance_rate'] as num?)?.toDouble() ?? 0.0;
      final completionRate = (data['completion_rate'] as num?)?.toDouble() ?? 0.0;
      final onTimeRate = (data['on_time_rate'] as num?)?.toDouble() ?? 0.0;
      final customerRating = (data['customer_rating'] as num?)?.toDouble() ?? 0.0;
      final totalReviews = data['total_reviews'] as int? ?? 0;
      final cancellations = data['cancellations'] as int? ?? 0;
      final lateArrivals = data['late_arrivals'] as int? ?? 0;
      final acceptedOrders = data['accepted_orders'] as int? ?? 0;

      // Performance trend data
      final performanceTrendList = (data['performance_trend'] as List?)
          ?.whereType<Map>()
          .map((e) => PerformanceTrendData.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [];

      state = state.copyWith(
        acceptanceRate: acceptanceRate,
        completionRate: completionRate,
        onTimeRate: onTimeRate,
        customerRating: customerRating,
        totalReviews: totalReviews,
        cancellations: cancellations,
        lateArrivals: lateArrivals,
        acceptedOrders: acceptedOrders,
        performanceTrend: performanceTrendList,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load performance metrics', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load performance data',
      );
    }
  }

  Future<void> refreshPerformanceMetrics() async {
    await loadPerformanceMetrics();
  }
}

class RiderPerformanceState {
  final double acceptanceRate;
  final double completionRate;
  final double onTimeRate;
  final double customerRating;
  final int totalReviews;
  final int cancellations;
  final int lateArrivals;
  final int acceptedOrders;
  final List<PerformanceTrendData> performanceTrend;
  final bool isLoading;
  final String? error;

  const RiderPerformanceState({
    this.acceptanceRate = 0.0,
    this.completionRate = 0.0,
    this.onTimeRate = 0.0,
    this.customerRating = 0.0,
    this.totalReviews = 0,
    this.cancellations = 0,
    this.lateArrivals = 0,
    this.acceptedOrders = 0,
    this.performanceTrend = const [],
    this.isLoading = false,
    this.error,
  });

  String get acceptanceRateFormatted => '${acceptanceRate.toStringAsFixed(1)}%';
  String get completionRateFormatted => '${completionRate.toStringAsFixed(1)}%';
  String get onTimeRateFormatted => '${onTimeRate.toStringAsFixed(1)}%';
  String get customerRatingFormatted => customerRating.toStringAsFixed(2);

  // Determine rating badge color
  Color get ratingColor {
    if (customerRating >= 4.5) return const Color(0xFF4CAF50); // Green
    if (customerRating >= 4.0) return const Color(0xFF8BC34A); // Light green
    if (customerRating >= 3.5) return const Color(0xFFFFC107); // Amber
    if (customerRating >= 3.0) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String get ratingStatus {
    if (customerRating >= 4.5) return 'Excellent';
    if (customerRating >= 4.0) return 'Very Good';
    if (customerRating >= 3.5) return 'Good';
    if (customerRating >= 3.0) return 'Average';
    return 'Needs Improvement';
  }

  RiderPerformanceState copyWith({
    double? acceptanceRate,
    double? completionRate,
    double? onTimeRate,
    double? customerRating,
    int? totalReviews,
    int? cancellations,
    int? lateArrivals,
    int? acceptedOrders,
    List<PerformanceTrendData>? performanceTrend,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderPerformanceState(
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      completionRate: completionRate ?? this.completionRate,
      onTimeRate: onTimeRate ?? this.onTimeRate,
      customerRating: customerRating ?? this.customerRating,
      totalReviews: totalReviews ?? this.totalReviews,
      cancellations: cancellations ?? this.cancellations,
      lateArrivals: lateArrivals ?? this.lateArrivals,
      acceptedOrders: acceptedOrders ?? this.acceptedOrders,
      performanceTrend: performanceTrend ?? this.performanceTrend,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PerformanceTrendData {
  final String period; // e.g., "Week 1", "Day 1"
  final double acceptance;
  final double completion;
  final double onTime;
  final double rating;

  const PerformanceTrendData({
    required this.period,
    required this.acceptance,
    required this.completion,
    required this.onTime,
    required this.rating,
  });

  factory PerformanceTrendData.fromJson(Map<String, dynamic> json) {
    return PerformanceTrendData(
      period: json['period']?.toString() ?? '',
      acceptance: (json['acceptance'] as num?)?.toDouble() ?? 0.0,
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
      onTime: (json['on_time'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
