import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  try {
    print('Logging in...');
    var loginReq = await client.postUrl(Uri.parse('http://127.0.0.1:8000/api/v1/auth/login'));
    loginReq.headers.set('Content-Type', 'application/json');
    loginReq.headers.set('Accept', 'application/json');
    loginReq.write(jsonEncode({
      "email": "merchant@test.com",
      "password": "Password123!",
      "role": "partner"
    }));
    var loginRes = await loginReq.close();
    var loginBody = await loginRes.transform(utf8.decoder).join();
    
    if (loginRes.statusCode != 200 || !jsonDecode(loginBody)['success']) {
      print('Login failed: $loginBody');
      return;
    }
    
    var token = jsonDecode(loginBody)['token'];
    var partnerId = jsonDecode(loginBody)['user']['partner_id'];
    print('Token: $token');
    print('Partner ID: $partnerId');
    
    print('Updating partner...');
    var updateReq = await client.patchUrl(Uri.parse('http://127.0.0.1:8000/api/v1/partners/$partnerId'));
    updateReq.headers.set('Content-Type', 'application/json');
    updateReq.headers.set('Accept', 'application/json');
    updateReq.headers.set('Authorization', 'Bearer $token');
    
    updateReq.write(jsonEncode({
      "name": "Test Restaurant 2",
      "support_phone": "09498787543",
      "support_email": "carlmanahan@gmail.com"
    }));
    
    var updateRes = await updateReq.close();
    var updateBody = await updateRes.transform(utf8.decoder).join();
    
    print('Status: ${updateRes.statusCode}');
    if (updateBody.length > 300) {
      print('Response: ${updateBody.substring(0, 300)}...');
    } else {
      print('Response: $updateBody');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
