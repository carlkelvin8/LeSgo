import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Debugging Production Order Items');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Get recent orders
      print('\n2. Fetching recent orders...');
      await fetchRecentOrders(client, token);
      
    } else {
      print('   ❌ Login failed');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}

Future<String?> loginAndGetToken(HttpClient client) async {
  try {
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/login')
    );
    request.headers.set('Content-Type', 'application/json');
    
    final body = jsonEncode({
      'email': 'testuser1778720118525@lesgo.com',
      'password': 'TestPassword123!',
      'device_name': 'test-device'
    });
    
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['token'];
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<void> fetchRecentOrders(HttpClient client, String token) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders?per_page=5')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      print('   📋 Full response: ${jsonEncode(jsonResponse)}');
    } else {
      print('   ❌ Failed to fetch orders: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error fetching orders: $e');
  }
}

Future<void> fetchOrderDetails(HttpClient client, String token, int orderId) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders/$orderId')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      final order = jsonResponse['data'];
      
      final lesbuyItems = order['lesbuy_items'];
      if (lesbuyItems != null && lesbuyItems is List && lesbuyItems.isNotEmpty) {
        print('         ✅ Detailed view has ${lesbuyItems.length} items');
      } else {
        print('         ❌ Detailed view also has no items');
        print('         📋 Full order data: ${jsonEncode(order)}');
      }
    }
  } catch (e) {
    print('         ❌ Error fetching order details: $e');
  }
}