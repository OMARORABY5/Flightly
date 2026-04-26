class Airport {
  final String iataCode;
  final String? icaoCode;
  final String name;
  final String city;
  final String country;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final String? timezone;

  Airport({
    required this.iataCode,
    this.icaoCode,
    required this.name,
    required this.city,
    required this.country,
    required this.countryCode,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      iataCode: json['iata_code'] as String,
      icaoCode: json['icao_code'] as String?,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      countryCode: json['country_code'] as String,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iata_code': iataCode,
      'icao_code': icaoCode,
      'name': name,
      'city': city,
      'country': country,
      'country_code': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Airport && runtimeType == other.runtimeType && iataCode == other.iataCode;

  @override
  int get hashCode => iataCode.hashCode;
}
