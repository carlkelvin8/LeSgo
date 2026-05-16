import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/home_screen.dart';
import 'presentation/screens/main/address_management_screen.dart';
import 'presentation/screens/main/settings_screen.dart';
import 'presentation/screens/main/profile_screen.dart';
import 'presentation/screens/main/offers_screen.dart';
import 'core/constants/routers/main/main_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(const ProviderScope(child: LesGoApp()));
}

class LesGoApp extends StatelessWidget {
  const LesGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LesGo - Delivery & Transport',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF5F2D82),
        fontFamily: 'TT Fors',
        useMaterial3: true,
      ),
      home: const LesGoHomePage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        MainRoutes.addressManagement: (context) =>
            const AddressManagementScreen(),
        MainRoutes.settings: (context) => const SettingsScreen(),
        MainRoutes.profile: (context) => const ProfileScreen(),
        MainRoutes.offers: (context) => const OffersScreen(),
      },
    );
  }
}

class LesGoHomePage extends StatelessWidget {
  const LesGoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5F2D82),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      size: 60,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LesGo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'TT Fors',
                    ),
                  ),
                  const Text(
                    'Your Delivery & Transport Partner',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontFamily: 'TT Fors',
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TT Fors',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Service Cards
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _ServiceCard(
                              icon: Icons.motorcycle,
                              title: 'LesRide',
                              subtitle: 'Quick delivery',
                              color: Colors.blue,
                              onTap: () => _showComingSoon(context, 'LesRide'),
                            ),
                            _ServiceCard(
                              icon: Icons.restaurant,
                              title: 'LesEat',
                              subtitle: 'Food delivery',
                              color: Colors.orange,
                              onTap: () => _showComingSoon(context, 'LesEat'),
                            ),
                            _ServiceCard(
                              icon: Icons.shopping_bag,
                              title: 'LesBuy',
                              subtitle: 'Shopping delivery',
                              color: Colors.green,
                              onTap: () => _showComingSoon(context, 'LesBuy'),
                            ),
                            _ServiceCard(
                              icon: Icons.location_on,
                              title: 'Addresses',
                              subtitle: 'Manage addresses',
                              color: const Color(0xFF5F2D82),
                              onTap: () => Navigator.pushNamed(
                                context,
                                MainRoutes.addressManagement,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Navigation
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _NavButton(
                              icon: Icons.home,
                              label: 'Home',
                              isActive: true,
                              onTap: () {},
                            ),
                            _NavButton(
                              icon: Icons.person,
                              label: 'Profile',
                              onTap: () => Navigator.pushNamed(
                                context,
                                MainRoutes.profile,
                              ),
                            ),
                            _NavButton(
                              icon: Icons.settings,
                              label: 'Settings',
                              onTap: () => Navigator.pushNamed(
                                context,
                                MainRoutes.settings,
                              ),
                            ),
                          ],
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

  void _showComingSoon(BuildContext context, String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$service Coming Soon!'),
        content: Text('$service service will be available soon. Stay tuned!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'TT Fors',
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
                fontFamily: 'TT Fors',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5F2D82) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF5F2D82) : Colors.grey.shade600,
              fontFamily: 'TT Fors',
            ),
          ),
        ],
      ),
    );
  }
}
