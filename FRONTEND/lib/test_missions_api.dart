import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'core/di/injection.dart';

void main() async {
  print('🔵 Testing Missions API...');
  
  // Initialize dependencies
  await configureDependencies();
  
  final dioClient = getIt<DioClient>();
  
  try {
    // Test /me endpoint first
    print('🔵 Testing /me endpoint...');
    final meResponse = await dioClient.dio.get('/auth/me');
    print('🟢 /me Response: ${meResponse.data}');
    
    // Test missions endpoint
    print('🔵 Testing /missions endpoint...');
    final missionsResponse = await dioClient.dio.get('/missions');
    print('🟢 Missions Response: ${missionsResponse.data}');
    
  } catch (e) {
    print('🔴 Error: $e');
    if (e is DioException) {
      print('🔴 Status Code: ${e.response?.statusCode}');
      print('🔴 Response Data: ${e.response?.data}');
    }
  }
}