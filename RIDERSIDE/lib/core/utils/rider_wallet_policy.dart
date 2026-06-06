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
      return 'Your wallet balance is PHP ${balance.toStringAsFixed(2)}. '
          'Insufficient balance to accept bookings. Please top up your wallet '
          '(minimum PHP ${minimumBalanceToAccept.toStringAsFixed(0)} required).';
    }

    return 'Insufficient wallet balance to accept bookings. '
        'Please top up to at least PHP ${minimumBalanceToAccept.toStringAsFixed(0)}.';
  }

  static String lowBalanceWarningMessage(double balance) {
    if (!shouldShowTopUpWarning(balance)) return '';

    if (balance <= maintainingBalance) {
      return 'Wallet balance is PHP ${balance.toStringAsFixed(2)}. '
          'Please top up — insufficient balance to accept new bookings.';
    }

    return 'Wallet balance is below PHP ${minimumBalanceToAccept.toStringAsFixed(0)}. '
        'Top up to accept bookings.';
  }
}
