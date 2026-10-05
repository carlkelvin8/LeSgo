import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  try {
    print('Creating test merchant account...');
    final request = await client.postUrl(
      Uri.parse('https://lezgo.carl.lescripts.com/api/v1/auth/register')
    );
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final body = jsonEncode({
      "name": "Test Restaurant",
      "email": "merchant@test.com",
      "password": "password123",
      "password_confirmation": "password123",
      "phone_number": "+639171234567",
      "role": "partner"
    });
    
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status Code: ${response.statusCode}');
    print('Response: $responseBody');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
