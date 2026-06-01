import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets/widgets.dart';

class RiderHistoryDetailScreen extends StatelessWidget {
  final Map<String, String> bookingData;
  final Color statusColor;
  final Color statusBackgroundColor;

  const RiderHistoryDetailScreen({
    super.key,
    required this.bookingData,
    required this.statusColor,
    required this.statusBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: ResponsiveUtils.spacing(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Status Section
                      RiderHistoryDetailStatus(
                        rating: int.tryParse(bookingData['rating'] ?? '') ??
                            int.tryParse(bookingData['stars'] ?? '') ??
                            0,
                        status: bookingData['status'] ?? '',
                        statusColor: statusColor,
                        statusBackgroundColor: statusBackgroundColor,
                      ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                      // Middle Info Section
                      RiderHistoryDetailInfo(bookingData: bookingData),

                      SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                      // Bottom Proof Section
                      RiderHistoryDetailProof(
                        timestamp: bookingData['timestamp'] ?? '',
                        proofUrls: bookingData['proofUrls']
                            ?.split('|')
                            .where((url) => url.isNotEmpty)
                            .toList(),
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
}
