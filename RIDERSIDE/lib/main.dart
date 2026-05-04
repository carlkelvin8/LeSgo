import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/network/dio_client.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences early
  print('🔧 Initializing SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialized successfully');
  
  // Check if token exists
  final existingToken = prefs.getString('rider_token');
  print('🔍 Existing token check: ${existingToken != null ? "Token found" : "No token"}');
  
  // Initialize DioClient
  DioClient().initialize();
  
  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  const LesgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lezgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5F2D82)),
        useMaterial3: true,
        fontFamily: 'TT Fors',
      ),
      initialRoute: AuthRoutes.auth,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
