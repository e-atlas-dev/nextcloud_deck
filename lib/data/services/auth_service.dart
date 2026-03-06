import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/storage/secure_storage_service.dart';

/// Result returned after a successful Login Flow v2 exchange.
class LoginCredentials {
  const LoginCredentials({
    required this.serverUrl,
    required this.loginName,
    required this.appPassword,
  });

  final String serverUrl;
  final String loginName;
  final String appPassword;
}

/// Implements the Nextcloud Login Flow v2.
/// Reference: https://docs.nextcloud.com/server/latest/developer_manual/
///            client_apis/LoginFlow/index.html
///
/// Steps:
///  1. POST to /index.php/login/v2 → receive {poll, login} URLs
///  2. Open the `login` URL in a WebView for the user to authenticate
///  3. Poll `poll.endpoint` with `poll.token` until credentials are returned
///  4. Store credentials in SecureStorage
class AuthService {
  AuthService({required this.secureStorage});

  final SecureStorageService secureStorage;

  /// Initiates Login Flow v2 against [serverUrl].
  ///
  /// Returns a record with:
  ///  - [loginUrl]  → open this in a WebView
  ///  - [pollFuture] → awaits polling completion; resolves with credentials
  ///  - [cancel]    → call to abort polling
  Future<
    ({
      String loginUrl,
      Future<LoginCredentials> pollFuture,
      void Function() cancel,
    })
  >
  initiateLogin(String serverUrl, String appName) async {
    final cleanUrl = serverUrl.trimRight().replaceAll(RegExp(r'/$'), '');

    // Step 1: Initiate the flow
    final initUrl = '$cleanUrl${ApiConstants.loginV2Initiate}';
    http.Response response;
    try {
      // The appName parameter appears in Nextcloud's "Connected devices" list
      // (Settings → Security). Without it, the entry defaults to "Dart", which
      // is the HTTP client's default user-agent. Sending the app name as the
      // User-Agent is the recommended approach according to the Login Flow v2
      // specification.
      response = await http
          .post(Uri.parse(initUrl), headers: {'User-Agent': appName})
          .timeout(ApiConstants.connectTimeout);
    } on Exception catch (e) {
      throw AuthFlowException('Cannot reach $cleanUrl: $e');
    }

    if (response.statusCode != 200) {
      throw AuthFlowException(
        'Server returned HTTP ${response.statusCode} for login init.',
      );
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ParseException('Unexpected login init response.');
    }

    final loginUrl = body['login'] as String?;
    final poll = body['poll'] as Map<String, dynamic>?;

    if (loginUrl == null || poll == null) {
      throw const AuthFlowException('Malformed login init response.');
    }

    final pollToken = poll['token'] as String;
    final pollEndpoint = poll['endpoint'] as String;

    // Step 3: Start polling in background
    final cancelToken = _CancelToken();
    final pollFuture = _poll(pollEndpoint, pollToken, cancelToken);

    return (
      loginUrl: loginUrl,
      pollFuture: pollFuture,
      cancel: cancelToken.cancel,
    );
  }

  Future<LoginCredentials> _poll(
    String endpoint,
    String token,
    _CancelToken cancelToken,
  ) async {
    for (var i = 0; i < ApiConstants.pollMaxAttempts; i++) {
      if (cancelToken.isCancelled) {
        throw const AuthFlowException('Login cancelled by user.');
      }

      await Future<void>.delayed(ApiConstants.pollInterval);

      if (cancelToken.isCancelled) {
        throw const AuthFlowException('Login cancelled by user.');
      }

      try {
        final response = await http
            .post(Uri.parse(endpoint), body: {'token': token})
            .timeout(ApiConstants.connectTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final server = data['server'] as String?;
          final loginName = data['loginName'] as String?;
          final appPassword = data['appPassword'] as String?;

          if (server == null || loginName == null || appPassword == null) {
            throw const ParseException('Unexpected poll response.');
          }

          return LoginCredentials(
            serverUrl: server.replaceAll(RegExp(r'/$'), ''),
            loginName: loginName,
            appPassword: appPassword,
          );
        }
        // 404 means still waiting; any other code is unexpected
      } catch (e) {
        if (e is AppException) rethrow;
        // Network hiccups during polling are tolerated
      }
    }

    throw const PollTimeoutException();
  }

  /// Persists credentials after a successful login.
  Future<void> saveCredentials(LoginCredentials creds) =>
      secureStorage.saveCredentials(
        serverUrl: creds.serverUrl,
        username: creds.loginName,
        appPassword: creds.appPassword,
      );

  /// Clears all stored credentials and local data markers.
  Future<void> logout() => secureStorage.clearAll();
}

class _CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
