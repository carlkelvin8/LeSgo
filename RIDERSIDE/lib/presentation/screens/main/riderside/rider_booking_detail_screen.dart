import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show File;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../widgets/widgets.dart';
import '../../../../domain/entities/rider_booking.dart';
import '../../../../core/utils/receipt_generator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../provider/main/riderside/rider_history_provider.dart';
import '../../../provider/main/riderside/rider_location_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/booking_workflow.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/rider_booking_mapper.dart';
import '../../../../core/utils/lesbuy_manual_delivery_utils.dart';
import '../../../../core/utils/offline_feedback_utils.dart';
import '../../../../core/utils/rider_order_ops_utils.dart';
import '../../../widgets/chat/rider_chat_button.dart';
import '../../../widgets/main/riderside/bookings/rider_booking_confirm_dialog.dart';
import '../../../widgets/main/riderside/bookings/rider_cancel_order_dialog.dart';
import '../../../widgets/main/riderside/bookings/rider_booking_detail_map_section.dart';
import '../../../widgets/main/riderside/bookings/rider_booking_proof_upload_section.dart';
import '../../../widgets/main/riderside/bookings/rider_cod_confirm_dialog.dart';
import '../../../widgets/main/riderside/bookings/rider_customer_rating_dialog.dart';
import '../../../../core/utils/rider_payment_utils.dart';
import '../../../../core/utils/app_localization.dart';

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
    extends ConsumerState<RiderBookingDetailScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    // Order list polling is handled by riderOrdersProvider when on duty.
    _fetchLatestStatus();
  }

  late BookingStatus _currentStatus;
  late String? _currentApiStatus;
  bool _isUpdating = false;
  bool _isFetchingStatus = false;
  bool _isHandlingStatusChange = false; // NEW: Prevent concurrent status changes
  final List<XFile> _selectedImages = [];
  bool _isUploadingProof = false;
  bool _showProofUpload = false;
  bool _showPickupProof = false; // Photo required before marking picked_up
  final ImagePicker _imagePicker = ImagePicker();
  RiderBooking? _updatedBooking; // Store updated booking with proof URLs
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.currentStatus;
    _currentApiStatus = widget.currentApiStatus;
    _fetchLatestStatus();
    
    // Resume order auto-refresh when entering detail screen
    ref.read(riderOrdersProvider.notifier).resumeAutoRefresh();
    AppLogger.debug('🔄 Resumed order auto-refresh in booking detail screen');
    
    // Ensure location tracking is active for delivery tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Refresh location to ensure we have current position
        ref.read(riderLocationProvider.notifier).refreshLocation();
        AppLogger.debug('📍 Refreshed location for booking detail tracking');
      }
    });
  }

  @override
  void dispose() {
    AppLogger.debug('🗑️ RiderBookingDetailScreen dispose called');
    
    // Clean up map controller carefully
    try {
      // First, remove any listeners to prevent them firing after dispose
      if (_mapController != null) {
        // Cancel any pending marker/polyline operations
        _mapController!.dispose();
        AppLogger.debug('✅ Map controller disposed successfully');
      }
    } catch (e) {
      AppLogger.error('Error disposing map controller', e);
    } finally {
      _mapController = null;
    }
    
    // Don't stop location tracking or auto-refresh here - let them continue
    // for other screens. The providers will manage their own lifecycle.
    
    super.dispose();
    AppLogger.debug('✅ RiderBookingDetailScreen disposed successfully');
  }

  // Fetch the latest status from API
  Future<void> _fetchLatestStatus() async {
    if (_isFetchingStatus || _isHandlingStatusChange) return;
    
    setState(() => _isFetchingStatus = true);
    
    try {
      final orderId = int.tryParse(widget.booking.id);
      if (orderId == null) return;
      
      AppLogger.debug('🔄 Fetching latest status for order #$orderId');
      final orderData = await ApiService.getOrderById(orderId);
      
      // Check if widget is still mounted and no status change is in progress
      if (orderData == null || !mounted || _isHandlingStatusChange) {
        return;
      }
      
      final apiStatus = orderData['status'] as String?;
      final order = RiderOrder.fromJson(orderData);
      final proofUrls = MediaUrlUtils.parseProofImageUrls(orderData);

      AppLogger.debug('✅ Latest status from API: $apiStatus');
      if (proofUrls.isNotEmpty) {
        AppLogger.debug('📸 Fetched ${proofUrls.length} proof image(s): $proofUrls');
      }

      if (apiStatus != null && mounted && !_isHandlingStatusChange) {
        final refreshedBooking = RiderBookingMapper.fromOrder(
          order,
          proofOfDeliveryUrls:
              proofUrls.isEmpty ? widget.booking.proofOfDeliveryUrls : proofUrls,
        );

        setState(() {
          _currentApiStatus = apiStatus;
          _currentStatus = _mapApiStatusToBookingStatus(
            apiStatus,
            order.serviceId,
          );
          _updatedBooking = refreshedBooking;
        });
        AppLogger.debug('📊 Updated UI status to: ${_currentStatus.label}');
      }
    } catch (e) {
      AppLogger.error('Error fetching status', e);
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
    AppLogger.debug('🎯 _handleStatusChange called with: ${newStatus.label}');
    
    // Prevent concurrent status changes with a double guard
    if (_isUpdating || _isHandlingStatusChange) {
      AppLogger.debug('⏳ Already updating, ignoring tap');
      return;
    }
    
    setState(() => _isHandlingStatusChange = true);
    
    try {
      final lang = ref.read(appLanguageProvider);
    
      // Get service ID from booking
      final orderId = int.tryParse(widget.booking.id);
      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('invalid_order_id', lang)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Fetch latest to get service_id
      await _fetchLatestStatus();
      
      // Map BookingStatus to API status string based on service type
      String? apiStatus;
      String? statusLabel;

      switch (newStatus) {
      case BookingStatus.onTheWayGoing:
        // LesRide: Can transition from accepted, driver_arrived_at_pickup, or in_progress → picked_up
        if (_currentApiStatus == 'accepted' || 
            _currentApiStatus == 'driver_arrived_at_pickup' || 
            _currentApiStatus == 'in_progress') {
          // Require photo proof before marking as picked up
          if (!_showPickupProof) {
            setState(() {
              _showPickupProof = true;
              _selectedImages.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Take a photo of the pickup, then tap "Picked Up" again.'),
                backgroundColor: Color(0xFF5F2D82),
              ),
            );
            return;
          }
          final hasProof = _selectedImages.isNotEmpty;
          if (!hasProof) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalization.translate('minimum_1_photo_required', lang)),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'picked_up';
          statusLabel = 'Picked Up';
        } else if (_currentApiStatus == 'picked_up') {
          // Already at this status
          AppLogger.debug('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_already_picked_up_tap', lang)),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          AppLogger.warn('Can only update to ${newStatus.label} from accepted, arrived, or in progress status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_accepted', lang)),
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
              SnackBar(
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
              SnackBar(
                content: Text(AppLocalization.translate('minimum_1_photo_required', lang)),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'completed';
          statusLabel = 'Completed';
        } else {
          AppLogger.warn('Can only complete from picked_up status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_picked_up_first', lang)),
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
        // Can transition from accepted, ready_for_pickup, driver_arrived_at_pickup, or in_progress → picked_up
        if (_currentApiStatus == 'accepted' ||
            _currentApiStatus == 'ready_for_pickup' ||
            _currentApiStatus == 'driver_arrived_at_pickup' ||
            _currentApiStatus == 'in_progress') {
          // Require photo proof before marking as picked up
          if (!_showPickupProof) {
            setState(() {
              _showPickupProof = true;
              _selectedImages.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Take a photo of the pickup, then tap "Picked Up" again.'),
                backgroundColor: Color(0xFF5F2D82),
              ),
            );
            return;
          }
          final hasProof = _selectedImages.isNotEmpty;
          if (!hasProof) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalization.translate('minimum_1_photo_required', lang)),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'picked_up';
          statusLabel = 'Picked Up';
        } else if (_currentApiStatus == 'picked_up') {
          // Already at this status
          AppLogger.debug('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_already_picked_up_tap_delivered', lang)),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          AppLogger.warn('Can only update to ${newStatus.label} from accepted, arrived, or in progress status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_accepted', lang)),
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
              SnackBar(
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
              SnackBar(
                content: Text(AppLocalization.translate('minimum_1_photo_required', lang)),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          apiStatus = 'completed';
          statusLabel = 'Completed';
        } else {
          AppLogger.warn('Can only deliver from picked_up status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_picked_up_first', lang)),
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
        if (_currentApiStatus == 'accepted' ||
            _currentApiStatus == 'ready_for_pickup') {
          apiStatus = 'driver_arrived_at_pickup';
          statusLabel = 'Driver Has Arrived';
        } else if (_currentApiStatus == 'picked_up') {
          // Already past this status
          AppLogger.debug('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_already_picked_up_skip', lang)),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else {
          AppLogger.warn('Can only mark arrival from accepted status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_accepted', lang)),
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
          AppLogger.debug('ℹ️ Order is already picked up');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_already_picked_up', lang)),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        } else if (_currentApiStatus == 'driver_arrived_at_pickup' ||
            _currentApiStatus == 'accepted' ||
            _currentApiStatus == 'ready_for_pickup') {
          apiStatus = 'in_progress';
          statusLabel = 'In Progress';
        } else {
          AppLogger.warn('Can only mark in progress from accepted or arrived status');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalization.translate('order_must_be_accepted_or_arrived', lang)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        break;
        
      // Informational statuses
      case BookingStatus.onTheWay:
      case BookingStatus.cooking:
      case BookingStatus.toBuy:
      case BookingStatus.pending:
      case BookingStatus.cancelled:
        AppLogger.debug('ℹ️ Status ${newStatus.label} is informational only');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('status_set_automatically', lang).replaceAll('{{status}}', newStatus.label)),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    final targetStatus = apiStatus;
    final targetLabel = statusLabel;

    AppLogger.debug('📡 Will update to API status: $targetStatus');
    
    // Check if we're trying to update to the same status
    if (_currentApiStatus != null && _currentApiStatus == targetStatus) {
      AppLogger.warn('Status is already $targetStatus, showing warning');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order is already $targetLabel. ${targetStatus == "picked_up" ? "Tap Complete to finish the order." : ""}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Show confirmation dialog
    if (targetStatus == 'completed') {
      final booking = _updatedBooking ?? widget.booking;
      if (RiderPaymentUtils.isCashPayment(booking.paymentMethod)) {
        final codOk = await showRiderCodConfirmDialog(
          context,
          amountLabel: booking.billingAmount,
        );
        if (!codOk) return;
      }
    }

    final confirmed = await showRiderBookingConfirmDialog(
      context: context,
      title: 'Update Status',
      message: 'Are you sure you want to update the order status to $targetLabel?',
      confirmText: 'Update',
      cancelText: AppLocalization.translate('cancel', lang),
    );
    
    if (!confirmed) {
      AppLogger.error('❌ User cancelled status update');
      return;
    }

    AppLogger.debug('✅ Status is different ($_currentApiStatus → $targetStatus), proceeding with update');
    setState(() => _isUpdating = true);

    try {
      bool success = false;
      if (targetStatus == 'driver_arrived_at_pickup') {
        success = await ref.read(riderOrdersProvider.notifier).markDriverArrived(orderId);
      } else if (targetStatus == 'in_progress') {
        success = await ref.read(riderOrdersProvider.notifier).markInProgress(orderId);
      } else if (targetStatus == 'picked_up') {
        success = await ref.read(riderOrdersProvider.notifier).markPickedUp(orderId);
      } else if (targetStatus == 'completed') {
        success = await ref.read(riderOrdersProvider.notifier).markCompleted(orderId);
      }

      if (success && mounted) {
        setState(() {
          _currentApiStatus = targetStatus;
          _currentStatus = _mapApiStatusToBookingStatus(
            targetStatus,
            widget.booking.serviceId,
          );
          if (targetStatus == 'picked_up') {
            _showPickupProof = false;
            _selectedImages.clear();
          }
          if (targetStatus != 'picked_up') {
            _showProofUpload = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${AppLocalization.translate('status_updated_to', lang).replaceAll('{{status}}', targetLabel)}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // If completed, go back to main screen and refresh history
        if (targetStatus == 'completed') {
          AppLogger.debug('🎯 Order completed! Starting refresh sequence...');
          
          await Future.delayed(const Duration(milliseconds: 300));
          await ref.read(riderHistoryProvider.notifier).refresh();
          
          if (mounted) {
            await showRiderCustomerRatingDialog(
              context,
              orderId: orderId,
              customerName: widget.booking.customerName,
            );
          }
          
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else if (mounted) {
        showApiErrorSnackBar(
          context,
          ref.read(riderOrdersProvider).error,
          fallback: 'Failed to update status',
        );
      }
    } catch (e) {
      if (mounted) {
        showApiErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _isHandlingStatusChange = false;
        });
      } else {
        _isHandlingStatusChange = false;
      }
    }
  } catch (e) {
    AppLogger.error('Status change error', e);
    if (mounted) {
      showApiErrorSnackBar(context, e);
    }
  } finally {
    _isHandlingStatusChange = false;
  }
}  // end _handleStatusChange

  // Request camera permission
  Future<bool> _requestCameraPermission() async {
    final lang = ref.read(appLanguageProvider);
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('camera_permission_required', lang)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('camera_permission_denied', lang)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return true;
  }

  // Pick images from gallery or camera
  Future<void> _pickImages() async {
    final lang = ref.read(appLanguageProvider);
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // Validate file sizes before adding
        final validImages = <XFile>[];
        for (final image in images) {
          try {
            final file = File(image.path);
            final sizeInMb = file.lengthSync() / (1024 * 1024);
            if (sizeInMb > 25) {
              AppLogger.warn('Image too large: ${sizeInMb.toStringAsFixed(2)}MB, skipping');
              continue;
            }
            validImages.add(image);
          } catch (e) {
            AppLogger.error('Error checking image size', e);
          }
        }
        
        if (validImages.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalization.translate('all_images_too_large', lang)),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImages.addAll(validImages);
          // Limit to 5 images
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalization.translate('maximum_5_images', lang)),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error picking images', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('failed_to_pick_images', lang).replaceAll('{{error}}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    final lang = ref.read(appLanguageProvider);
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) return;
      
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (photo != null) {
        // Validate file size
        try {
          final file = File(photo.path);
          final sizeInMb = file.lengthSync() / (1024 * 1024);
          if (sizeInMb > 25) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalization.translate('image_too_large', lang).replaceAll('{{name}}', '${sizeInMb.toStringAsFixed(2)}MB')),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        } catch (e) {
          AppLogger.error('Error checking photo size', e);
        }
        
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(photo);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalization.translate('maximum_5_images', lang)),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error taking photo', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('failed_to_take_photo', lang).replaceAll('{{error}}', e.toString())),
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

  void _shareReceipt() {
    final booking = _updatedBooking ?? widget.booking;
    final orderId = int.tryParse(booking.id) ?? 0;
    final earningsStr = booking.earnings?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
    final earnings = double.tryParse(earningsStr) ?? 0;

    final receipt = ReceiptGenerator.generateEarningReceipt(
      orderId: orderId,
      serviceName: booking.restaurantName,
      earnings: earnings,
      completedAt: DateTime.now(),
      pickupAddress: booking.pickupAddress,
      dropoffAddress: booking.deliveryAddress,
    );

    ShareUtils.saveAndShareReceipt(
      context,
      receipt,
      'LeSGo_Receipt_Order_$orderId',
    );
  }

  Future<void> _handleCancelOrder() async {
    final lang = ref.read(appLanguageProvider);
    if (_isUpdating) return;

    final orderId = int.tryParse(widget.booking.id);
    if (orderId == null) return;
    if (!RiderOrderOpsUtils.canCancel(_currentApiStatus)) return;

    final reason = await showRiderCancelOrderDialog(context);
    if (reason == null || !mounted) return;

    setState(() => _isUpdating = true);

    final success =
        await ref.read(riderOrdersProvider.notifier).cancelOrder(orderId, reason);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.translate('order_cancelled', lang)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      showApiErrorSnackBar(
        context,
        ref.read(riderOrdersProvider).error,
        fallback: 'Failed to cancel order',
      );
    }
  }

  // Upload proof images
  Future<void> _uploadProofImages() async {
    final lang = ref.read(appLanguageProvider);
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.translate('please_select_at_least_one_image', lang)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showRiderBookingConfirmDialog(
      context: context,
      title: 'Upload Proof',
      message: 'Upload ${_selectedImages.length} image(s) as proof of delivery/completion?',
      confirmText: 'Upload',
      cancelText: AppLocalization.translate('cancel', lang),
    );

    if (!confirmed) return;

    setState(() => _isUploadingProof = true);

    try {
      final orderId = int.tryParse(widget.booking.id);
      if (orderId == null) {
        throw Exception(AppLocalization.translate('invalid_order_id', lang));
      }

      final orderData = await ApiService.getOrderById(orderId);
      final existingProofs =
          MediaUrlUtils.parseProofImageUrls(orderData ?? {});
      final sendPickupLocation = orderData != null &&
          LesbuyManualDeliveryUtils.needsFirstItemPickupLocation(orderData) &&
          existingProofs.isEmpty;

      double? uploadLat;
      double? uploadLng;
      if (sendPickupLocation) {
        await ref.read(riderLocationProvider.notifier).refreshLocation();
        final loc = ref.read(riderLocationProvider);
        uploadLat = loc.latitude;
        uploadLng = loc.longitude;
        if (uploadLat == null || uploadLng == null) {
          throw Exception(
            'Turn on location so we can calculate delivery fee from the shop.',
          );
        }
      }

      // Use different upload method for web vs mobile
      if (kIsWeb) {
        await ApiService.uploadProofImagesWeb(
          orderId,
          _selectedImages,
          latitude: uploadLat,
          longitude: uploadLng,
          firstItemProof: sendPickupLocation,
        );
      } else {
        final imagePaths = _selectedImages.map((img) => img.path).toList();
        await ApiService.uploadProofImages(
          orderId,
          imagePaths,
          latitude: uploadLat,
          longitude: uploadLng,
          firstItemProof: sendPickupLocation,
        );
      }

      if (mounted) {
        setState(() {
          _selectedImages.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${AppLocalization.translate('proof_images_uploaded', lang)}'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() => _showProofUpload = true);

        // Refresh order data
        AppLogger.debug('🔄 Refreshing order data after proof upload...');
        await _fetchLatestStatus();
        
        // Refresh the orders list in the provider
        AppLogger.debug('🔄 Refreshing orders list...');
        await ref.read(riderOrdersProvider.notifier).loadOrders(silent: true);
        
        // If order is completed, also refresh history
        if (_currentApiStatus == 'completed') {
          AppLogger.debug('🔄 Order is completed, refreshing history...');
          await ref.read(riderHistoryProvider.notifier).refresh();
          AppLogger.debug('✅ History refreshed');
        }
      }
    } catch (e) {
      AppLogger.error('Error uploading proof', e);
      if (mounted) {
        showApiErrorSnackBar(context, e, fallback: 'Failed to upload proof');
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
        status == 'ready_for_pickup' ||
        status == 'driver_arrived_at_pickup' ||
        status == 'in_progress' ||
        status == 'picked_up';
  }

  bool _shouldShowProofUpload() {
    if (_showPickupProof) return true; // Show proof upload for pickup photo
    if (_showProofUpload && _currentApiStatus == 'picked_up') return true;
    return _currentApiStatus == 'completed';
  }

  // Build dynamic content based on current status
  Widget _buildStatusContent(BuildContext context, RiderLocationState locationState) {
    AppLogger.debug('🎨 Building status content for: ${_currentStatus.label} (API: $_currentApiStatus)');
    
    if (_shouldShowProofUpload()) {
      return RiderBookingProofUploadSection(
        selectedImages: _selectedImages,
        isUploading: _isUploadingProof,
        onPickImages: _pickImages,
        onTakePhoto: _takePhoto,
        onRemoveImage: _removeImage,
        onUpload: _uploadProofImages,
      );
    }

    if (_shouldShowRouteMap()) {
      return RiderBookingDetailMapSection(
        booking: widget.booking,
        locationState: locationState,
        currentApiStatus: _currentApiStatus,
        onMapCreated: (controller) {
          if (!mounted) return;
          _mapController = controller;
        },
        onFitBounds: () {
          if (!mounted) return;
          RiderBookingDetailMapSection.fitBounds(
            controller: _mapController,
            booking: widget.booking,
            locationState: locationState,
          );
        },
      );
    }

    // Default: return empty container
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // Watch location provider to ensure tracking continues
    final locationState = ref.watch(riderLocationProvider);
    final lang = ref.watch(appLanguageProvider);
    
    // Listen for order updates to refresh status
    ref.listen<RiderOrdersState>(riderOrdersProvider, (previous, next) {
      if (!mounted) return;

      final currentOrderId = int.tryParse(widget.booking.id);
      if (currentOrderId == null) return;

      RiderOrder? updatedOrder;
      for (final order in next.activeOrders) {
        if (order.id == currentOrderId) {
          updatedOrder = order;
          break;
        }
      }
      updatedOrder ??=
          next.activeOrder?.id == currentOrderId ? next.activeOrder : null;

      if (updatedOrder != null &&
          updatedOrder.status != _currentApiStatus) {
        setState(() {
          _currentApiStatus = updatedOrder!.status;
          _currentStatus = _mapApiStatusToBookingStatus(
            updatedOrder.status,
            updatedOrder.serviceId,
          );
          if (updatedOrder.status != 'picked_up') {
            _showProofUpload = false;
          }
        });
      }
    });
    
    // Log location tracking status
    if (locationState.hasLocation) {
      AppLogger.debug('📍 Location tracking active: ${locationState.latitude}, ${locationState.longitude}');
    } else if (locationState.error != null) {
      AppLogger.error('❌ Location tracking error: ${locationState.error}');
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with refresh button
                HomeHeader(
                  showBackButton: true,
                  action: IconButton(
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
                    tooltip: AppLocalization.translate('refresh_status', lang),
                  ),
                ),
                // Banner
                SizedBox(
                  height: ResponsiveUtils.adaptiveBannerHeight(context, 120),
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/images/booking/banner.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveUtils.scrollPaddingWithFab(context),
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
                              RiderBookingStatusGrid(
                                booking: _updatedBooking ?? widget.booking,
                                currentStatus: _currentStatus,
                                onStatusTap:
                                    _isUpdating ? null : _handleStatusChange,
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                              RiderBookingNextActions(
                                category: widget.booking.category,
                                apiStatus: _currentApiStatus,
                                isUpdating: _isUpdating,
                                awaitingProof: _showProofUpload,
                                onAction:
                                    _isUpdating ? null : _handleStatusChange,
                              ),
                              if (RiderOrderOpsUtils.canCancel(
                                _currentApiStatus,
                              )) ...[
                                SizedBox(
                                  height: ResponsiveUtils.spacing(context, 12),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _isUpdating ? null : _handleCancelOrder,
                                    icon: Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red.shade700,
                                    ),
                                    label: Text(
                                      AppLocalization.translate('cancel_order', lang),
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(
                                          context,
                                          14,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.red.shade700,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: ResponsiveUtils.spacing(
                                          context,
                                          12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (_currentApiStatus == 'completed') ...[
                                SizedBox(
                                  height: ResponsiveUtils.spacing(context, 12),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _shareReceipt,
                                    icon: const Icon(
                                      Icons.receipt_long_outlined,
                                      color: Color(0xFF5F2D82),
                                    ),
                                    label: Text(
                                      'Get Receipt',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: ResponsiveUtils.fontSize(
                                          context,
                                          14,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5F2D82),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF5F2D82),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: ResponsiveUtils.spacing(
                                          context,
                                          12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

}
