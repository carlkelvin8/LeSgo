import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  try {
    print('Logging in to Cloud Server...');
    
    // Login
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
    
    if (partnerId == null) {
      print('User has no partner profile!');
      return;
    }
    
    print('Logged in successfully! Partner ID: $partnerId');
    print('Updating partner status to active...');
    
    // Update Partner Status
    var updateRequest = await client.patchUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/partners/$partnerId')
    );
    updateRequest.headers.set('Content-Type', 'application/json');
    updateRequest.headers.set('Accept', 'application/json');
    updateRequest.headers.set('Authorization', 'Bearer $token');
    
    updateRequest.write(jsonEncode({
      "category": "restaurant"
    }));
    
    var updateResponse = await updateRequest.close();
    var updateBody = await updateResponse.transform(utf8.decoder).join();
    
    print('Update Status Code: ${updateResponse.statusCode}');
    print('Update Response: $updateBody');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
