// settings.dart — FLIGHTLY Settings Model
// Represents the user settings returned by /users/settings

class Settings {
  final String language;
  final String country;
  final String currency;

  Settings({
    required this.language,
    required this.country,
    required this.currency,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      language: json['language'] ?? 'en',
      country: json['country'] ?? 'Egypt',
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'country': country,
      'currency': currency,
    };
  }

  Settings copyWith({
    String? language,
    String? country,
    String? currency,
  }) {
    return Settings(
      language: language ?? this.language,
      country: country ?? this.country,
      currency: currency ?? this.currency,
    );
  }
}
