import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../widgets/widgets.dart';
import '../../../../domain/entities/rider_booking.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../provider/main/riderside/rider_history_provider.dart';
import '../../../provider/main/riderside/rider_location_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/booking_workflow.dart';
import '../../../../core/utils/media_url_utils.dart';
import 'map/rider_map_screen.dart';
import '../../../widgets/chat/rider_chat_button.dart';
import '../../../widgets/test/simple_map_test.dart';
import '../../../widgets/test/ultra_simple_map.dart';

class RiderBookingDetailScreen extends ConsumerStatefulWidget {
  final RiderBooking booking;
  final String? currentApiStatus; // Add this to track actual API status

  const RiderBookingDetailScreen({
    super.key,
    required this.booking,
    this.currentApiStatus,
  });

  @override
  ConsumerState<RiderBookingDetailScreen> createState() =>
      _RiderBookingDetailScreenState();
}

class _RiderBookingDetailScreenState
    extends ConsumerState<RiderBookingDetailScreen> {
  late BookingStatus _currentStatus;
  late String? _currentApiStatus;
  bool _isUpdating = false;
  bool _isFetchingStatus = false;
  final List<XFile> _selectedImages = [];
  bool _isUploadingProof = false;
  bool _showProofUpload = false;
  final ImagePicker _imagePicker = ImagePicker();
  RiderBooking? _updatedBooking; // Store updated booking with proof URLs
  GoogleMapController? _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.currentStatus;
    _currentApiStatus = widget.currentApiStatus;
    _fetchLatestStatus();
    
    // Resume order auto-refresh when entering detail screen
    ref.read(riderOrdersProvider.notifier).resumeAutoRefresh();
    print('🔄 Resumed order auto-refresh in booking detail screen');
    
    // Ensure location tracking is active for delivery tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Refresh location to ensure we have current position
        ref.read(riderLocationProvider.notifier).refreshLocation();
        print('📍 Refreshed location for booking detail tracking');
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ RiderBookingDetailScreen dispose called');
    
    // Clean up map controller
    try {
      _mapController?.dispose();
    } catch (e) {
      print('⚠️ Error disposing map controller: $e');
    }
    _mapController = null;
    
    // Don't stop location tracking or auto-refresh here - let them continue
    // for other screens. The providers will manage their own lifecycle.
    
    super.dispose();
    print('✅ RiderBookingDetailScreen disposed successfully');
  }

  // Fetch the latest status from API
  Future<void> _fetchLatestStatus() async {
    if (_isFetchingStatus) return;
    
    setState(() => _isFetchingStatus = true);
    
    try {
      final orderId = int.tryParse(widget.booking.id);
      if (orderId == null) return;
      
      print('🔄 Fetching latest status for order #$orderId');
      final orderData = await ApiService.getOrderById(orderId);
      
      if (orderData != null && mounted) {
        final apiStatus = orderData['status'] as String?;
        final serviceId = orderData['service_id'] as int? ?? 2;
        
        print('✅ Latest status from API: $apiStatus');
        
        if (apiStatus != null) {
          // Extract proof of delivery URLs
          List<String>? proofUrls;
          if (orderData['proof_images'] != null) {
            print('📸 Raw proof_images from API: ${orderData['proof_images']}');
            final proofData = orderData['proof_images'];
            if (proofData is String && proofData.isNotEmpty) {
              proofUrls = [_buildImageUrl(proofData)];
              print('📸 Parsed as single string: $proofUrls');
            } else if (proofData is List) {
              proofUrls = proofData
                  .map((url) => url.toString())
                  .where((url) => url.isNotEmpty)
                  .map((url) => _buildImageUrl(url))
                  .toList();
              print('📸 Parsed as list: $proofUrls');
            }
          } else {
            print('⚠️ No proof_images field in API response');
          }
          
          if (proofUrls != null && proofUrls.isNotEmpty) {
            print('📸 Fetched ${proofUrls.length} proof image(s): $proofUrls');
            // Update the booking with proof URLs
            final updatedBooking = RiderBooking(
              id: widget.booking.id,
              serviceId: serviceId,
              restaurantName: widget.booking.restaurantName,
              customerName: widget.booking.customerName,
              address: widget.booking.address,
              pickupAddress: widget.booking.pickupAddress,
              deliveryAddress: widget.booking.deliveryAddress,
              distance: widget.booking.distance,
              estimatedTime: widget.booking.estimatedTime,
              earnings: widget.booking.earnings,
              paymentMethod: widget.booking.paymentMethod,
              items: widget.booking.items,
              pickupLat: widget.booking.pickupLat,
              pickupLng: widget.booking.pickupLng,
              dropoffLat: widget.booking.dropoffLat,
              dropoffLng: widget.booking.dropoffLng,
              logoPath: widget.booking.logoPath,
              category: BookingWorkflow.categoryFromServiceId(serviceId),
              billingAmount: widget.booking.billingAmount,
              billingMethod: widget.booking.billingMethod,
              deliveryFee: widget.booking.deliveryFee,
              currentStatus: _mapApiStatusToBookingStatus(apiStatus, serviceId),
              proofOfDeliveryUrls: proofUrls,
              customerPhone: widget.booking.customerPhone,
            );
            
            // Replace the current booking with updated one
            setState(() {
              _currentApiStatus = apiStatus;
              _currentStatus = _mapApiStatusToBookingStatus(apiStatus, serviceId);
              _updatedBooking = updatedBooking;
            });
          } else {
            setState(() {
              _currentApiStatus = apiStatus;
              _currentStatus = _mapApiStatusToBookingStatus(apiStatus, serviceId);
            });
          }
          print('📊 Updated UI status to: ${_currentStatus.label}');
        }
      }
    } catch (e) {
      print('❌ Error fetching status: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingStatus = false);
      }
    }
  }

  BookingStatus _mapApiStatusToBookingStatus(String apiStatus, int serviceId) {
    return BookingWorkflow.mapApiStatus(apiStatus, serviceId);
  }

  Future<void> _handleStatusChange(BookingStatus newStatus) async {
    print('🎯 _handleStatusChange called with: ${newStatus.label}');
    
    if (_isUpdating) {
      print('⏳ Already updating, ignoring tap');
      return;
    }
    
    // Map BookingStatus to API status string based on service type
    String? apiStatus;
    String? statusLabel;
    
    // Get service ID from booking
    final orderId = int.tryParse(widget.booking.id);
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid order ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Fetch latest to get service_id
    await _fetchLatestStatus();
    
    // Determine service type from current status mapping
    // For LesRide: onTheWay (accepted) → onTheWayGoing (picked_up) → complete (completed)
    // For LesEat: cooking (accepted) → forPickUp (picked_up) → delivered (completed)
    // For LesBuy: toBuy (accepted) → forDelivery (picked_up) → delivered (completed)
    
    switch (newStatus) {
      // LesRide statuses
      case BookingStatus.onTheWay:
        // This is the initial accepted state for LesRide, can't manually set
        print('ℹ️ Status ${newStatus.label} is set automatically when order is accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStatus.label} status is set automatically'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
        
      case BookingStatus.onTheWayGoing:
        // LesRide: Can transition from accepted, driver_arrived_at_pickup, or in_progress → picked_up
        if (_currentApiStatus == 'accepted' || 
            _currentApiStatus == 'driver_arrived_at_pickup' || 
            _currentApiStatus == 'in_progress') {
          apiStatus = 'picked_up';
          statusLabel = 'Picked Up';
        } else if (_currentApiStatus == 'picked_up') {
          // Already at this status
          print('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order is already picked up. Tap Complete to finish.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          print('⚠️ Can only update to ${newStatus.label} from accepted, arrived, or in progress status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be accepted first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      case BookingStatus.complete:
        // LesRide: picked_up → completed (proof required at drop-off)
        if (_currentApiStatus == 'picked_up') {
          if (!_showProofUpload) {
            setState(() => _showProofUpload = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Upload proof of delivery, then tap Complete again.',
                ),
                backgroundColor: Color(0xFF5F2D82),
              ),
            );
            return;
          }
          final hasProof = _selectedImages.isNotEmpty ||
              (widget.booking.proofOfDeliveryUrls?.isNotEmpty ?? false) ||
              (_updatedBooking?.proofOfDeliveryUrls?.isNotEmpty ?? false);
          if (!hasProof) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please upload at least one proof photo first.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'completed';
          statusLabel = 'Completed';
        } else {
          print('⚠️ Can only complete from picked_up status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be picked up first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
      
      // LesEat/LesBuy statuses
      case BookingStatus.forPickUp:
      case BookingStatus.forDelivery:
        // Can transition from accepted, driver_arrived_at_pickup, or in_progress → picked_up
        if (_currentApiStatus == 'accepted' || 
            _currentApiStatus == 'driver_arrived_at_pickup' || 
            _currentApiStatus == 'in_progress') {
          apiStatus = 'picked_up';
          statusLabel = 'Picked Up';
        } else if (_currentApiStatus == 'picked_up') {
          // Already at this status
          print('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order is already picked up. Tap Delivered/Complete to finish.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          print('⚠️ Can only update to ${newStatus.label} from accepted, arrived, or in progress status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be accepted first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      case BookingStatus.delivered:
        // picked_up → completed (proof required at drop-off)
        if (_currentApiStatus == 'picked_up') {
          if (!_showProofUpload) {
            setState(() => _showProofUpload = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Upload proof of delivery, then tap Complete again.',
                ),
                backgroundColor: Color(0xFF5F2D82),
              ),
            );
            return;
          }
          final hasProof = _selectedImages.isNotEmpty ||
              (widget.booking.proofOfDeliveryUrls?.isNotEmpty ?? false) ||
              (_updatedBooking?.proofOfDeliveryUrls?.isNotEmpty ?? false);
          if (!hasProof) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please upload at least one proof photo first.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'completed';
          statusLabel = 'Completed';
        } else {
          print('⚠️ Can only deliver from picked_up status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be picked up first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      // New statuses for driver workflow
      case BookingStatus.driverHasArrived:
        // accepted → driver_arrived_at_pickup
        if (_currentApiStatus == 'accepted') {
          apiStatus = 'driver_arrived_at_pickup';
          statusLabel = 'Driver Has Arrived';
        } else if (_currentApiStatus == 'picked_up') {
          // Already past this status
          print('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order has already been picked up. This status was skipped.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          print('⚠️ Can only mark arrival from accepted status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be accepted first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      case BookingStatus.inProgress:
        // Can transition from: accepted, driver_arrived_at_pickup
        // Cannot transition from: picked_up (already past this status)
        if (_currentApiStatus == 'picked_up') {
          print('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order has already been picked up. Cannot go back to In Progress.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else if (_currentApiStatus == 'driver_arrived_at_pickup' || _currentApiStatus == 'accepted') {
          apiStatus = 'in_progress';
          statusLabel = 'In Progress';
        } else {
          print('⚠️ Can only mark in progress from accepted or arrived status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order must be accepted or driver must have arrived first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      // Informational statuses
      case BookingStatus.cooking:
      case BookingStatus.toBuy:
      case BookingStatus.pending:
      case BookingStatus.cancelled:
        print('ℹ️ Status ${newStatus.label} is informational only');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStatus.label} status is set automatically'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    print('📡 Will update to API status: $apiStatus');
    
    // Check if we're trying to update to the same status
    if (_currentApiStatus != null && _currentApiStatus == apiStatus) {
      print('⚠️ Status is already $apiStatus, showing warning');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order is already $statusLabel. ${apiStatus == "picked_up" ? "Tap Complete to finish the order." : ""}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Update Status',
      message: 'Are you sure you want to update the order status to $statusLabel?',
      confirmText: 'Update',
      cancelText: 'Cancel',
    );
    
    if (!confirmed) {
      print('❌ User cancelled status update');
      return;
    }

    print('✅ Status is different ($_currentApiStatus → $apiStatus), proceeding with update');
    setState(() => _isUpdating = true);

    try {
      bool success = false;
      if (apiStatus == 'driver_arrived_at_pickup') {
        success = await ref.read(riderOrdersProvider.notifier).markDriverArrived(orderId);
      } else if (apiStatus == 'in_progress') {
        success = await ref.read(riderOrdersProvider.notifier).markInProgress(orderId);
      } else if (apiStatus == 'picked_up') {
        success = await ref.read(riderOrdersProvider.notifier).markPickedUp(orderId);
      } else if (apiStatus == 'completed') {
        success = await ref.read(riderOrdersProvider.notifier).markCompleted(orderId);
      }

      if (success && mounted && apiStatus != null) {
        setState(() {
          _currentApiStatus = apiStatus;
          _currentStatus = _mapApiStatusToBookingStatus(
            apiStatus!,
            widget.booking.serviceId,
          );
          if (apiStatus != 'picked_up') {
            _showProofUpload = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to $statusLabel'),
            backgroundColor: Colors.green,
          ),
        );
        
        // If completed, go back to main screen and refresh history
        if (apiStatus == 'completed') {
          print('🎯 Order completed! Starting refresh sequence...');
          
          // Multiple refresh attempts with delays to ensure backend has saved
          await Future.delayed(const Duration(milliseconds: 300));
          print('🔄 First history refresh...');
          await ref.read(riderHistoryProvider.notifier).refresh();
          
          await Future.delayed(const Duration(milliseconds: 300));
          print('🔄 Second history refresh...');
          await ref.read(riderHistoryProvider.notifier).refresh();
          
          await Future.delayed(const Duration(milliseconds: 400));
          print('✅ Refresh sequence complete, closing screen...');
          
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else if (mounted) {
        final error = ref.read(riderOrdersProvider).error ?? 'Failed to update status';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF5F2D82),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  String _buildImageUrl(String path) {
    return MediaUrlUtils.resolve(path) ?? path;
  }

  // Pick images from gallery or camera
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          // Limit to 5 images
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 images allowed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(photo);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 images allowed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Upload proof images
  Future<void> _uploadProofImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Upload Proof',
      message: 'Upload ${_selectedImages.length} image(s) as proof of delivery/completion?',
      confirmText: 'Upload',
      cancelText: 'Cancel',
    );

    if (!confirmed) return;

    setState(() => _isUploadingProof = true);

    try {
      final orderId = int.tryParse(widget.booking.id);
      if (orderId == null) {
        throw Exception('Invalid order ID');
      }

      // Use different upload method for web vs mobile
      if (kIsWeb) {
        await ApiService.uploadProofImagesWeb(orderId, _selectedImages);
      } else {
        final imagePaths = _selectedImages.map((img) => img.path).toList();
        await ApiService.uploadProofImages(orderId, imagePaths);
      }

      if (mounted) {
        setState(() {
          _selectedImages.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Proof images uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() => _showProofUpload = true);

        // Refresh order data
        print('🔄 Refreshing order data after proof upload...');
        await _fetchLatestStatus();
        
        // Refresh the orders list in the provider
        print('🔄 Refreshing orders list...');
        await ref.read(riderOrdersProvider.notifier).loadOrders(silent: true);
        
        // If order is completed, also refresh history
        if (_currentApiStatus == 'completed') {
          print('🔄 Order is completed, refreshing history...');
          await ref.read(riderHistoryProvider.notifier).refresh();
          print('✅ History refreshed');
        }
      }
    } catch (e) {
      print('Error uploading proof: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload proof: ${ApiService.extractError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingProof = false);
      }
    }
  }

  bool _shouldShowRouteMap() {
    final status = _currentApiStatus?.toLowerCase();
    if (status == null) return false;
    if (_showProofUpload) return false;
    return status == 'accepted' ||
        status == 'driver_arrived_at_pickup' ||
        status == 'in_progress' ||
        status == 'picked_up';
  }

  bool _shouldShowProofUpload() {
    if (_showProofUpload && _currentApiStatus == 'picked_up') return true;
    return _currentApiStatus == 'completed';
  }

  // Build dynamic content based on current status
  Widget _buildStatusContent(BuildContext context, RiderLocationState locationState) {
    print('🎨 Building status content for: ${_currentStatus.label} (API: $_currentApiStatus)');
    
    if (_shouldShowProofUpload()) {
      print('📤 Showing upload section');
      return Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          children: [
            // Selected Images Grid
            if (_selectedImages.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  image.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Image.file(
                                  File(image.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            ],
            
            // Upload Area
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: const Color(0xFF5F2D82).withOpacity(0.5),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  Text(
                    'Upload Proof of Delivery',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Take photos or select from gallery',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    'Max 5 images • JPG, PNG • Max 5MB each',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!kIsWeb) ...[
                        ElevatedButton.icon(
                          onPressed: _isUploadingProof ? null : _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5F2D82),
                            side: BorderSide(color: const Color(0xFF5F2D82)),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.spacing(context, 20),
                              vertical: ResponsiveUtils.spacing(context, 12),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isUploadingProof ? null : _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2D82),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 20),
                            vertical: ResponsiveUtils.spacing(context, 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Upload Button
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingProof ? null : _uploadProofImages,
                  icon: _isUploadingProof
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploadingProof ? 'Uploading...' : 'Upload ${_selectedImages.length} Image(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    if (_shouldShowRouteMap()) {
      print('🗺️ Showing route map for API status: $_currentApiStatus');
      
      return Container(
        height: ResponsiveUtils.imageHeight(context, 300),
        margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // REAL GOOGLE MAPS
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.booking.pickupLat != null && widget.booking.pickupLng != null
                      ? LatLng(widget.booking.pickupLat!, widget.booking.pickupLng!)
                      : const LatLng(8.4542, 124.6319), // Default to Cagayan de Oro
                  zoom: 13,
                ),
                
                // Enable all interactive gestures
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                
                // Disable built-in controls
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                
                // Enable location
                myLocationEnabled: true,
                
                // Add markers and polylines
                markers: _buildMapMarkers(locationState),
                polylines: _buildMapPolylines(locationState),
                
                onMapCreated: (controller) {
                  if (mounted) {
                    _mapController = controller;
                    _mapReady = true;
                    
                    // Fit bounds to show pickup and dropoff
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _fitBounds();
                        }
                      });
                    });
                    
                    print('🗺️ Booking detail Google Maps created successfully');
                  }
                },
                
                onTap: (LatLng position) {
                  print('🗺️ Booking detail map tapped at: ${position.latitude}, ${position.longitude}');
                },
              ),
              
              // Live tracking indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE TRACKING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tap to expand
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderMapScreen(
                          orderId: int.parse(widget.booking.id),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'View Full Map',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default: return empty container
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // Watch location provider to ensure tracking continues
    final locationState = ref.watch(riderLocationProvider);
    
    // Watch orders provider for real-time updates
    final ordersState = ref.watch(riderOrdersProvider);
    
    // Listen for order updates to refresh status
    ref.listen<RiderOrdersState>(riderOrdersProvider, (previous, next) {
      if (previous != next) {
        // Check if our current order has been updated
        final currentOrderId = int.tryParse(widget.booking.id);
        if (currentOrderId != null) {
          final updatedOrder = next.activeOrder;
          if (updatedOrder != null && updatedOrder.id == currentOrderId) {
            print('🔄 Order #${currentOrderId} status updated: ${updatedOrder.status}');
            // Update local status to match API
            if (mounted && updatedOrder.status != _currentApiStatus) {
              setState(() {
                _currentApiStatus = updatedOrder.status;
                _currentStatus = _mapApiStatusToBookingStatus(
                  updatedOrder.status,
                  updatedOrder.serviceId,
                );
                if (updatedOrder.status != 'picked_up') {
                  _showProofUpload = false;
                }
              });
            }
          }
        }
      }
    });
    
    // Log location tracking status
    if (locationState.hasLocation) {
      print('📍 Location tracking active: ${locationState.latitude}, ${locationState.longitude}');
    } else if (locationState.error != null) {
      print('❌ Location tracking error: ${locationState.error}');
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with refresh button
                Stack(
                  children: [
                    const HomeHeader(showBackButton: true),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: IconButton(
                        onPressed: _isFetchingStatus ? null : _fetchLatestStatus,
                        icon: _isFetchingStatus
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF5F2D82),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: const Color(0xFF5F2D82),
                              ),
                        tooltip: 'Refresh Status',
                      ),
                    ),
                  ],
                ),
                // Banner
                SizedBox(
                  height: ResponsiveUtils.imageHeight(context, 120),
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/images/booking/banner.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RiderBookingDetailInfo(booking: _updatedBooking ?? widget.booking),
                        Divider(color: Colors.grey.shade200, height: 1),
                        
                        // Dynamic content based on status
                        _buildStatusContent(context, locationState),
                        
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.horizontalPadding(context),
                            vertical: ResponsiveUtils.spacing(context, 16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 15),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D2D2D),
                                    ),
                                  ),
                                  if (_currentApiStatus != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5F2D82).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _currentApiStatus!.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: ResponsiveUtils.fontSize(context, 11),
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF5F2D82),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                              RiderBookingNextActions(
                                category: widget.booking.category,
                                apiStatus: _currentApiStatus,
                                isUpdating: _isUpdating,
                                awaitingProof: _showProofUpload,
                                onAction:
                                    _isUpdating ? null : _handleStatusChange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isUpdating)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingRiderChatButton(
        orderId: int.tryParse(widget.booking.id) ?? 0,
        customerName: widget.booking.customerName,
      ),
    );
  }

  // Build map markers for pickup and dropoff and driver
  Set<Marker> _buildMapMarkers(RiderLocationState locationState) {
    final markers = <Marker>{};
    
    // Driver marker
    if (locationState.hasLocation) {
      markers.add(Marker(
        markerId: const MarkerId('driver_location'),
        position: LatLng(locationState.latitude!, locationState.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 2,
      ));
    }
    
    // Pickup marker
    if (widget.booking.pickupLat != null && widget.booking.pickupLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.booking.pickupLat!,
          widget.booking.pickupLng!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));
    }
    
    // Dropoff marker
    if (widget.booking.dropoffLat != null && widget.booking.dropoffLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.booking.dropoffLat!,
          widget.booking.dropoffLng!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ));
    }
    
    return markers;
  }

  // Build polyline between pickup and dropoff and driver
  Set<Polyline> _buildMapPolylines(RiderLocationState locationState) {
    final polylines = <Polyline>{};
    
    if (widget.booking.pickupLat != null && 
        widget.booking.pickupLng != null &&
        widget.booking.dropoffLat != null && 
        widget.booking.dropoffLng != null) {
        
      // Draw route between pickup and dropoff
      polylines.add(Polyline(
        polylineId: const PolylineId('route_pickup_dropoff'),
        points: [
          LatLng(widget.booking.pickupLat!, widget.booking.pickupLng!),
          LatLng(widget.booking.dropoffLat!, widget.booking.dropoffLng!),
        ],
        color: const Color(0xFF5F2D82),
        width: 4,
      ));
      
      // If driver location is available, draw a line from driver to current destination
      if (locationState.hasLocation) {
        final driverLoc = LatLng(locationState.latitude!, locationState.longitude!);
        LatLng destLoc;
        
        final enRouteToPickup = _currentApiStatus == 'accepted' ||
            _currentApiStatus == 'driver_arrived_at_pickup' ||
            _currentApiStatus == 'in_progress';
        destLoc = enRouteToPickup
            ? LatLng(widget.booking.pickupLat!, widget.booking.pickupLng!)
            : LatLng(widget.booking.dropoffLat!, widget.booking.dropoffLng!);
        
        polylines.add(Polyline(
          polylineId: const PolylineId('route_driver_to_dest'),
          points: [driverLoc, destLoc],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ));
      }
    }
    
    return polylines;
  }

  // Fit map bounds to show all markers
  void _fitBounds() {
    if (!_mapReady || _mapController == null) return;
    
    if (widget.booking.pickupLat != null && 
        widget.booking.pickupLng != null &&
        widget.booking.dropoffLat != null &&
        widget.booking.dropoffLng != null) {
      
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(widget.booking.pickupLat!, widget.booking.dropoffLat!),
          math.min(widget.booking.pickupLng!, widget.booking.dropoffLng!),
        ),
        northeast: LatLng(
          math.max(widget.booking.pickupLat!, widget.booking.dropoffLat!),
          math.max(widget.booking.pickupLng!, widget.booking.dropoffLng!),
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }
}
