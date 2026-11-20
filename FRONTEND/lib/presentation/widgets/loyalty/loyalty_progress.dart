import '../../provider/main/loyalty/loyalty_provider.dart';

/// Pure helpers behind the Redeem Points screen, kept out of the widgets so the
/// rules (what is the next goal, what can I redeem) are easy to test.
class LoyaltyProgress {
  LoyaltyProgress._();

  static bool canRedeem(LoyaltyReward reward, int points) =>
      reward.available && points >= reward.pointsCost;

  /// The closest reward the customer cannot afford yet: the cheapest available
  /// reward that costs more than [points]. Null when nothing is left to aim for.
  static LoyaltyReward? nextGoal(int points, List<LoyaltyReward> rewards) {
    LoyaltyReward? best;
    for (final reward in rewards) {
      if (!reward.available || reward.pointsCost <= points) continue;
      if (best == null || reward.pointsCost < best.pointsCost) best = reward;
    }
    return best;
  }

  static int redeemableCount(int points, List<LoyaltyReward> rewards) =>
      rewards.where((r) => canRedeem(r, points)).length;

  /// Rewards the customer can redeem right now come first, then the rest from
  /// cheapest to most expensive. Unavailable rewards go last.
  static List<LoyaltyReward> sorted(int points, List<LoyaltyReward> rewards) {
    int rank(LoyaltyReward r) => canRedeem(r, points) ? 0 : (r.available ? 1 : 2);
    final copy = List<LoyaltyReward>.from(rewards);
    copy.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.pointsCost.compareTo(b.pointsCost);
    });
    return copy;
  }

  /// 0.0 .. 1.0 progress towards [cost].
  static double fraction(int points, int cost) {
    if (cost <= 0) return 1;
    return (points / cost).clamp(0.0, 1.0).toDouble();
  }

  static int pointsToGo(int points, int cost) => (cost - points).clamp(0, cost);

  /// 1250 -> "1,250".
  static String format(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
