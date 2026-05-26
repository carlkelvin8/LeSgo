import 'dart:convert';
import 'lib/data/data_source/dto/order/order_dto.dart';

void main() {
  const jsonStr = '''
  {
    "id": 59,
    "customer_id": 17,
    "partner_id": 15,
    "driver_id": 2,
    "service_id": 3,
    "status": "completed",
    "payment_method": "cash",
    "payment_status": "pending",
    "created_at": "2026-05-17T05:22:45.000000Z",
    "updated_at": "2026-05-18T02:52:09.000000Z",
    "pickup_address": "Test Restaurant",
    "dropoff_address": "1600 Amphitheatre Parkway",
    "customer": {
      "id": 17,
      "name": "carl manahan",
      "email": "carlkelvinmanahan014@gmail.com",
      "phone_number": "+639498787542"
    },
    "partner": {
      "id": 15,
      "name": "Test Restaurant",
      "slug": "test-restaurant"
    },
    "driver_profile": {
      "id": 2,
      "user_id": 7,
      "status": "pending",
      "rating": 0,
      "user": {
        "id": 7,
        "name": "Carl Manahan",
        "email": "testrider@lesgo.com",
        "phone_number": "+639171234567"
      }
    },
    "service": {
      "id": 3,
      "name": "LesEat",
      "code": "LESEAT",
      "icon_url": null
    },
    "lesbuy_items": [
      {
        "id": 65,
        "order_id": 59,
        "name": "test",
        "quantity": 1,
        "estimated_price": "100.00"
      }
    ]
  }
  ''';
  
  try {
    final map = jsonDecode(jsonStr);
    final order = OrderDto.fromJson(map);
    print('Successfully parsed OrderDto! ID: \${order.id}');
    print('Driver ID: \${order.driverProfile?.id}');
  } catch (e, stack) {
    print('Error: \$e');
    print(stack);
  }
}
