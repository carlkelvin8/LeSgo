import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class LocalStorageService {
  static const String authTokenKey = 'auth_token';

  final SharedPreferences prefs;
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();

  LocalStorageService(this.prefs);

  Future<void> saveToken(String token) async {
    await prefs.setString(authTokenKey, token);
    _tokenController.add(token);
  }

  String? get token {
    final token = prefs.getString(authTokenKey);
    print('🔵 LocalStorageService: Getting token from SharedPreferences: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
    return token;
  }

  Stream<String?> get tokenStream async* {
    yield token;
    yield* _tokenController.stream;
  }

  Future<void> clearToken() async {
    await prefs.remove(authTokenKey);

    _tokenController.add(null);
  }

  void dispose() {
    _tokenController.close();
  }
}
