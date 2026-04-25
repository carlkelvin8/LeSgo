import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../widgets/widgets.dart';

class LeseatOrderCompleteScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderType;
  final Map<String, dynamic>? orderData;

  const LeseatOrderCompleteScreen({
    super.key,
    required this.orderId,
    required this.orderType,
    this.orderData,
  });

  @override
  ConsumerState<LeseatOrderCompleteScreen> createState() => _LeseatOrderCompleteScreenState();
}

class _LeseatOrderCompleteScreenState extends ConsumerState<LeseatOrderCompleteScreen> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _hasSubmittedReview = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_hasSubmittedReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Show rating dialog for driver (temporarily disabled)
    // final result = await showRatingDialog(
    //   context: context,
    //   title: 'Rate Your Driver',
    //   subtitle: 'How was your delivery experience?',
    //   reviewableType: 'order',
    //   reviewableId: int.tryParse(widget.orderId) ?? 0,
    //   onSuccess: () {
    //     setState(() {
    //       _hasSubmittedReview = true;
    //     });
    //   },
    // );

    // if (result == true && mounted) {
    //   // Navigate back to home after successful review
    //   Future.delayed(const Duration(seconds: 1), () {
    //     if (mounted) {
    //       Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    //     }
    //   });
    // }
    
    // Temporarily just navigate back
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _orderAgain() {
    // Navigate back to LesEat screen
    AppRouter.pushReplacement(context, BookingRoutes.leseat);
  }

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderData ?? {};
    final restaurantName = orderData['restaurantName'] ?? 'Restaurant';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.orderType,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 40)),

              // Success Icon and Restaurant Logo
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Restaurant logo placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  // Success checkmark
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

              // Restaurant Name
              Text(
                restaurantName,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              // Order Complete Message
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 48,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Text(
                      'ORDER DELIVERED!',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      'Your food has been delivered successfully',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.green[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 32)),

              // Rating Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your food?',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Star Rating
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.spacing(context, 4),
                              ),
                              child: Icon(
                                Icons.star,
                                size: 32,
                                color: index < _rating
                                    ? Colors.amber[600]
                                    : Colors.grey[300],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // Feedback Text Field
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your feedback (optional)',
                        hintStyle: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          color: Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5F2D82)),
                        ),
                        contentPadding: EdgeInsets.all(
                          ResponsiveUtils.spacing(context, 16),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // Submit Rating Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _hasSubmittedReview ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasSubmittedReview
                              ? Colors.grey
                              : const Color(0xFF5F2D82),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.spacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _hasSubmittedReview ? 'REVIEW SUBMITTED' : 'SUBMIT',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

              // Rate LesEat Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1D4F7)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Rate LesEat',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                    // LesEat Star Rating (default 5 stars)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 2),
                          ),
                          child: Icon(
                            Icons.star,
                            size: 24,
                            color: Colors.amber[600],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 32)),

              // Order Again Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _orderAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Order Again',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              // Go to Home Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5F2D82)),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
