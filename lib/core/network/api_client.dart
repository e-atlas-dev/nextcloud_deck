import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:nextcloud_deck/core/constants/api_constants.dart';
import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/storage/secure_storage_service.dart';

/// Low-level HTTP client with Basic Auth, proper error handling and
/// support for both JSON-object and JSON-array responses.
class ApiClient {
  ApiClient({required this.secureStorage});

  final SecureStorageService secureStorage;

  Future<Map<String, dynamic>> get(String url) => _sendObject('GET', url);
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) =>
      _sendObject('POST', url, body: body);
  Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) =>
      _sendObject('PUT', url, body: body);
  Future<void> delete(String url) => _sendRaw('DELETE', url).then((_) {});

  Future<List<Map<String, dynamic>>> getList(String url) async {
    final raw = await _sendRaw('GET', url);
    if (raw.body.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map<String, dynamic>) {
        final first = decoded.values.firstOrNull;
        if (first is List) return first.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<Map<String, dynamic>> _sendObject(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final raw = await _sendRaw(method, url, body: body);
    if (raw.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'_data': decoded};
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<http.Response> _sendRaw(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final creds = await secureStorage.getCredentials();
    if (creds == null) throw const UnauthorizedException();

    final token = base64.encode(
      utf8.encode('${creds.username}:${creds.appPassword}'),
    );

    // Only send Content-Type when there is a body
    final headers = <String, String>{
      HttpHeaders.authorizationHeader: 'Basic $token',
      HttpHeaders.acceptHeader: 'application/json',
      'OCS-APIREQUEST': 'true',
      if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
    };

    http.Response response;
    try {
      final request = http.Request(method, Uri.parse(url))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);

      final streamed = await request.send().timeout(
        ApiConstants.receiveTimeout,
      );
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }

    _checkStatus(response);
    return response;
  }

  void _checkStatus(http.Response response) {
    final c = response.statusCode;
    if (c >= 200 && c <= 299) return;
    switch (c) {
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const NotFoundException();
      // 409 Conflict - two users edited the same resource simultaneously.
      case 409:
        throw const ConflictException();
      default:
        throw ServerException.withCode(c);
    }
  }
}
