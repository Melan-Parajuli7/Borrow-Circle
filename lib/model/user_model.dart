class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? avatar; // file name only, see AppStatic.avatarUrl()
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'user',
    this.avatar,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] as num).toInt(),
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        avatar: j['avatar'] as String?,
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  /// First letters for the avatar placeholder: "Nabin Dhakal" -> "ND"
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
