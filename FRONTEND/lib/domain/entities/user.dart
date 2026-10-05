class User {
  final String id;
  final String email;
  final String name;
  final String? token;
  final String? role;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.token,
    this.role,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
      role: role ?? this.role,
    );
  }
}


