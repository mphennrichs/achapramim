class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  final String? username;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.username,
  });

  bool get usernamePending => username == null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      active: json['active'] as bool,
      username: json['username'] as String?,
    );
  }
}
