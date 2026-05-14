import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../domain/entities/rider_booking.dart';

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
      return allBookings.where((b) => b.currentStatus == BookingStatus.complete).toList();
    } else if (selectedFilter == 'Processing') {
      return allBookings.where((b) => 
        b.currentStatus == BookingStatus.onTheWayGoing ||
        b.currentStatus == BookingStatus.inProgress ||
        b.currentStatus == BookingStatus.forDelivery
      ).toList();
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
      if (booking.currentStatus == BookingStatus.complete) {
        counts['Completed'] = counts['Completed']! + 1;
      } else if (booking.currentStatus == BookingStatus.onTheWayGoing ||
                 booking.currentStatus == BookingStatus.inProgress ||
                 booking.currentStatus == BookingStatus.forDelivery) {
        counts['Processing'] = counts['Processing']! + 1;
      } else if (booking.currentStatus == BookingStatus.cancelled) {
        counts['Cancelled'] = counts['Cancelled']! + 1;
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
  RiderHistoryNotifier() : super(const RiderHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      print('📊 Fetching rider history from API...');
      
      // Fetch completed and cancelled orders for history list
      final ordersRaw = await ApiService.getOrders(perPage: 100);
      print('📦 Received ${ordersRaw.length} orders from API');

      final bookings = <RiderBooking>[];
      int completedCount = 0;
      int cancelledCount = 0;

      for (var orderData in ordersRaw) {
        final order = orderData as Map<String, dynamic>;
        final apiStatus = order['status'] as String?;
        final orderId = order['id'];

        // Only include completed, picked_up, and cancelled orders in history
        if (apiStatus == 'completed' || apiStatus == 'cancelled' || apiStatus == 'picked_up') {
          // Map API status to BookingStatus
          BookingStatus bookingStatus;
          if (apiStatus == 'completed') {
            bookingStatus = BookingStatus.complete;
            completedCount++;
          } else if (apiStatus == 'picked_up') {
            bookingStatus = BookingStatus.onTheWayGoing;
          } else {
            // cancelled
            bookingStatus = BookingStatus.cancelled;
            cancelledCount++;
          }

          // Extract service info
          int serviceId = 2; // Default to LesRide
          if (order['service'] != null && order['service'] is Map) {
            serviceId = order['service']['id'] ?? 2;
          }

          // Determine category based on service_id
          BookingCategory category;
          String serviceName;
          if (serviceId == 3) {
            category = BookingCategory.lesEat;
            serviceName = 'LesEat';
          } else if (serviceId == 4) {
            category = BookingCategory.lesBuy;
            serviceName = 'LesBuy';
          } else {
            category = BookingCategory.lesRide;
            serviceName = 'LesRide';
          }

          // Extract addresses
          String pickupAddress = 'Pickup location';
          String dropoffAddress = 'Dropoff location';
          double? pickupLat;
          double? pickupLng;
          double? dropoffLat;
          double? dropoffLng;
          
          if (order['pickup_address'] is String) {
            pickupAddress = order['pickup_address'];
          }
          if (order['dropoff_address'] is String) {
            dropoffAddress = order['dropoff_address'];
          }
          
          // Extract coordinates
          if (order['pickup_lat'] != null) {
            pickupLat = double.tryParse(order['pickup_lat'].toString());
          }
          if (order['pickup_lng'] != null) {
            pickupLng = double.tryParse(order['pickup_lng'].toString());
          }
          if (order['dropoff_lat'] != null) {
            dropoffLat = double.tryParse(order['dropoff_lat'].toString());
          }
          if (order['dropoff_lng'] != null) {
            dropoffLng = double.tryParse(order['dropoff_lng'].toString());
          }

          // Extract customer name and phone
          String customerName = 'Customer';
          String customerPhone = '';
          if (order['customer'] != null && order['customer'] is Map) {
            customerName = order['customer']['name'] ?? 'Customer';
            customerPhone = order['customer']['phone_number'] ?? '';
          }

          // Extract fare
          final fare = order['estimated_fare'] ?? order['actual_fare'];
          String fareStr = 'PHP 0.00';
          if (fare != null) {
            try {
              final fareValue = fare is num ? fare.toDouble() : double.tryParse(fare.toString()) ?? 0.0;
              fareStr = 'PHP ${fareValue.toStringAsFixed(2)}';
            } catch (e) {
              print('⚠️ Error parsing fare for order $orderId: $e');
              fareStr = 'PHP 0.00';
            }
          }

          // Extract distance
          String distanceStr = '0.0 km';
          final distanceM = order['estimated_distance_m'];
          if (distanceM != null) {
            try {
              final distanceValue = distanceM is num ? distanceM.toDouble() : double.tryParse(distanceM.toString()) ?? 0.0;
              final distanceKm = distanceValue / 1000;
              distanceStr = '${distanceKm.toStringAsFixed(1)} km';
            } catch (e) {
              print('⚠️ Error parsing distance for order $orderId: $e');
              distanceStr = '0.0 km';
            }
          }

          // Extract proof of delivery URLs
          List<String>? proofUrls;
          if (order['proof_images'] != null) {
            final proofData = order['proof_images'];
            if (proofData is String && proofData.isNotEmpty) {
              // Single URL as string
              proofUrls = [_buildImageUrl(proofData)];
            } else if (proofData is List) {
              // Multiple URLs as array
              proofUrls = proofData
                  .map((url) => url.toString())
                  .where((url) => url.isNotEmpty)
                  .map((url) => _buildImageUrl(url))
                  .toList();
            }
          }
          if (proofUrls != null && proofUrls.isNotEmpty) {
            print('📸 Order $orderId has ${proofUrls.length} proof image(s): ${proofUrls.join(", ")}');
          } else {
            print('⚠️ Order $orderId has no proof images');
          }

          // Create RiderBooking object
          final booking = RiderBooking(
            id: orderId.toString(),
            restaurantName: serviceName,
            address: customerName,
            pickupAddress: pickupAddress,
            deliveryAddress: dropoffAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropoffLat: dropoffLat,
            dropoffLng: dropoffLng,
            distance: distanceStr,
            earnings: fareStr,
            paymentMethod: (order['payment_method'] ?? 'cash').toString().toUpperCase(),
            logoPath: 'assets/images/lesgo_logo.png', // Default logo
            category: category,
            billingAmount: fareStr,
            billingMethod: (order['payment_method'] ?? 'cash').toString().toUpperCase(),
            currentStatus: bookingStatus,
            proofOfDeliveryUrls: proofUrls,
            customerPhone: customerPhone,
          );

          bookings.add(booking);
        }
      }

      print('✅ Processed ${bookings.length} history bookings');
      print('   Completed: $completedCount, Cancelled: $cancelledCount');

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
          print('⭐ Driver rating: $ratingValue → $stars stars');
        }
      } catch (e) {
        print('⚠️ Could not fetch driver rating: $e');
        // Fallback: calculate from completion rate
        if (bookings.isNotEmpty) {
          final completionRate = completedCount / bookings.length;
          if (completionRate >= 0.95) stars = 5;
          else if (completionRate >= 0.85) stars = 4;
          else if (completionRate >= 0.75) stars = 3;
          else if (completionRate >= 0.60) stars = 2;
          else stars = 1;
        }
      }

      state = state.copyWith(
        allBookings: bookings,
        totalBookings: bookings.length,
        performanceStars: stars,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error loading history: $e');
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

  // Helper to build full image URL
  String _buildImageUrl(String path) {
    // If already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Use production API for image serving
    const baseUrl = 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud';
    return '$baseUrl/storage/$path';
  }
}

final riderHistoryProvider =
    StateNotifierProvider<RiderHistoryNotifier, RiderHistoryState>(
      (ref) => RiderHistoryNotifier(),
    );
