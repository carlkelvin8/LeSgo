// Fake data for the rider application
import '../../../domain/entities/rider_booking.dart';

final List<Map<String, String>> riderPersonalTasks = [
  {'title': 'Resolve delivery issues', 'timeText': 'Today - 10 am'},
  {'title': 'Resolve delivery issues', 'timeText': 'Today - 10 am'},
  {'title': 'Resolve delivery issues', 'timeText': 'Today - 10 am'},
  {'title': 'Resolve delivery issues', 'timeText': 'Today - 10 am'},
];

final Map<String, String> riderProfileInfoData = {
  'Name:': 'Juan Dela Cruz',
  'Contact:': '09987654321',
  'Address:': 'Claveria, Cagayan',
  'Vehicle:': 'Yamaha Aerox',
  'Plate number:': 'YMXU2',
  'Referral Code:': 'LESGOFEHL',
};

final Map<String, String> riderWalletInfoData = {
  'Balance': 'PHP 411.25',
  'Deposit': 'PHP 2000.00',
};

// History dashboard data
final Map<String, dynamic> riderHistoryDashboardData = {
  'totalBookings': 40,
  'performance': 5,
};

// Bookings mock data
final List<RiderBooking> riderMockBookings = [
  const RiderBooking(
    id: '1',
    restaurantName: 'Sunsets Restaurant',
    address: 'Java Commercial Building, Libertad, Cagayan de Oro',
    logoPath: 'assets/images/logo.png',
    category: BookingCategory.lesEat,
    billingAmount: 'PHP 340.00',
    billingMethod: 'Cash on Delivery',
    currentStatus: BookingStatus.pending,
  ),
  const RiderBooking(
    id: '2',
    restaurantName: 'Jollibee',
    address: 'Java Commercial Building, Libertad, Cagayan de Oro',
    logoPath: 'assets/images/logo.png',
    category: BookingCategory.lesEat,
    billingAmount: 'PHP 215.00',
    billingMethod: 'GCash',
    currentStatus: BookingStatus.cooking,
  ),
  const RiderBooking(
    id: '3',
    restaurantName: 'Juan Dela Cruz',
    address: 'Claveria, Cagayan de Oro',
    logoPath: 'assets/images/logo.png',
    category: BookingCategory.lesRide,
    billingAmount: 'PHP 120.00',
    billingMethod: 'Cash on Delivery',
    currentStatus: BookingStatus.onTheWay,
  ),
  const RiderBooking(
    id: '4',
    restaurantName: 'SM City CDO — Groceries',
    address: 'Limketkai Drive, Cagayan de Oro',
    logoPath: 'assets/images/logo.png',
    category: BookingCategory.lesBuy,
    billingAmount: 'PHP 890.00',
    billingMethod: 'Cash on Delivery',
    currentStatus: BookingStatus.pending,
  ),
];

// Mission mock data
final List<Map<String, dynamic>> riderMissions = [
  {'title': 'Book 10 orders today', 'reward': 'PHP 10', 'progress': 0.8},
  {'title': 'Refer 1 friend today', 'reward': 'PHP 10', 'progress': 0.6},
  {'title': 'Achieve 25 bookings', 'reward': 'PHP 25', 'progress': 0.7},
  {'title': 'Get 1 Lesride booking today', 'reward': 'PHP 5', 'progress': 0.4},
  {'title': 'Get a 5 star rating today', 'reward': 'PHP 5', 'progress': 0.5},
];

final List<Map<String, dynamic>> merchantMissions = [
  {'title': 'Book 10 orders today', 'reward': 'PHP 10', 'progress': 0.8},
  {'title': 'Refer 1 friend today', 'reward': 'PHP 10', 'progress': 0.6},
  {'title': 'Achieve 25 bookings', 'reward': 'PHP 25', 'progress': 0.7},
  {'title': 'Get 1 Lesride booking today', 'reward': 'PHP 5', 'progress': 0.4},
  {'title': 'Get a 5 star rating today', 'reward': 'PHP 5', 'progress': 0.5},
];

final Map<String, String> merchantProfileInfoData = {
  'greeting': 'LeSgo,\nPartner!',
  'restaurant': 'Sun Sets Restaurant',
  'contact': '09987654321',
  'address': 'Claveria, Cagayan',
  'referralCode': 'LESGOSUNSETS',
};

final List<Map<String, String>> merchantFoodMenuItems = [
  {
    'name': 'Sun Sets Pizza',
    'description': 'Signature pizza baked with sunset crust.',
    'price': '300.00',
    'category': 'Pizza',
    'sizes': '9 INCHES,12 INCHES',
  },
  {
    'name': 'Sun Sets Sisig',
    'description': 'Savory sizzling sisig made fresh to order.',
    'price': '140.00',
    'category': 'Rice Meals',
    'sizes': 'Regular,Large',
  },
  {
    'name': 'Sun Sets Fries',
    'description': 'Crispy fries with your choice of toppings.',
    'price': '120.00',
    'category': 'Chicken',
    'sizes': 'Solo,Sharing',
  },
  {
    'name': 'Cookies',
    'description': 'Soft-baked cookies for snack cravings.',
    'price': '40.00',
    'category': 'Pasta',
    'sizes': 'Box of 6,Box of 12',
  },
  {
    'name': 'Matcha Latte',
    'description': 'Premium matcha drink with smooth finish.',
    'price': '80.00',
    'category': 'More',
    'sizes': '12 OZ,16 OZ',
  },
];

final List<Map<String, String>> merchantFoodCategories = [
  {'label': 'Pizza', 'icon': '🍕'},
  {'label': 'Pasta', 'icon': '🍝'},
  {'label': 'Rice Meals', 'icon': '🍛'},
  {'label': 'Chicken', 'icon': '🍗'},
  {'label': 'More', 'icon': '⊞'},
];

// History bookings data
final List<Map<String, String>> riderHistoryBookings = [
  {
    'id': '#53472920',
    'referenceNumber': 'R#1234',
    'customerName': 'Juan Dela Cruz',
    'customerContact': '0939976890',
    'restaurantName': 'Sunsets Restaurant',
    'address': 'Java Commercial Building, Libertad, ...',
    'pu': '',
    'do': '',
    'price': '340.00',
    'status': 'Processing',
    'timestamp': 'March 29, 2025, 5:05 PM',
  },
  {
    'id': '#8790908',
    'referenceNumber': 'R#1234',
    'customerName': 'Juan Dela Cruz',
    'customerContact': '0939976890',
    'restaurantName': 'Jollibee',
    'address': 'Java Commercial Building, Libertad, ...',
    'pu': '',
    'do': '',
    'price': '340.00',
    'status': 'Completed',
    'timestamp': 'March 29, 2025, 5:05 PM',
  },
  {
    'id': '#25178197',
    'referenceNumber': 'R#1234',
    'customerName': 'Juan Dela Cruz',
    'customerContact': '0939976890',
    'restaurantName': 'McDonalds',
    'address': 'Java Commercial Building, Libertad, ...',
    'pu': '',
    'do': '',
    'price': '340.00',
    'status': 'Cancelled',
    'timestamp': 'March 29, 2025, 5:05 PM',
  },
  {
    'id': '#11293847',
    'referenceNumber': 'R#1234',
    'customerName': 'Juan Dela Cruz',
    'customerContact': '0939976890',
    'restaurantName': 'Chowking',
    'address': 'Rizal Avenue, Tuguegarao City, ...',
    'pu': '',
    'do': '',
    'price': '250.00',
    'status': 'Completed',
    'timestamp': 'March 29, 2025, 5:05 PM',
  },
  {
    'id': '#99102938',
    'referenceNumber': 'R#1234',
    'customerName': 'Juan Dela Cruz',
    'customerContact': '0939976890',
    'restaurantName': 'Mang Inasal',
    'address': 'Luna Street, Centro, Tuguegarao, ...',
    'pu': '',
    'do': '',
    'price': '180.00',
    'status': 'Processing',
    'timestamp': 'March 29, 2025, 5:05 PM',
  },
];
