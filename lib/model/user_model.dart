class User {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final int role;
  final String? image; // URL of the user's image
  final String description; // Description of the user

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.image = '', // Default value
    this.description = '', // Default value
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['User_id'] is int ? json['User_id'] : int.tryParse(json['User_id']?.toString() ?? '') ?? 0,
      email: json['email'] ?? '',
      firstName: json['f_name'] ?? '',
      lastName: json['l_name'] ?? '',
      role: json['role'] is int ? json['role'] : int.tryParse(json['role']?.toString() ?? '') ?? 99,
     image: json['image'] as String?, // Fetch image URL from JSON
      description: json['description'] ?? '', // Fetch description from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'User_id': userId,
      'email': email,
      'f_name': firstName,
      'l_name': lastName,
      'role': role,
      'image': image, // Include image URL in JSON representation
      'description': description, // Include description in JSON representation
    };
  }
}
