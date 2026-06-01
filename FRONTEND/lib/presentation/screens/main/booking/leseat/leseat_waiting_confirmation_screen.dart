import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../data/data_source/order_remote_datasource.dart';
import '../../../../widgets/orders/cancel_order_dialog.dart';

class LeseatWaitingConfirmationScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String address;
  final List<Map<String, dynamic>> orderItems;

  const LeseatWaitingConfirmationScreen({
    super.key,
    required this.orderId,
    required this.address,
    required this.orderItems,
  });

  @override
  ConsumerState<LeseatWaitingConfirmationScreen> createState() =>
      _LeseatWaitingConfirmationScreenState();
}

class _LeseatWaitingConfirmationScreenState
    extends ConsumerState<LeseatWaitingConfirmationScreen> {
  Timer? _pollTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkOrderStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkOrderStatus() async {
    if (!mounted || _isCancelling) return;

    try {
      final response =
          await getIt<OrderRemoteDataSource>().getOrder(widget.orderId);
      if (!mounted || !response.success) return;

      final status = response.data.status.toLowerCase();
      if (status == 'cancelled') {
        SnackBarUtils.showError(context, 'This order was cancelled.');
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      if (status != 'pending' && status != 'created') {
        if (!mounted) return;
        AppRouter.pushReplacement(
          context,
          BookingRoutes.driverFinding,
          arguments: {
            'orderId': widget.orderId.toString(),
            'orderType': 'LesEat',
            'orderData': {
              'deliveryAddress': widget.address,
              'items': widget.orderItems,
              'status': status,
            },
          },
        );
      }
    } catch (_) {}
  }

  Future<void> _showCancelDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => CancelOrderDialog(
        onConfirm: (reason) async {
          setState(() => _isCancelling = true);
          try {
            await getIt<OrderRemoteDataSource>().cancelOrder(
              widget.orderId,
              reason,
            );
            if (!mounted) return;
            Navigator.of(dialogContext).pop();
            SnackBarUtils.showSuccess(context, 'Order cancelled.');
            Navigator.of(context).popUntil((route) => route.isFirst);
          } catch (e) {
            if (mounted) {
              setState(() => _isCancelling = false);
              SnackBarUtils.showErrorFrom(
                context,
                e,
                fallbackEn: 'Could not cancel order.',
                fallbackTl: 'Hindi makansela ang order.',
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: _isCancelling ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'LesEat',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
                vertical: ResponsiveUtils.spacing(context, 24),
              ),
              child: Column(
                children: [
                  Container(
                    width: ResponsiveUtils.screenWidth(context) * 0.6,
                    height: ResponsiveUtils.screenWidth(context) * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/leseat/waiting_confirmation.png',
                        width: ResponsiveUtils.screenWidth(context) * 0.5,
                        height: ResponsiveUtils.screenWidth(context) * 0.5,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant,
                            size: ResponsiveUtils.screenWidth(context) * 0.3,
                            color: const Color(0xFF5F2D82),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 20),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Waiting for Restaurant\nConfirmation',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(
                                    context,
                                    18,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5F2D82),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                        Text(
                          'Address',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        Text(
                          widget.address,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                        Divider(color: Colors.grey.shade300),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        Text(
                          'Your Order',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                        ...widget.orderItems.map((item) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.spacing(context, 8),
                            ),
                            child: Text(
                              '${item['quantity']} pc. ${item['name']}',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.spacing(context, 56),
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _showCancelDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
