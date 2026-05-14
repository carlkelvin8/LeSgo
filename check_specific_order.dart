import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Checking Specific Order and Menu Items');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Check menu items for Jollibee
      print('\n2. Checking Jollibee menu items...');
      await checkPartnerMenu(client, token, 1); // Jollibee ID
      
      // Try to get a specific order (the one from screenshot might be order ID 1 or recent)
      print('\n3. Checking recent orders with details...');
      await checkOrderDetails(client, token);
      
      // Check user's orders specifically
      print('\n4. Checking user orders...');
      await checkUserOrders(client, token);
      
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

Future<void> checkPartnerMenu(HttpClient client, String token, int partnerId) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/partners/$partnerId/menu')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
        final menuItems = jsonResponse['data'] as List;
        print('   🍽️ Found ${menuItems.length} menu items for partner $partnerId');
        
        for (final item in menuItems) {
          print('   - ${item['name']}: ₱${item['price']}');
        }
      } else {
        print('   🍽️ No menu items found for partner $partnerId');
      }
    } else {
      print('   ❌ Failed to fetch menu: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking menu: $e');
  }
}

Future<void> checkOrderDetails(HttpClient client, String token) async {
  // Try to check orders 1-5 to see if any exist
  for (int orderId = 1; orderId <= 5; orderId++) {
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
        
        print('   📦 Order $orderId found:');
        print('     Status: ${order['status']}');
        print('     Total: ₱${order['total_amount']}');
        print('     Service: ${order['service_type']}');
        
        // Check items
        if (order['lesbuy_items'] != null && order['lesbuy_items'] is List) {
          final items = order['lesbuy_items'] as List;
          print('     Items (${items.length}):');
          for (final item in items) {
            print('       - ${item['name'] ?? 'No name'}: ₱${item['actual_price'] ?? item['estimated_price'] ?? '0.00'}');
          }
        } else {
          print('     ⚠️  No lesbuy_items found');
        }
        
        // Check if it's a different service type
        if (order['service_type'] == 'leseat' && order['leseat_items'] != null) {
          final items = order['leseat_items'] as List;
          print('     LesEat Items (${items.length}):');
          for (final item in items) {
            print('       - ${item['name'] ?? 'No name'}: ₱${item['price'] ?? '0.00'}');
          }
        }
        
        break; // Found an order, stop checking
      }
    } catch (e) {
      // Continue to next order ID
    }
  }
}

Future<void> checkUserOrders(HttpClient client, String token) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders?user_id=16') // Our test user ID
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    print('   Response: $responseBody');
    
  } catch (e) {
    print('   ❌ Error checking user orders: $e');
  }
}