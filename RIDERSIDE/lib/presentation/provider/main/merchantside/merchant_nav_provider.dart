import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum defining the navigation tabs for the Merchant app
enum MerchantNavType { book, orders, profile, menu, lespay }

/// Provider to manage the currently selected navigation index
final merchantNavProvider = StateProvider<MerchantNavType>(
  (ref) => MerchantNavType.book,
);
