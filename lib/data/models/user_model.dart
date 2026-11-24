/// User model representing a registered user in the BorrowCircle application.
///
/// Contains user identification, profile information, and authentication-related data.
class UserModel {
  /// Unique identifier of the user.
  final int id;

  /// Full display name of the user.
  final String fullName;

  /// Email address of the user (used for login).
  final String email;

  /// Role of the user (e.g., 'user', 'admin').
  final String role;

  /// Avatar file name (stored on backend), if any.
  final String? avatar;

  /// Timestamp when the user account was created.
  final DateTime? createdAt;

  /// Creates a [UserModel] with the given properties.
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'user',
    this.avatar,
    this.createdAt,
  });

  /// Creates a [UserModel] from a JSON map as returned by the API.
  ///
  /// Expects keys: `id`, `full_name`, `email`, `role`, `avatar`, `created_at`.
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] as num).toInt(),
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        avatar: j['avatar'] as String?,
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  /// Converts this [UserModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'avatar': avatar,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Returns the user's initials for avatar placeholder (e.g., "Nabin Dhakal" -> "ND").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}