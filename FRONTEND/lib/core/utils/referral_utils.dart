/// Helpers for referral / invite-friends flows.
class ReferralUtils {
  ReferralUtils._();

  static const String appName = 'LEZGO';

  /// Stable code when API has not assigned one yet.
  static String generateFallbackCode(int userId, {String? name}) {
    final suffix = userId.toString().padLeft(5, '0');
    final prefix = _namePrefix(name);
    return '$prefix$suffix'.toUpperCase();
  }

  static String _namePrefix(String? name) {
    if (name == null || name.trim().isEmpty) return 'LEZ';
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleaned.isEmpty) return 'LEZ';
    return cleaned.length >= 3 ? cleaned.substring(0, 3) : cleaned.padRight(3, 'X');
  }

  static String displayCode(String? apiCode, int userId, {String? name}) {
    if (apiCode != null && apiCode.trim().isNotEmpty) {
      return apiCode.trim().toUpperCase();
    }
    return generateFallbackCode(userId, name: name);
  }

  static String inviteMessage({
    required String referralCode,
    String? userName,
  }) {
    final who = userName != null && userName.isNotEmpty ? '$userName invites you' : 'Join me';
    return '$who on $appName! Use my referral code $referralCode when you sign up '
        'and we both earn rewards. Download $appName today!';
  }
}
