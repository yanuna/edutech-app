import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  AppStorage._();
  static final AppStorage instance = AppStorage._();

  // v10+ uses custom ciphers and auto-migrates data stored under the old
  // (now-deprecated) EncryptedSharedPreferences backend on first access.
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRole = 'user_role';
  static const _keyEmailReq = 'verify_email_required';
  static const _keyMobileReq = 'verify_mobile_required';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);
  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<void> saveUserId(int id) =>
      _storage.write(key: _keyUserId, value: id.toString());
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> saveRole(String role) =>
      _storage.write(key: _keyRole, value: role);
  Future<String?> getRole() => _storage.read(key: _keyRole);

  // Which verifications the backend currently requires (persisted so the
  // session restore on app launch can route correctly).
  Future<void> saveVerifyFlags({
    required bool email,
    required bool mobile,
  }) async {
    await _storage.write(key: _keyEmailReq, value: email ? '1' : '0');
    await _storage.write(key: _keyMobileReq, value: mobile ? '1' : '0');
  }

  Future<bool> emailVerifyRequired() async =>
      (await _storage.read(key: _keyEmailReq)) != '0'; // default true
  Future<bool> mobileVerifyRequired() async =>
      (await _storage.read(key: _keyMobileReq)) == '1'; // default false

  Future<void> clearAll() => _storage.deleteAll();
}
