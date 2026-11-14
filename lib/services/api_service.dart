import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/services/token_storage.dart';

/// Any error from the server or the network. [message] is safe to show to the user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// The ONE place that talks to the backend. All other services use this.
///
/// It does 3 things for you:
///  1. adds the login cookies to every request
///  2. saves new cookies sent by the server (login / refresh)
///  3. if the access token expired, asks the server for a new one and retries
class ApiService {
  ApiService._();

  static const _timeout = Duration(seconds: 20);

  // ---------------- public methods ----------------

  static Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _call(() => http.get(_uri(path, query), headers: _headers()));

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool refreshOn401 = true, // false for login/register
  }) =>
      _call(
        () => http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})),
        refreshOn401: refreshOn401,
      );

  static Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _call(() => http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) =>
      _call(() => http.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<Map<String, dynamic>> delete(String path) =>
      _call(() => http.delete(_uri(path), headers: _headers()));

  /// For requests that upload an image (create item, update profile).
  /// [method] is "POST" or "PUT". [filePath] can be null (no new image).
  static Future<Map<String, dynamic>> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    String? fileField,
    String? filePath,
  }) =>
      _call(() async {
        final req = http.MultipartRequest(method, _uri(path));
        req.headers.addAll(_headers(json: false));
        req.fields.addAll(fields);
        if (fileField != null && filePath != null) {
          req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
        }
        return http.Response.fromStream(await req.send());
      });

  // ---------------- helpers ----------------

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) q[key] = '$value';
    });
    final uri = Uri.parse('${AppStatic.apiUrl}$path');
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';

    final cookies = <String>[];
    if (TokenStorage.accessToken != null) cookies.add('accessToken=${TokenStorage.accessToken}');
    if (TokenStorage.refreshToken != null) cookies.add('refreshToken=${TokenStorage.refreshToken}');
    if (cookies.isNotEmpty) headers['Cookie'] = cookies.join('; ');
    return headers;
  }

  /// Reads "Set-Cookie" from the response and stores the tokens.
  /// An empty value means the server wants the cookie removed (logout).
  static Future<void> _saveCookies(http.Response res) async {
    final header = res.headers['set-cookie'];
    if (header == null) return;

    final matches = RegExp(r'(accessToken|refreshToken)=([^;,\s]*)').allMatches(header);
    for (final m in matches) {
      final name = m.group(1);
      final value = m.group(2) ?? '';
      final token = value.isEmpty ? null : value;
      if (name == 'accessToken') await TokenStorage.setAccess(token);
      if (name == 'refreshToken') await TokenStorage.setRefresh(token);
    }
  }

  /// Gets a new access token using the refresh token.
  static Future<bool> _refresh() async {
    try {
      final res = await http.post(_uri('/users/refresh'), headers: _headers()).timeout(_timeout);
      await _saveCookies(res);
      if (res.statusCode == 200) return true;
      await TokenStorage.clear();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends the request, refreshes the token if needed, and turns errors into [ApiException].
  static Future<Map<String, dynamic>> _call(
    Future<http.Response> Function() send, {
    bool refreshOn401 = true,
  }) async {
    try {
      var res = await send().timeout(_timeout);
      await _saveCookies(res);

      // Access token expired -> refresh once and try again
      if (res.statusCode == 401 && refreshOn401 && TokenStorage.refreshToken != null) {
        if (await _refresh()) {
          res = await send().timeout(_timeout);
          await _saveCookies(res);
        }
      }
      return _handle(res);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Try again.');
    } catch (_) {
      throw ApiException('Cannot connect to the server. Check your internet and the API address.');
    }
  }

  static Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      }
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    throw ApiException(
      body['message'] as String? ?? 'Something went wrong (${res.statusCode})',
      res.statusCode,
    );
  }
}
