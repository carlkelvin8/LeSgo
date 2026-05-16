import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'LesEat',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: Color(0xFF5F2D82)),
            onPressed: () {
              // Navigate to profile
            },
          ),
        ],
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
                  // Illustration
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
                            color: Color(0xFF5F2D82),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                  // Status Card
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
                        // Status Header
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
                            SizedBox(
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

                        // Address Section
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

                        // Divider
                        Divider(color: Colors.grey.shade300),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                        // Your Order Section
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

                        // Order Items
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
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cancel Button
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.spacing(context, 56),
                child: ElevatedButton(
                  onPressed: () {
                    _showCancelDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5F2D82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
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

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Order?',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(fontFamily: 'TT Fors'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: TextStyle(fontFamily: 'TT Fors', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              // TODO: Call API to cancel order
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: Color(0xFF5F2D82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
