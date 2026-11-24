import 'user_model.dart';

/// Authentication response returned by login and register endpoints.
///
/// Bundles the session tokens with the authenticated user profile.
class AuthResponse {
  /// Access token for authenticated requests.
  final String accessToken;

  /// Refresh token for obtaining new access tokens.
  final String refreshToken;

  /// The authenticated user profile.
  final UserModel user;

  /// Creates an [AuthResponse] with the given tokens and user.
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Creates an [AuthResponse] from a JSON map as returned by the API.
  ///
  /// Expects keys: `access_token`, `refresh_token`, `user`.
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}