/// Validates the fields required before the delivery details sheet can close.
///
/// Keeping this check in the sheet prevents checkout from popping the route
/// and then trying to show an error against a disposed modal context.
String? validateCartDeliveryDetails({
  required String address,
  required bool hasPinnedLocation,
}) {
  if (address.trim().isEmpty) return 'Please enter a delivery address.';
  if (!hasPinnedLocation) {
    return 'Pin the delivery location so the delivery fee can be calculated.';
  }
  return null;
}
