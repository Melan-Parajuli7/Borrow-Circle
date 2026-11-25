import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
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
  /// Creates an [ApiClient] with the given HTTP client and preferences store.
  ///
  /// The [client] is used for every request. Token persistence is handled by
  /// [prefs] (a [SharedPreferences] instance).
  ApiClient(this._client, this._prefs);

  /// Underlying HTTP client used to make network requests.
  final http.Client _client;

  /// SharedPreferences instance used to retrieve the stored authentication token.
  final SharedPreferences _prefs;

  /// Timeout applied to every request.
  static const Duration _timeout = Duration(seconds: 20);

  // ---------------- Public Methods ----------------

  /// Sends a GET request to `[baseUrl][apiPrefix][path]`.
  ///
  /// Returns the decoded JSON body as a [Map] on success (2xx). Throws a typed
  /// [AppException] on client or server errors, and [FetchDataException] on
  /// network failures.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _call(() => _client.get(_uri(path, query), headers: _headers()));

  /// Sends a POST request to `[baseUrl][apiPrefix][path]` with an optional JSON
  /// [body].
  ///
  /// Returns the decoded JSON body as a [Map] on success (2xx). Throws a typed
  /// [AppException] on client or server errors, and [FetchDataException] on
  /// network failures. When [refreshOn401] is true (the default), a 401
  /// triggers a token refresh and a single retry.
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

  /// Sends a PUT request to `[baseUrl][apiPrefix][path]` with an optional JSON
  /// [body].
  ///
  /// Returns the decoded JSON body as a [Map] on success (2xx). Throws a typed
  /// [AppException] on client or server errors, and [FetchDataException] on
  /// network failures.
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

  /// Sends a PATCH request to `[baseUrl][apiPrefix][path]` with an optional
  /// JSON [body].
  ///
  /// Returns the decoded JSON body as a [Map] on success (2xx). Throws a typed
  /// [AppException] on client or server errors, and [FetchDataException] on
  /// network failures.
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

  /// Sends a DELETE request to `[baseUrl][apiPrefix][path]`.
  ///
  /// Returns the decoded JSON body as a [Map] on success (2xx). Throws a typed
  /// [AppException] on client or server errors, and [FetchDataException] on
  /// network failures.
  Future<Map<String, dynamic>> delete(String path) =>
      _call(() => _client.delete(_uri(path), headers: _headers()));

  /// Sends a multipart request (for file uploads).
  ///
  /// [method] is `"POST"` or `"PUT"`. [filePath] can be null (no new image).
  /// Returns the decoded JSON body as a [Map] on success (2xx).
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
    final accessToken = _prefs.getString(AppConstants.tokenKey) ?? '';
    final refreshToken = _prefs.getString(AppConstants.refreshTokenKey) ?? '';
    if (accessToken.isNotEmpty) {
      cookies.add('accessToken=$accessToken');
    }
    if (refreshToken.isNotEmpty) {
      cookies.add('refreshToken=$refreshToken');
    }
    if (cookies.isNotEmpty) headers['Cookie'] = cookies.join('; ');
    return headers;
  }

  /// Saves cookies from the response (used for token persistence).
  Future<void> _saveCookies(http.Response res) async {
    final header = res.headers['set-cookie'];
    if (header == null) return;

    final matches =
        RegExp(r'(accessToken|refreshToken)=([^;,\s]*)').allMatches(header);
    for (final m in matches) {
      final name = m.group(1);
      final value = m.group(2) ?? '';
      final token = value.isEmpty ? null : value;
      if (name == 'accessToken') {
        if (token == null) {
          await _prefs.remove(AppConstants.tokenKey);
        } else {
          await _prefs.setString(AppConstants.tokenKey, token);
        }
      }
      if (name == 'refreshToken') {
        if (token == null) {
          await _prefs.remove(AppConstants.refreshTokenKey);
        } else {
          await _prefs.setString(AppConstants.refreshTokenKey, token);
        }
      }
    }
  }

  /// Attempts to refresh the access token using the refresh token.
  ///
  /// Returns `true` if the refresh succeeded, `false` otherwise. On failure the
  /// stored tokens are cleared.
  Future<bool> _refresh() async {
    try {
      final res = await _client
          .post(_uri(AppConstants.refreshEndpoint), headers: _headers())
          .timeout(_timeout);
      await _saveCookies(res);
      if (res.statusCode == 200) return true;
      await _clearTokens();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clears both tokens from [SharedPreferences].
  Future<void> _clearTokens() async {
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
  }

  /// Core request execution with automatic token refresh and error handling.
  ///
  /// [send] is the callback that performs the actual HTTP call. When
  /// [refreshOn401] is true and the response is a 401, the access token is
  /// refreshed and the request is retried once.
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
          _prefs.getString(AppConstants.refreshTokenKey) != null) {
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
  ///
  /// For 2xx status codes the decoded JSON body is returned. For any other
  /// status code a [BadRequestException] is thrown with the error message
  /// extracted from the response body.
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
