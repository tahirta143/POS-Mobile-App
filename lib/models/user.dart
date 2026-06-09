class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  final bool isAdmin;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? json['username'] ?? json['first_name'],
      email: json['email'],
      role: json['role'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true || json['role'] == 'admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_admin': isAdmin,
    };
  }
}
