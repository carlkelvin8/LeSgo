import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Testing Fixed Order Display with Production API');
  print('=' * 60);
  
  try {
    // Login first
    print('\n1. Logging in...');
    final token = await loginAndGetToken(client);
    
    if (token != null) {
      print('   ✅ Logged in successfully');
      
      // Check the newly created orders
      print('\n2. Checking Order #44 (LesEat with items)...');
      await checkOrderWithFallback(client, token, 44);
      
      print('\n3. Checking Order #45 (LesBuy with items)...');
      await checkOrderWithFallback(client, token, 45);
      
      print('\n4. Testing effective helper methods...');
      await testEffectiveMethods(client, token, 44);
      
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

Future<void> checkOrderWithFallback(HttpClient client, String token, int orderId) async {
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
      
      print('   📦 Order #$orderId:');
      print('     Service ID: ${order['service_id']}');
      print('     Status: ${order['status']}');
      print('     Estimated Fare: ₱${order['estimated_fare']}');
      
      // Test the fallback logic that our helper methods would use
      print('   🔧 Testing fallback logic:');
      
      // Service type fallback
      String serviceType = order['service_type'] ?? 'unknown';
      if (serviceType == 'unknown') {
        switch (order['service_id']) {
          case 3: serviceType = 'leseat'; break;
          case 4: serviceType = 'lesbuy'; break;
          default: serviceType = 'unknown';
        }
      }
      print('     Effective Service Type: $serviceType');
      
      // Items fallback (check meta for items)
      bool hasItems = false;
      if (order['lesbuy_items'] != null) {
        hasItems = true;
        print('     Has lesbuy_items: Yes');
      } else if (order['meta'] != null && order['meta']['items'] != null) {
        hasItems = true;
        print('     Has items in meta: Yes');
        final items = order['meta']['items'] as List;
        print('     Items count: ${items.length}');
        for (final item in items) {
          print('       - ${item['name']}: ₱${item['estimated_price']} x${item['quantity']}');
        }
      } else {
        print('     Has items: No');
      }
      
      // Total calculation fallback
      double total = 0.0;
      if (order['total_amount'] != null) {
        total = (order['total_amount'] as num).toDouble();
      } else {
        // Calculate from items + delivery
        double itemsTotal = 0.0;
        if (order['meta'] != null && order['meta']['items'] != null) {
          final items = order['meta']['items'] as List;
          for (final item in items) {
            final price = (item['estimated_price'] ?? 0.0) as num;
            final qty = (item['quantity'] ?? 1) as num;
            itemsTotal += price.toDouble() * qty.toDouble();
          }
        }
        final deliveryFee = (order['estimated_fare'] ?? 0.0) as num;
        total = itemsTotal + deliveryFee.toDouble();
      }
      print('     Effective Total: ₱${total.toStringAsFixed(2)}');
      
    } else {
      print('   ❌ Failed to fetch order: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
}

Future<void> testEffectiveMethods(HttpClient client, String token, int orderId) async {
  print('   🧪 Simulating frontend helper methods...');
  
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
      
      // Simulate effectiveServiceType
      String effectiveServiceType = order['service_type'] ?? '';
      if (effectiveServiceType.isEmpty) {
        switch (order['service_id']) {
          case 1: effectiveServiceType = 'lesgo'; break;
          case 2: effectiveServiceType = 'lesride'; break;
          case 3: effectiveServiceType = 'leseat'; break;
          case 4: effectiveServiceType = 'lesbuy'; break;
          case 5: effectiveServiceType = 'lestransport'; break;
          default: effectiveServiceType = 'unknown';
        }
      }
      
      // Simulate effectiveItems
      List<Map<String, dynamic>> effectiveItems = [];
      if (order['lesbuy_items'] != null && order['lesbuy_items'] is List) {
        effectiveItems = List<Map<String, dynamic>>.from(order['lesbuy_items']);
      } else if (order['meta'] != null && order['meta']['items'] != null) {
        final metaItems = order['meta']['items'] as List;
        effectiveItems = metaItems.map((item) => {
          'id': 0,
          'order_id': orderId,
          'name': item['name'] ?? 'Unknown Item',
          'quantity': item['quantity'] ?? 1,
          'unit': 'pcs',
          'estimated_price': (item['estimated_price'] ?? 0.0).toDouble(),
          'actual_price': (item['estimated_price'] ?? 0.0).toDouble(),
          'image_url': null,
        }).toList().cast<Map<String, dynamic>>();
      }
      
      // Simulate effectiveDeliveryFee
      double effectiveDeliveryFee = 0.0;
      if (order['delivery_fee'] != null) {
        effectiveDeliveryFee = (order['delivery_fee'] as num).toDouble();
      } else {
        effectiveDeliveryFee = ((order['estimated_fare'] ?? 0.0) as num).toDouble();
      }
      
      // Simulate effectiveTotalAmount
      double effectiveTotalAmount = 0.0;
      if (order['total_amount'] != null && (order['total_amount'] as num) > 0) {
        effectiveTotalAmount = (order['total_amount'] as num).toDouble();
      } else {
        double itemsTotal = 0.0;
        for (final item in effectiveItems) {
          final price = (item['actual_price'] ?? item['estimated_price'] ?? 0.0) as num;
          final quantity = (item['quantity'] ?? 1) as num;
          itemsTotal += price.toDouble() * quantity.toDouble();
        }
        effectiveTotalAmount = itemsTotal + effectiveDeliveryFee;
      }
      
      print('   ✅ Helper Methods Results:');
      print('     effectiveServiceType: $effectiveServiceType');
      print('     effectiveItems count: ${effectiveItems.length}');
      if (effectiveItems.isNotEmpty) {
        for (final item in effectiveItems) {
          print('       - ${item['name']}: ₱${item['actual_price']} x${item['quantity']}');
        }
      }
      print('     effectiveDeliveryFee: ₱${effectiveDeliveryFee.toStringAsFixed(2)}');
      print('     effectiveTotalAmount: ₱${effectiveTotalAmount.toStringAsFixed(2)}');
      
      print('   🎯 Frontend should now display:');
      print('     Service: ${effectiveServiceType.toUpperCase()}');
      print('     Items: ${effectiveItems.length} items');
      print('     Subtotal: ₱${(effectiveTotalAmount - effectiveDeliveryFee).toStringAsFixed(2)}');
      print('     Delivery: ₱${effectiveDeliveryFee.toStringAsFixed(2)}');
      print('     Total: ₱${effectiveTotalAmount.toStringAsFixed(2)}');
      
    }
  } catch (e) {
    print('   ❌ Error testing methods: $e');
  }
}