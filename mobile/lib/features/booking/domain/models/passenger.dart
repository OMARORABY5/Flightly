// passenger.dart - Passenger Domain Model
class Passenger {
  final String id;
  final String userId;
  final String fullName;
  final String gender;
  final DateTime dateOfBirth;
  final String nationality;
  final String passportNumber;
  final DateTime? passportExpiry;
  final bool isPrimary;
  
  // Selected state for UI (not persisted)
  final bool isSelected;

  Passenger({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.nationality,
    required this.passportNumber,
    this.passportExpiry,
    this.isPrimary = false,
    this.isSelected = false,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      userId: json['user_id'] ?? '',
      fullName: json['full_name'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      nationality: json['nationality'],
      passportNumber: json['passport_number'],
      passportExpiry: json['passport_expiry'] != null 
          ? DateTime.parse(json['passport_expiry']) 
          : null,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'full_name': fullName,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'nationality': nationality,
      'passport_number': passportNumber,
      'passport_expiry': passportExpiry?.toIso8601String().split('T')[0],
      'is_primary': isPrimary,
    };
  }

  Passenger copyWith({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? nationality,
    String? passportNumber,
    DateTime? passportExpiry,
    bool? isPrimary,
    bool? isSelected,
  }) {
    return Passenger(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      isPrimary: isPrimary ?? this.isPrimary,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
