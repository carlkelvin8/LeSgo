/// Rider wallet rules for accepting bookings.
class RiderWalletPolicy {
  RiderWalletPolicy._();

  /// Minimum balance riders must maintain in their wallet.
  static const double maintainingBalance = 10.0;

  /// Minimum balance required before accepting a new booking.
  static const double minimumBalanceToAccept = 11.0;

  static bool canAcceptBooking(double balance) =>
      balance >= minimumBalanceToAccept;

  static bool shouldShowTopUpWarning(double balance) =>
      balance < minimumBalanceToAccept;

  static String acceptBlockedMessage(double balance) {
    if (canAcceptBooking(balance)) return '';

    if (balance <= maintainingBalance) {
      return 'Your LesPay balance is PHP ${balance.toStringAsFixed(2)}. '
          'Insufficient balance to accept bookings. Please top up your LesPay '
          '(minimum PHP ${minimumBalanceToAccept.toStringAsFixed(0)} required).';
    }

    return 'Insufficient LesPay balance to accept bookings. '
        'Please top up to at least PHP ${minimumBalanceToAccept.toStringAsFixed(0)}.';
  }

  static String lowBalanceWarningMessage(double balance) {
    if (!shouldShowTopUpWarning(balance)) return '';

    if (balance <= maintainingBalance) {
      return 'LesPay balance is PHP ${balance.toStringAsFixed(2)}. '
          'Please top up — insufficient balance to accept new bookings.';
    }

    return 'LesPay balance is below PHP ${minimumBalanceToAccept.toStringAsFixed(0)}. '
        'Top up to accept bookings.';
  }
}
