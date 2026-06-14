import 'package:shared_preferences/shared_preferences.dart';

/// Persists remembered login email and account type only — never passwords.
/// Long-lived sessions rely on tokens in [SecureStorageService].
class RememberMeService {
  RememberMeService._();

  static const Duration sessionDuration = Duration(days: 30);
  static const String _enabledKey = 'remember_me_enabled';
  static const String _expiresKey = 'remember_me_expires_at';
  static const String _emailKey = 'remember_me_email';
  static const String _legacyPasswordKey = 'remember_me_password';
  static const String _accountTypeKey = 'remember_me_account_type';

  static SharedPreferences? _prefs;

  /// Clears cached preferences — for unit tests only.
  static void resetForTests() {
    _prefs = null;
  }

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _purgeLegacyPassword();
  }

  static Future<void> _purgeLegacyPassword() async {
    if (_store.containsKey(_legacyPasswordKey)) {
      await _store.remove(_legacyPasswordKey);
    }
  }

  static SharedPreferences get _store {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('RememberMeService.init() must be called first');
    }
    return prefs;
  }

  static bool isEnabled() => _store.getBool(_enabledKey) ?? false;

  static bool isSessionValid() {
    if (!isEnabled()) return false;

    final expiresAt = _store.getInt(_expiresKey);
    if (expiresAt == null) return false;

    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  static String? get savedEmail {
    if (!isEnabled()) return null;
    return _store.getString(_emailKey);
  }

  static String? get savedAccountType => _store.getString(_accountTypeKey);

  static bool matchesAccountType(String accountType) {
    final saved = savedAccountType;
    if (saved == null || saved.isEmpty) return true;
    return saved == accountType;
  }

  static bool get hasSavedEmail {
    if (!isEnabled()) return false;
    final email = savedEmail;
    return email != null && email.isNotEmpty;
  }

  static Future<void> savePreference({
    required bool enabled,
    required String email,
    required String accountType,
  }) async {
    if (!enabled) {
      await clearPreference();
      return;
    }

    await _store.setBool(_enabledKey, true);
    await _store.setString(_emailKey, email.trim());
    await _store.setString(_accountTypeKey, accountType);
    await _purgeLegacyPassword();
    await _refreshExpiry();
  }

  static Future<void> refreshExpiry() async {
    if (!isEnabled()) return;
    await _refreshExpiry();
  }

  static Future<void> _refreshExpiry() async {
    await _store.setInt(
      _expiresKey,
      DateTime.now().add(sessionDuration).millisecondsSinceEpoch,
    );
  }

  static Future<void> clearPreference() async {
    await _store.remove(_enabledKey);
    await _store.remove(_expiresKey);
    await _store.remove(_emailKey);
    await _store.remove(_legacyPasswordKey);
    await _store.remove(_accountTypeKey);
  }

  static Future<void> clearSession() async {
    await clearPreference();
  }
}
