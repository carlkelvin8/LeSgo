import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🍽️ Adding Menu Items to Production Partners');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Add menu items for each partner
      print('\n2. Adding Jollibee menu items...');
      await addJollibeeMenu(client, token);
      
      print('\n3. Adding Mang Inasal menu items...');
      await addMangInasalMenu(client, token);
      
      print('\n4. Adding Chowking menu items...');
      await addChowkingMenu(client, token);
      
      print('\n✅ Menu items added successfully!');
      print('\n🎯 Now you can create orders with actual items!');
      
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

Future<void> addJollibeeMenu(HttpClient client, String token) async {
  final menuItems = [
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
    {
      'partner_id': 1,
      'name': 'Yumburger',
      'description': 'Classic beef burger',
      'price': 45.00,
      'category': 'Burgers',
      'image_url': 'https://example.com/yumburger.jpg',
      'is_available': true
    }
  ];
  
  await addMenuItems(client, token, menuItems, 'Jollibee');
}

Future<void> addMangInasalMenu(HttpClient client, String token) async {
  final menuItems = [
    {
      'partner_id': 2,
      'name': 'Chicken Inasal',
      'description': 'Grilled chicken with unlimited rice',
      'price': 99.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/chicken-inasal.jpg',
      'is_available': true
    },
    {
      'partner_id': 2,
      'name': 'Pork BBQ',
      'description': 'Grilled pork barbecue',
      'price': 85.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/pork-bbq.jpg',
      'is_available': true
    },
    {
      'partner_id': 2,
      'name': 'Bangus Sisig',
      'description': 'Sizzling bangus sisig',
      'price': 120.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/bangus-sisig.jpg',
      'is_available': true
    }
  ];
  
  await addMenuItems(client, token, menuItems, 'Mang Inasal');
}

Future<void> addChowkingMenu(HttpClient client, String token) async {
  final menuItems = [
    {
      'partner_id': 3,
      'name': 'Chao Fan',
      'description': 'Chinese fried rice',
      'price': 78.00,
      'category': 'Rice Meals',
      'image_url': 'https://example.com/chao-fan.jpg',
      'is_available': true
    },
    {
      'partner_id': 3,
      'name': 'Sweet and Sour Pork',
      'description': 'Pork with sweet and sour sauce',
      'price': 95.00,
      'category': 'Main Course',
      'image_url': 'https://example.com/sweet-sour-pork.jpg',
      'is_available': true
    },
    {
      'partner_id': 3,
      'name': 'Wonton Noodles',
      'description': 'Noodles with wonton dumplings',
      'price': 68.00,
      'category': 'Noodles',
      'image_url': 'https://example.com/wonton-noodles.jpg',
      'is_available': true
    }
  ];
  
  await addMenuItems(client, token, menuItems, 'Chowking');
}

Future<void> addMenuItems(HttpClient client, String token, List<Map<String, dynamic>> menuItems, String restaurantName) async {
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ ${item['name']}: ₱${item['price']}');
      } else {
        print('   ❌ Failed to add ${item['name']}: ${response.statusCode}');
        print('     Response: $responseBody');
      }
    } catch (e) {
      print('   ❌ Error adding ${item['name']}: $e');
    }
  }
}