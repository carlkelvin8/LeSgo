import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/booking_workflow.dart';
import '../../../../../core/utils/media_url_utils.dart';
import '../../../../../core/utils/rider_booking_mapper.dart';
import '../../../../../domain/entities/rider_booking.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_orders_provider.dart';

// History State
class RiderHistoryState {
  final String selectedFilter;
  final List<RiderBooking> allBookings;  // Changed from Map to RiderBooking
  final int totalBookings;
  final int performanceStars;
  final bool isLoading;
  final String? error;

  const RiderHistoryState({
    this.selectedFilter = 'All',
    this.allBookings = const [],
    this.totalBookings = 0,
    this.performanceStars = 0,
    this.isLoading = false,
    this.error,
  });

  /// Available filter options
  static const List<String> filterOptions = [
    'All',
    'Completed',
    'Processing',
    'Cancelled',
  ];

  /// Filtered bookings based on selected filter
  List<RiderBooking> get filteredBookings {
    if (selectedFilter == 'All') return allBookings;
    
    if (selectedFilter == 'Completed') {
      return allBookings.where((b) =>
          b.currentStatus == BookingStatus.complete ||
          b.currentStatus == BookingStatus.delivered).toList();
    } else if (selectedFilter == 'Processing') {
      return allBookings
          .where((b) => BookingWorkflow.isProcessingBookingStatus(b.currentStatus))
          .toList();
    } else if (selectedFilter == 'Cancelled') {
      return allBookings.where((b) => b.currentStatus == BookingStatus.cancelled).toList();
    }
    
    return allBookings;
  }

  /// Count of bookings per status (for chart)
  Map<String, int> get statusCounts {
    final counts = <String, int>{
      'Completed': 0,
      'Processing': 0,
      'Cancelled': 0,
    };
    for (final booking in allBookings) {
      if (booking.currentStatus == BookingStatus.complete ||
          booking.currentStatus == BookingStatus.delivered) {
        counts['Completed'] = counts['Completed']! + 1;
      } else if (booking.currentStatus == BookingStatus.cancelled) {
        counts['Cancelled'] = counts['Cancelled']! + 1;
      } else if (BookingWorkflow.isProcessingBookingStatus(booking.currentStatus)) {
        counts['Processing'] = counts['Processing']! + 1;
      }
    }
    return counts;
  }

  /// Normalized chart data from actual booking status counts (0.0 to 1.0)
  /// Order: [Completed, Processing, Cancelled]
  List<double> get chartDataPoints {
    final counts = statusCounts;
    final raw = [
      counts['Completed']?.toDouble() ?? 0,
      counts['Processing']?.toDouble() ?? 0,
      counts['Cancelled']?.toDouble() ?? 0,
    ];
    final maxVal = raw.isEmpty ? 1.0 : raw.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(raw.length, 0.0);
    return raw.map((v) => v / maxVal).toList();
  }

  /// Status badge text color
  static Color statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF4CAF50);
      case 'Processing':
        return const Color(0xFFFF9800);
      case 'Cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  /// Status badge background color
  static Color statusBackgroundColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFFE8F5E9);
      case 'Processing':
        return const Color(0xFFFFF3E0);
      case 'Cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  RiderHistoryState copyWith({
    String? selectedFilter,
    List<RiderBooking>? allBookings,
    int? totalBookings,
    int? performanceStars,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderHistoryState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      allBookings: allBookings ?? this.allBookings,
      totalBookings: totalBookings ?? this.totalBookings,
      performanceStars: performanceStars ?? this.performanceStars,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderHistoryNotifier extends StateNotifier<RiderHistoryState> {
  RiderHistoryNotifier(this._ref) : super(const RiderHistoryState()) {
    loadHistory();
  }

  final Ref _ref;

  Future<void> loadHistory({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      AppLogger.debug('Fetching rider history from API');
      
      // Fetch completed, cancelled, and active assigned orders for history
      final ordersRaw = await ApiService.getOrders(perPage: 300);
      AppLogger.debug('Received ${ordersRaw.length} orders from API');

      final rider = _ref.read(riderAuthProvider).user;
      final packageTier = rider?.packageTier;
      final riderCommissionRate = rider?.commissionRate;

      final bookings = <RiderBooking>[];
      int completedCount = 0;
      int processingCount = 0;
      int cancelledCount = 0;

      for (var orderData in ordersRaw) {
        final orderMap = orderData as Map<String, dynamic>;
        final apiStatus = orderMap['status'] as String?;

        if (!BookingWorkflow.isHistoryEligible(orderMap)) {
          continue;
        }

        final order = RiderOrder.fromJson(orderMap);
        final proofUrls = MediaUrlUtils.parseProofImageUrls(orderMap);

        int? orderRating;
        final ratingRaw = orderMap['rating'] ??
            orderMap['customer_rating'] ??
            orderMap['review_rating'];
        if (ratingRaw != null) {
          final ratingValue = ratingRaw is num
              ? ratingRaw.toDouble()
              : double.tryParse(ratingRaw.toString()) ?? 0.0;
          orderRating = ratingValue.round().clamp(0, 5);
        }

        final booking = RiderBookingMapper.fromOrder(
          order,
          packageTier: packageTier,
          riderCommissionRate: riderCommissionRate,
          proofOfDeliveryUrls: proofUrls.isEmpty ? null : proofUrls,
          orderRating: orderRating,
        );

        if (apiStatus == 'completed') {
          completedCount++;
        } else if (apiStatus == 'cancelled') {
          cancelledCount++;
        } else if (BookingWorkflow.isActiveApiStatus(apiStatus)) {
          processingCount++;
        } else if (apiStatus == 'picked_up') {
          processingCount++;
        }

        bookings.add(booking);
      }

      bookings.sort((a, b) {
        final aId = int.tryParse(a.id) ?? 0;
        final bId = int.tryParse(b.id) ?? 0;
        return bId.compareTo(aId);
      });

      AppLogger.debug(
        'Processed ${bookings.length} history bookings '
        '(completed: $completedCount, processing: $processingCount, cancelled: $cancelledCount)',
      );

      // Get driver rating from profile API
      int stars = 0;
      try {
        final meData = await ApiService.getMe();
        final dp = (meData['user'] ?? meData)['driver_profile'] as Map<String, dynamic>?;
        final rating = dp?['rating'];
        if (rating != null) {
          final ratingValue = rating is num ? rating.toDouble() : double.tryParse(rating.toString()) ?? 0.0;
          // Convert 0-5 rating to stars (round to nearest integer)
          stars = ratingValue.round().clamp(0, 5);
          AppLogger.debug('Driver rating: $ratingValue → $stars stars');
        }
      } catch (e) {
        AppLogger.warn('Could not fetch driver rating: $e');
        // Fallback: calculate from completion rate
        if (bookings.isNotEmpty) {
          final completionRate = completedCount / bookings.length;
          if (completionRate >= 0.95) {
            stars = 5;
          } else if (completionRate >= 0.85) {
            stars = 4;
          } else if (completionRate >= 0.75) {
            stars = 3;
          } else if (completionRate >= 0.60) {
            stars = 2;
          } else {
            stars = 1;
          }
        }
      }

      state = state.copyWith(
        allBookings: bookings,
        totalBookings: bookings.length,
        performanceStars: stars,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Error loading history', e);
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> refresh() async {
    await loadHistory();
  }
}

final riderHistoryProvider =
    StateNotifierProvider<RiderHistoryNotifier, RiderHistoryState>(
      (ref) => RiderHistoryNotifier(ref),
    );
