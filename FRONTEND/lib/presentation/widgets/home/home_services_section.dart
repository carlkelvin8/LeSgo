import '../../../core/services/affiliate_launcher.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/booking/booking_routes.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import 'service_card.dart';

class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});
  static final _affiliateLauncher = AffiliateLauncher();

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'svgPath': 'assets/images/book/Lesride.svg',
        'title': 'LesRide',
        'description': 'Quick & Safe Motorcycle Taxi',
        'gradientStart': const Color(0xFF6B4CE6),
        'gradientEnd': const Color(0xFF8B6CE8),
        'route': BookingRoutes.lesride,
      },
      {
        'svgPath': 'assets/images/book/Lesgo.svg',
        'title': 'LesGo',
        'description': 'Fast Delivery Service',
        'gradientStart': const Color(0xFFE84C8B),
        'gradientEnd': const Color(0xFFEB6B9D),
        'route': BookingRoutes.lesgo,
      },
      {
        'svgPath': 'assets/images/book/Leseat.svg',
        'title': 'LesEat',
        'description': 'Food Cravings Delivered',
        'gradientStart': const Color(0xFFFF6B35),
        'gradientEnd': const Color(0xFFFF8555),
        'route': BookingRoutes.leseat,
      },
      {
        'svgPath': 'assets/images/book/Lesbuy.svg',
        'title': 'LesBuy',
        'description': 'Grocery & Shopping',
        'gradientStart': const Color(0xFF4CAF50),
        'gradientEnd': const Color(0xFF66BB6A),
        'route': BookingRoutes.lesbuy,
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'LesPay',
        'description': 'Digital Wallet & Payments',
        'gradientStart': const Color(0xFF2196F3),
        'gradientEnd': const Color(0xFF42A5F5),
        'route': MainRoutes.lespay,
      },
      {
        'icon': Icons.person_add,
        'title': 'Become Partner',
        'description': 'Earn with LeSgo',
        'gradientStart': const Color(0xFFFFB300),
        'gradientEnd': const Color(0xFFFFC233),
        'route': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
          ),
          child: Text(
            'Our Services',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: AppColors.accent(context, Color(0xFF6B4CE6)),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        
        // Horizontal scrolling services
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < services.length - 1 ? 12 : 0,
                ),
                child: SizedBox(
                  width: 160,
                  child: ServiceCard(
                    svgPath: service['svgPath'] as String?,
                    icon: service['icon'] as IconData?,
                    title: service['title'] as String,
                    description: service['description'] as String,
                    gradientStart: service['gradientStart'] as Color,
                    gradientEnd: service['gradientEnd'] as Color,
                    onTap: () {
                      final route = service['route'] as String?;
                      if (route != null) {
                        AppRouter.push(context, route);
                      } else {
                        _showPartnerInfo(context);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPartnerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Become a Partner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join LeSgo as a rider, merchant, or store owner and start earning today!',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildPartnerBenefit('🏍️', 'Become a Rider', 'Earn by delivering'),
            const SizedBox(height: 8),
            _buildPartnerBenefit('🍽️', 'Restaurant Partner', 'Expand your reach'),
            const SizedBox(height: 8),
            _buildPartnerBenefit('🛒', 'Store Partner', 'Sell more online'),
            const SizedBox(height: 16),
             Text(
              'Download the LeSgo Affiliate app to get started.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.foreground(context, Colors.grey),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.foreground(context, Colors.grey)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDetailedPartnerInfo(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4CE6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerBenefit(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetailedPartnerInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration:  BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.grey[300]!),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partner with LeSgo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grow your business and income with us',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildPartnerCard(
                      context,
                      '🏍️ Rider Partner',
                      'Earn money by delivering orders in your area',
                      [
                        '✓ Flexible schedule',
                        '✓ Earn up to ₱2,000/day',
                        '✓ Weekly payouts',
                        '✓ Insurance coverage',
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildPartnerCard(
                      context,
                      '🍽️ Restaurant Partner',
                      'Reach more customers and grow your restaurant',
                      [
                        '✓ Zero setup fees',
                        '✓ Marketing support',
                        '✓ Real-time dashboard',
                        '✓ Flexible commission rates',
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildPartnerCard(
                      context,
                      '🛒 Store Partner',
                      'Sell products online and expand your reach',
                      [
                        '✓ Easy product listing',
                        '✓ Inventory management',
                        '✓ Fast delivery network',
                        '✓ Marketing campaigns',
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'How to Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Download LeSgo Affiliate app'),
                    _buildStep('2', 'Complete registration'),
                    _buildStep('3', 'Submit requirements'),
                    _buildStep('4', 'Start earning!'),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final opened = await _affiliateLauncher.open();
                          if (!context.mounted) return;
                          if (opened) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Could not open LeSgo Affiliate. Check that a browser is available and try again.'),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4CE6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Get Started Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, String title, String description, List<String> benefits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.grey[50]!),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context, Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
            color: AppColors.foreground(context, Colors.grey[600]!),
          ),
        ),
        const SizedBox(height: 12),
        ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  benefit,
                  style: const TextStyle(fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF6B4CE6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
