import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🚀 Populating Production Server with Test Data');
  print('=' * 60);
  
  // First, get the auth token
  String? authToken;
  
  try {
    // Login to get token
    print('\n1. Logging in to get auth token...');
    authToken = await loginAndGetToken(client);
    
    if (authToken != null) {
      print('   ✅ Got auth token: ${authToken.substring(0, 20)}...');
      
      // Create test partners and menu items
      print('\n2. Creating test partners...');
      await createTestPartners(client, authToken);
      
      print('\n3. Creating test menu items...');
      await createTestMenuItems(client, authToken);
      
      print('\n4. Creating test services...');
      await createTestServices(client, authToken);
      
      print('\n✅ Production data population complete!');
    } else {
      print('   ❌ Failed to get auth token');
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
    print('   ❌ Login failed: $e');
    return null;
  }
}

Future<void> createTestPartners(HttpClient client, String token) async {
  final partners = [
    {
      'name': 'Jollibee - Claveria',
      'slug': 'jollibee-claveria',
      'description': 'Famous Filipino fast food chain',
      'address': 'Claveria, Cagayan de Oro',
      'phone': '+639171234567',
      'email': 'jollibee.claveria@test.com',
      'latitude': 8.4542,
      'longitude': 124.6319,
      'service_id': 2, // LesEat
      'status': 'active',
      'rating': 4.5,
      'delivery_fee': 75.00,
      'minimum_order': 100.00,
      'estimated_delivery_time': 30
    },
    {
      'name': 'SM Supermarket',
      'slug': 'sm-supermarket',
      'description': 'Complete grocery and shopping needs',
      'address': 'SM City Cagayan de Oro',
      'phone': '+639171234568',
      'email': 'sm.supermarket@test.com',
      'latitude': 8.4542,
      'longitude': 124.6319,
      'service_id': 3, // LesBuy
      'status': 'active',
      'rating': 4.3,
      'delivery_fee': 50.00,
      'minimum_order': 200.00,
      'estimated_delivery_time': 45
    }
  ];
  
  for (final partner in partners) {
    try {
      final request = await client.postUrl(
        Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/partners')
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      
      request.write(jsonEncode(partner));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('   Partner ${partner['name']}: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('     Response: $responseBody');
      }
    } catch (e) {
      print('   ❌ Failed to create ${partner['name']}: $e');
    }
  }
}

Future<void> createTestMenuItems(HttpClient client, String token) async {
  final menuItems = [
    // Jollibee items
    {
      'partner_id': 1,
      'name': 'Chickenjoy',
      'description': 'Crispy and juicy fried chicken',
      'price': 89.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/chickenjoy.jpg',
      'is_available': true
    },
    {
      'partner_id': 1,
      'name': 'Jolly Spaghetti',
      'description': 'Sweet style spaghetti with hotdog',
      'price': 65.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/spaghetti.jpg',
      'is_available': true
    },
    {
      'partner_id': 1,
      'name': 'Burger Steak',
      'description': 'Beef patty with mushroom gravy',
      'price': 75.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/burger-steak.jpg',
      'is_available': true
    },
    // SM Supermarket items
    {
      'partner_id': 2,
      'name': 'Rice 5kg',
      'description': 'Premium jasmine rice',
      'price': 250.00,
      'category': 'Groceries',
      'image_url': 'https://example.com/rice.jpg',
      'is_available': true
    },
    {
      'partner_id': 2,
      'name': 'Cooking Oil 1L',
      'description': 'Pure vegetable cooking oil',
      'price': 85.00,
      'category': 'Groceries',
      'image_url': 'https://example.com/oil.jpg',
      'is_available': true
    }
  ];
  
  for (final item in menuItems) {
    try {
      final request = await client.postUrl(
        Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/menu-items')
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      
      request.write(jsonEncode(item));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('   Menu Item ${item['name']}: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('     Response: $responseBody');
      }
    } catch (e) {
      print('   ❌ Failed to create ${item['name']}: $e');
    }
  }
}

Future<void> createTestServices(HttpClient client, String token) async {
  final services = [
    {
      'id': 1,
      'name': 'LesRide',
      'description': 'Motorcycle taxi service',
      'icon': 'motorcycle',
      'is_active': true
    },
    {
      'id': 2,
      'name': 'LesEat',
      'description': 'Food delivery service',
      'icon': 'restaurant',
      'is_active': true
    },
    {
      'id': 3,
      'name': 'LesBuy',
      'description': 'Shopping and grocery delivery',
      'icon': 'shopping_cart',
      'is_active': true
    }
  ];
  
  for (final service in services) {
    try {
      final request = await client.postUrl(
        Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services')
      );
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      
      request.write(jsonEncode(service));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('   Service ${service['name']}: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('     Response: $responseBody');
      }
    } catch (e) {
      print('   ❌ Failed to create ${service['name']}: $e');
    }
  }
}