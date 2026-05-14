import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  print('🔍 Testing Production API: https://lesgo-api-feature-auth-secmes.free.laravel.cloud');
  print('=' * 60);
  
  try {
    // Test 1: Check API Health
    print('\n1. Testing API Health...');
    await testApiHealth(client);
    
    // Test 2: Try Registration
    print('\n2. Testing Registration...');
    await testRegistration(client);
    
    // Test 3: Try Login with generated credentials
    print('\n3. Testing Login...');
    await testLogin(client);
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}

Future<void> testApiHealth(HttpClient client) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/health')
    );
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    print('   Response: $responseBody');
    
    if (response.statusCode == 200) {
      print('   ✅ API is healthy');
    } else {
      print('   ⚠️  API returned ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Health check failed: $e');
  }
}

Future<void> testRegistration(HttpClient client) async {
  try {
    final testEmail = 'testuser${DateTime.now().millisecondsSinceEpoch}@lesgo.com';
    final testPassword = 'TestPassword123!';
    
    print('   📧 Email: $testEmail');
    print('   🔐 Password: $testPassword');
    
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/register')
    );
    request.headers.set('Content-Type', 'application/json');
    
    final body = jsonEncode({
      'name': 'Test User',
      'email': testEmail,
      'password': testPassword,
      'password_confirmation': testPassword,
      'phone': '+639171234567',
      'device_name': 'test-device',
      'terms_accepted': true,
      'privacy_accepted': true
    });
    
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    print('   Response: $responseBody');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('   ✅ Registration successful');
      
      // Save credentials for login test
      await File('production_credentials.txt').writeAsString(
        'Email: $testEmail\nPassword: $testPassword\n'
      );
      print('   💾 Credentials saved to production_credentials.txt');
    } else {
      print('   ⚠️  Registration failed with ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Registration test failed: $e');
  }
}

Future<void> testLogin(HttpClient client) async {
  try {
    // Try with saved credentials first
    String email = 'testuser@lesgo.com';
    String password = 'TestPassword123!';
    
    final credFile = File('production_credentials.txt');
    if (await credFile.exists()) {
      final content = await credFile.readAsString();
      final lines = content.split('\n');
      if (lines.length >= 2) {
        email = lines[0].split(': ')[1];
        password = lines[1].split(': ')[1];
      }
    }
    
    print('   📧 Trying login with: $email');
    
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/login')
    );
    request.headers.set('Content-Type', 'application/json');
    
    final body = jsonEncode({
      'email': email,
      'password': password,
      'device_name': 'test-device'
    });
    
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status: ${response.statusCode}');
    print('   Response: $responseBody');
    
    if (response.statusCode == 200) {
      print('   ✅ Login successful');
      
      // Parse token if available
      try {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['data'] != null && jsonResponse['data']['token'] != null) {
          print('   🔑 Token: ${jsonResponse['data']['token']}');
        }
      } catch (e) {
        print('   ⚠️  Could not parse token from response');
      }
    } else {
      print('   ⚠️  Login failed with ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Login test failed: $e');
  }
}