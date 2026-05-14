import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('📦 Creating Test Order with Items in Production');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Create a test order with items
      print('\n2. Creating LesEat order with items...');
      await createLesEatOrder(client, token);
      
      // Create a LesBuy order with items
      print('\n3. Creating LesBuy order with items...');
      await createLesBuyOrder(client, token);
      
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

Future<void> createLesEatOrder(HttpClient client, String token) async {
  try {
    final orderData = {
      'service_id': 3, // LesEat
      'estimated_distance_m': 2500,
      'pickup': {
        'address': 'Jollibee - Claveria, Cagayan de Oro',
        'lat': 8.4542,
        'lng': 124.6319,
        'contact_name': 'Jollibee Staff',
        'contact_phone': '+639171234567'
      },
      'dropoff': {
        'address': 'Main Campus, Cagayan de Oro',
        'lat': 8.4500,
        'lng': 124.6300,
        'contact_name': 'Test User',
        'contact_phone': '+639171234567'
      },
      'notes': 'Test order with items',
      'payment_method': 'cash',
      'items': [
        {
          'name': 'Chickenjoy',
          'quantity': 2,
          'estimated_price': 89.00,
          'notes': 'Extra crispy'
        },
        {
          'name': 'Jolly Spaghetti',
          'quantity': 1,
          'estimated_price': 65.00,
          'notes': 'Regular'
        },
        {
          'name': 'Yumburger',
          'quantity': 1,
          'estimated_price': 45.00,
          'notes': 'No onions'
        }
      ],
      'meta': {
        'partner_id': 1,
        'partner_name': 'Jollibee - Claveria'
      }
    };
    
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders')
    );
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $token');
    
    request.write(jsonEncode(orderData));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(responseBody);
      final order = jsonResponse['data'];
      print('   ✅ LesEat Order created: #${order['id']}');
      print('   Total: ₱${order['total_amount']}');
      
      // Check if items were saved
      if (order['lesbuy_items'] != null || order['leseat_items'] != null) {
        print('   ✅ Items were saved!');
      } else {
        print('   ⚠️  Items not found in response');
      }
    } else {
      print('   ❌ Failed to create order: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error creating LesEat order: $e');
  }
}

Future<void> createLesBuyOrder(HttpClient client, String token) async {
  try {
    final orderData = {
      'service_id': 4, // LesBuy
      'estimated_distance_m': 3000,
      'pickup': {
        'address': 'Mercury Drug - Claveria, Cagayan de Oro',
        'lat': 8.4542,
        'lng': 124.6319,
        'contact_name': 'Mercury Drug Staff',
        'contact_phone': '+639171234568'
      },
      'dropoff': {
        'address': 'Main Campus, Cagayan de Oro',
        'lat': 8.4500,
        'lng': 124.6300,
        'contact_name': 'Test User',
        'contact_phone': '+639171234567'
      },
      'notes': 'Test LesBuy order with items',
      'payment_method': 'cash',
      'items': [
        {
          'name': 'Paracetamol 500mg',
          'quantity': 1,
          'estimated_price': 25.00,
          'notes': 'Generic brand'
        },
        {
          'name': 'Vitamin C 500mg',
          'quantity': 2,
          'estimated_price': 45.00,
          'notes': 'Ascorbic acid'
        }
      ],
      'meta': {
        'partner_id': 4,
        'partner_name': 'Mercury Drug - Claveria'
      }
    };
    
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders')
    );
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $token');
    
    request.write(jsonEncode(orderData));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(responseBody);
      final order = jsonResponse['data'];
      print('   ✅ LesBuy Order created: #${order['id']}');
      print('   Total: ₱${order['total_amount']}');
      
      // Check if items were saved
      if (order['lesbuy_items'] != null || order['leseat_items'] != null) {
        print('   ✅ Items were saved!');
      } else {
        print('   ⚠️  Items not found in response');
      }
    } else {
      print('   ❌ Failed to create order: $responseBody');
    }
  } catch (e) {
    print('   ❌ Error creating LesBuy order: $e');
  }
}