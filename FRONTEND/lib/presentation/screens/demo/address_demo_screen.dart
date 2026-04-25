import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/address/address_selector_widget.dart';
import '../../widgets/widgets.dart';

/// Demo screen to showcase address management functionality
class AddressDemoScreen extends ConsumerWidget {
  const AddressDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(title: 'Address Management Demo'),
            ),
            Container(height: 1, color: Colors.grey[200]),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5F2D82).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF5F2D82),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Address Management Features',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5F2D82),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '✅ Save multiple addresses (Home, Work, etc.)\n'
                            '✅ Set default address\n'
                            '✅ Edit and delete saved addresses\n'
                            '✅ Quick address selection in booking\n'
                            '✅ Uses existing AddressRemoteDataSource\n'
                            '✅ Integrated with profile and settings',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                    // Address selector widget demo
                    Text(
                      'Address Selector Widget',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This widget can be used in booking/checkout screens:',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AddressSelectorWidget(
                      title: 'Delivery Address',
                      onAddressSelected: (address) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${address.label} - ${address.addressLine1}'),
                            backgroundColor: const Color(0xFF5F2D82),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                    // Navigation buttons
                    Text(
                      'Quick Navigation',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _NavigationButton(
                      icon: Icons.location_on_outlined,
                      title: 'Address Management',
                      subtitle: 'Full address management screen',
                      onTap: () => Navigator.pushNamed(context, '/address-management'),
                    ),
                    const SizedBox(height: 12),
                    _NavigationButton(
                      icon: Icons.person_outline,
                      title: 'Profile Screen',
                      subtitle: 'Profile with quick actions',
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    const SizedBox(height: 12),
                    _NavigationButton(
                      icon: Icons.settings_outlined,
                      title: 'Settings Screen',
                      subtitle: 'Settings with address management',
                      onTap: () => Navigator.pushNamed(context, '/settings'),
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
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5F2D82),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}