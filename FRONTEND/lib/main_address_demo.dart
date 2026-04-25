import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'presentation/screens/demo/address_demo_screen.dart';
import 'presentation/screens/main/address_management_screen.dart';
import 'presentation/screens/main/settings_screen.dart';
import 'presentation/screens/main/profile_screen.dart';
import 'core/constants/routers/main/main_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const ProviderScope(child: AddressDemoApp()));
}

class AddressDemoApp extends StatelessWidget {
  const AddressDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Address Management Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF5F2D82),
        fontFamily: 'TT Fors',
      ),
      home: const AddressDemoScreen(),
      routes: {
        MainRoutes.addressManagement: (context) => const AddressManagementScreen(),
        MainRoutes.addressDemo: (context) => const AddressDemoScreen(),
        MainRoutes.settings: (context) => const SettingsScreen(),
        MainRoutes.profile: (context) => const ProfileScreen(),
      },
    );
  }
}