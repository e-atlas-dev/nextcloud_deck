import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/core/errors/exceptions.dart';

/// Wraps [FlutterSecureStorage] and provides typed accessors for the three
/// credential values (server URL, username, app password).
///
/// Credentials are NEVER written to Hive, logs, or plaintext.
class SecureStorageService {
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  final FlutterSecureStorage _storage;

  // Write

  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String appPassword,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: SecureStorageKeys.serverUrl, value: serverUrl),
        _storage.write(key: SecureStorageKeys.username, value: username),
        _storage.write(key: SecureStorageKeys.appPassword, value: appPassword),
      ]);
    } catch (e) {
      throw const CacheException('Failed to save credentials securely.');
    }
  }

  // Read

  Future<String?> getServerUrl() => _read(SecureStorageKeys.serverUrl);

  Future<String?> getUsername() => _read(SecureStorageKeys.username);

  Future<String?> getAppPassword() => _read(SecureStorageKeys.appPassword);

  Future<({String serverUrl, String username, String appPassword})?>
  getCredentials() async {
    final url = await getServerUrl();
    final user = await getUsername();
    final pass = await getAppPassword();
    if (url == null || user == null || pass == null) return null;
    return (serverUrl: url, username: user, appPassword: pass);
  }

  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds != null;
  }

  // Delete

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // best-effort
    }
  }

  // Private

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}
