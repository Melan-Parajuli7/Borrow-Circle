import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/token_storage.dart';
import 'app_exception.dart';

/// Thin wrapper over [http.Client] that communicates with the Node.js Express
/// backend.
///
/// Responsibilities:
/// - Builds request headers (JSON content type + cookie-based JWT session)
/// - Persists access / refresh tokens received via `Set-Cookie`
/// - Transparently refreshes the access token on a 401 and retries once
/// - Executes GET / POST / PUT / PATCH / DELETE requests against
///   [AppConstants.baseUrl]
/// - Maps HTTP status codes to typed [AppException] subclasses
///
/// All repositories depend on an [ApiClient] instance (constructor injection)
/// rather than calling a static service, matching the MVVM reference layout.
class ApiClient {
  /// Creates an [ApiClient] with the given HTTP client.
  ///
  /// The [client] is used for every request. Token persistence is handled by
  /// [TokenStorage] (a thin wrapper over `SharedPreferences`).
  ApiClient(this._client);

  /// Underlying HTTP client used to make network requests.
  final http.Client _client;

  /// Timeout applied to every request.
  static const Duration _timeout = Duration(seconds: 20);

  // ---------------- Public Methods ----------------

  /// Sends a GET request to `[baseUrl][apiPrefix][path]`.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _call(() => _client.get(_uri(path, query), headers: _headers()));

  /// Sends a POST request.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool refreshOn401 = true,
  }) =>
      _call(
        () => _client.post(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        ),
        refreshOn401: refreshOn401,
      );

  /// Sends a PUT request.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _call(
        () => _client.put(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        ),
      );

  /// Sends a PATCH request.
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _call(
        () => _client.patch(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        ),
      );

  /// Sends a DELETE request.
  Future<Map<String, dynamic>> delete(String path) =>
      _call(() => _client.delete(_uri(path), headers: _headers()));

  /// Sends a multipart request (for file uploads).
  ///
  /// [method] is `"POST"` or `"PUT"`. [filePath] can be null (no new image).
  Future<Map<String, dynamic>> multipart(
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

  // ---------------- Helpers ----------------

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) q[key] = '$value';
    });
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.apiPrefix}$path',
    );
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';

    final cookies = <String>[];
    if (TokenStorage.accessToken != null) {
      cookies.add('accessToken=${TokenStorage.accessToken}');
    }
    if (TokenStorage.refreshToken != null) {
      cookies.add('refreshToken=${TokenStorage.refreshToken}');
    }
    if (cookies.isNotEmpty) headers['Cookie'] = cookies.join('; ');
    return headers;
  }

  /// Saves cookies from the response (used for token persistence).
  static Future<void> _saveCookies(http.Response res) async {
    final header = res.headers['set-cookie'];
    if (header == null) return;

    final matches =
        RegExp(r'(accessToken|refreshToken)=([^;,\s]*)').allMatches(header);
    for (final m in matches) {
      final name = m.group(1);
      final value = m.group(2) ?? '';
      final token = value.isEmpty ? null : value;
      if (name == 'accessToken') await TokenStorage.setAccess(token);
      if (name == 'refreshToken') await TokenStorage.setRefresh(token);
    }
  }

  /// Attempts to refresh the access token using the refresh token.
  Future<bool> _refresh() async {
    try {
      final res = await _client
          .post(_uri(AppConstants.refreshEndpoint), headers: _headers())
          .timeout(_timeout);
      await _saveCookies(res);
      if (res.statusCode == 200) return true;
      await TokenStorage.clear();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Core request execution with automatic token refresh and error handling.
  Future<Map<String, dynamic>> _call(
    Future<http.Response> Function() send, {
    bool refreshOn401 = true,
  }) async {
    try {
      var res = await send().timeout(_timeout);
      await _saveCookies(res);

      // Handle token expiration
      if (res.statusCode == 401 &&
          refreshOn401 &&
          TokenStorage.refreshToken != null) {
        if (await _refresh()) {
          res = await send().timeout(_timeout);
          await _saveCookies(res);
        }
      }
      return _handle(res);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw FetchDataException(
          'The server took too long to respond. Try again.');
    } catch (_) {
      throw FetchDataException(
          'Cannot connect to the server. Check your internet and the API address.');
    }
  }

  /// Processes the HTTP response and returns the JSON body or throws an
  /// [AppException].
  Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      }
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    throw BadRequestException(
      body['message'] as String? ?? 'Something went wrong (${res.statusCode})',
      res.statusCode,
    );
  }
}