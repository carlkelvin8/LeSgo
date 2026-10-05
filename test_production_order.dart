import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Testing Production Order API');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Check existing orders
      print('\n2. Checking existing orders...');
      await checkExistingOrders(client, token);
      
      // Check partners
      print('\n3. Checking available partners...');
      await checkPartners(client, token);
      
      // Check services
      print('\n4. Checking available services...');
      await checkServices(client, token);
      
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

Future<void> checkExistingOrders(HttpClient client, String token) async {
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
        print('   📦 Found ${orders.length} orders');
        
        for (int i = 0; i < orders.length && i < 3; i++) {
          final order = orders[i];
          print('   Order ${order['id']}: ${order['status']} - Total: ${order['total_amount']}');
          
          // Check if order has items
          if (order['lesbuy_items'] != null) {
            final items = order['lesbuy_items'] as List;
            print('     Items: ${items.length}');
            for (final item in items) {
              print('       - ${item['name']}: ₱${item['actual_price'] ?? item['estimated_price']}');
            }
          } else {
            print('     ⚠️  No items found in order');
          }
        }
      } else {
        print('   📦 No orders found');
      }
    } else {
      print('   ❌ Failed to fetch orders: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking orders: $e');
  }
}

Future<void> checkPartners(HttpClient client, String token) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/partners')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
        final partners = jsonResponse['data'] as List;
        print('   🏪 Found ${partners.length} partners');
        
        for (final partner in partners) {
          print('   Partner: ${partner['name']} (ID: ${partner['id']})');
        }
      } else {
        print('   🏪 No partners found');
      }
    } else {
      print('   ❌ Failed to fetch partners: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking partners: $e');
  }
}

Future<void> checkServices(HttpClient client, String token) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services')
    );
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
        final services = jsonResponse['data'] as List;
        print('   🚀 Found ${services.length} services');
        
        for (final service in services) {
          print('   Service: ${service['name']} (ID: ${service['id']})');
        }
      } else {
        print('   🚀 No services found');
      }
    } else {
      print('   ❌ Failed to fetch services: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error checking services: $e');
  }
}