// profile.dart — FLIGHTLY Profile Model
// Represents the user profile data returned by /users/profile

class Profile {
  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? nationality;
  final String? photoUrl;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.email,
    this.displayName,
    this.phone,
    this.nationality,
    this.photoUrl,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      phone: json['phone'],
      nationality: json['nationality'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'phone': phone,
      'nationality': nationality,
      // photo_url is updated via a separate endpoint
    };
  }
}
