import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  try {
    print('Creating test merchant account on live server...');
    final request = await client.postUrl(
      Uri.parse('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/register')
    );
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final body = jsonEncode({
      "name": "Test Restaurant",
      "restaurant_name": "Test Restaurant",
      "email": "merchant@test.com",
      "password": "Password123!",
      "password_confirmation": "Password123!",
      "phone_number": "+639171234567",
      "role": "partner_admin",
      "terms_accepted": true,
      "privacy_accepted": true,
      "selfie_path": "uploads/merchants/selfie.jpg",
      "valid_id_path": "uploads/merchants/id.jpg",
      "digital_signature_path": "uploads/merchants/signature.png"
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
