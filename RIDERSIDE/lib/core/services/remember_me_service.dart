import 'package:shared_preferences/shared_preferences.dart';

class RememberMeService {
  RememberMeService._();

  static const Duration sessionDuration = Duration(days: 30);
  static const String _enabledKey = 'remember_me_enabled';
  static const String _expiresKey = 'remember_me_expires_at';
  static const String _emailKey = 'remember_me_email';
  static const String _passwordKey = 'remember_me_password';
  static const String _accountTypeKey = 'remember_me_account_type';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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

  static String? get savedPassword {
    if (!isEnabled()) return null;
    return _store.getString(_passwordKey);
  }

  static String? get savedAccountType => _store.getString(_accountTypeKey);

  static bool matchesAccountType(String accountType) {
    final saved = savedAccountType;
    if (saved == null || saved.isEmpty) return true;
    return saved == accountType;
  }

  static bool get hasSavedCredentials {
    if (!isEnabled()) return false;
    final email = savedEmail;
    final password = savedPassword;
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  static Future<void> savePreference({
    required bool enabled,
    required String email,
    required String password,
    required String accountType,
  }) async {
    if (!enabled) {
      await clearPreference();
      return;
    }

    await _store.setBool(_enabledKey, true);
    await _store.setString(_emailKey, email);
    await _store.setString(_passwordKey, password);
    await _store.setString(_accountTypeKey, accountType);
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
    await _store.remove(_passwordKey);
    await _store.remove(_accountTypeKey);
  }

  static Future<void> clearSession() async {
    await clearPreference();
  }
}
