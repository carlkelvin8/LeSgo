import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  try {
    print('Logging in as merchant@test.com...');
    
    var loginRequest = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/login')
    );
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.headers.set('Accept', 'application/json');
    
    loginRequest.write(jsonEncode({
      "email": "merchant@test.com",
      "password": "Password123!"
    }));
    
    var loginResponse = await loginRequest.close();
    var loginBody = await loginResponse.transform(utf8.decoder).join();
    
    if (loginResponse.statusCode != 200) {
      print('Login failed: $loginBody');
      return;
    }
    
    var loginData = jsonDecode(loginBody);
    var token = loginData['token'];
    var partnerId = loginData['user']['partner_id'];
    
    print('Logged in successfully! Partner ID: $partnerId');
    
    print('Fetching orders...');
    var ordersRequest = await client.getUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/orders?partner_id=$partnerId&per_page=100')
    );
    ordersRequest.headers.set('Accept', 'application/json');
    ordersRequest.headers.set('Authorization', 'Bearer $token');
    
    var ordersResponse = await ordersRequest.close();
    var ordersBody = await ordersResponse.transform(utf8.decoder).join();
    
    print('Orders Response Code: ${ordersResponse.statusCode}');
    print('Orders: $ordersBody');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
