import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Checking Newly Created Orders');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Check order #42 (LesEat)
      print('\n2. Checking Order #42 (LesEat)...');
      await checkOrderDetails(client, token, 42);
      
      // Check order #43 (LesBuy)
      print('\n3. Checking Order #43 (LesBuy)...');
      await checkOrderDetails(client, token, 43);
      
      // Check all user orders
      print('\n4. Checking all user orders...');
      await checkAllUserOrders(client, token);
      
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

Future<void> checkOrderDetails(HttpClient client, String token, int orderId) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders/$orderId')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      final order = jsonResponse['data'];
      
      print('   📦 Order #$orderId:');
      print('     Service: ${order['service_type']}');
      print('     Status: ${order['status']}');
      print('     Total: ₱${order['total_amount'] ?? 'null'}');
      print('     Delivery Fee: ₱${order['delivery_fee'] ?? 'null'}');
      
      // Check for items in different fields
      bool foundItems = false;
      
      if (order['lesbuy_items'] != null && order['lesbuy_items'] is List) {
        final items = order['lesbuy_items'] as List;
        print('     LesBuy Items (${items.length}):');
        for (final item in items) {
          print('       - ${item['name']}: ₱${item['actual_price'] ?? item['estimated_price']} x${item['quantity']}');
        }
        foundItems = true;
      }
      
      if (order['leseat_items'] != null && order['leseat_items'] is List) {
        final items = order['leseat_items'] as List;
        print('     LesEat Items (${items.length}):');
        for (final item in items) {
          print('       - ${item['name']}: ₱${item['actual_price'] ?? item['estimated_price']} x${item['quantity']}');
        }
        foundItems = true;
      }
      
      if (order['items'] != null && order['items'] is List) {
        final items = order['items'] as List;
        print('     Generic Items (${items.length}):');
        for (final item in items) {
          print('       - ${item['name']}: ₱${item['price'] ?? item['estimated_price']} x${item['quantity']}');
        }
        foundItems = true;
      }
      
      if (!foundItems) {
        print('     ⚠️  No items found in any field');
        print('     Available fields: ${order.keys.toList()}');
      }
      
    } else {
      print('   ❌ Failed to fetch order: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking order: $e');
  }
}

Future<void> checkAllUserOrders(HttpClient client, String token) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
        final orders = jsonResponse['data'] as List;
        print('   📦 Found ${orders.length} total orders');
        
        for (final order in orders) {
          print('   Order #${order['id']}: ${order['service_type']} - ₱${order['total_amount'] ?? 'null'}');
        }
      }
    } else {
      print('   ❌ Failed to fetch orders: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking orders: $e');
  }
}