class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String bio;
  final String? avatarUrl;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
      gender: json['gender'] ?? "",
      email: json['email'] ?? "",
      bio: json['bio'] ?? "",
      avatarUrl: json['avatar_url'],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "gender": gender,
      "email": email,
      "bio": bio,
      "avatar_url": avatarUrl,
      "is_admin": isAdmin,
      // ❗ ID NÃO VAI NO JSON — o Supabase gera automaticamente
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? gender,
    String? email,
    String? bio,
    String? avatarUrl,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
