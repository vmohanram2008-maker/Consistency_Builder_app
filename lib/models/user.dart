class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.createdAt,
    this.passwordHash,
    this.salt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? passwordHash;
  final String? salt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'passwordHash': passwordHash,
      'salt': salt,
    };
  }

  static AppUser fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      passwordHash: map['passwordHash'] as String?,
      salt: map['salt'] as String?,
    );
  }
}
