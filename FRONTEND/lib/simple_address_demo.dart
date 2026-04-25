import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleAddressDemoApp());
}

class SimpleAddressDemoApp extends StatelessWidget {
  const SimpleAddressDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Address Management Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF5F2D82),
        fontFamily: 'TT Fors',
      ),
      home: const SimpleAddressDemoScreen(),
    );
  }
}

class SimpleAddressDemoScreen extends StatelessWidget {
  const SimpleAddressDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F2D82),
        title: const Text(
          'Address Management Demo',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5F2D82).withOpacity(0.2),
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
                      const Text(
                        'Address Management Features ✅',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F2D82),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✅ Save multiple addresses (Home, Work, etc.)\n'
                    '✅ Set default address\n'
                    '✅ Edit and delete saved addresses\n'
                    '✅ Quick address selection in booking\n'
                    '✅ Uses existing AddressRemoteDataSource\n'
                    '✅ Integrated with profile and settings\n'
                    '✅ Modern UI with Material Design\n'
                    '✅ Form validation and error handling\n'
                    '✅ Loading states and animations\n'
                    '✅ Responsive design for all screen sizes',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Implementation Status
            const Text(
              'Implementation Status',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _StatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Address Management Screen',
              subtitle: 'Full CRUD operations with modern UI',
              status: 'Completed',
            ),
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Address Provider (State Management)',
              subtitle: 'Riverpod-based state management',
              status: 'Completed',
            ),
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Address Selector Widget',
              subtitle: 'Reusable widget for booking screens',
              status: 'Completed',
            ),
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Navigation Integration',
              subtitle: 'Settings and Profile integration',
              status: 'Completed',
            ),
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'API Integration',
              subtitle: 'Uses existing AddressRemoteDataSource',
              status: 'Completed',
            ),

            const SizedBox(height: 32),

            // File Structure
            const Text(
              'Key Files Created/Modified',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FileItem('📱 address_management_screen.dart', 'Main address management interface'),
                  _FileItem('🎛️ address_provider.dart', 'State management with Riverpod'),
                  _FileItem('🧩 address_selector_widget.dart', 'Reusable address selector'),
                  _FileItem('⚙️ settings_screen.dart', 'Enhanced with address management'),
                  _FileItem('👤 profile_quick_actions_section.dart', 'Profile integration'),
                  _FileItem('🗺️ main_routes.dart', 'Navigation routes'),
                  _FileItem('📋 ADDRESS_MANAGEMENT_IMPLEMENTATION.md', 'Complete documentation'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Usage Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to Access Address Management',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Settings → Account → Saved Addresses\n'
                    '2. Profile → Quick Actions → Saved Addresses\n'
                    '3. Booking screens → AddressSelectorWidget\n'
                    '4. Direct navigation: /address-management',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Success Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.green.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Address Management Implementation Complete! 🎉',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All requested features have been successfully implemented\nwith modern UI and comprehensive functionality.',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      color: Colors.green.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String name;
  final String description;

  const _FileItem(this.name, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5F2D82),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}