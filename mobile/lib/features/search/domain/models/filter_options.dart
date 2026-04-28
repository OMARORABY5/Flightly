// filter_options.dart - Filter and Sort Options Model
import 'package:flutter/foundation.dart';

enum SortOption {
  best('Best', 'best'),
  priceAsc('Cheapest', 'price_asc'),
  priceDesc('Most expensive', 'price_desc'),
  durationAsc('Fastest', 'duration_asc'),
  departureAsc('Earliest departure', 'departure_asc'),
  arrivalAsc('Earliest arrival', 'arrival_asc');

  final String label;
  final String value;
  const SortOption(this.label, this.value);
}

class FilterOptions {
  final double? maxPrice;
  final int? maxStops;
  final List<String> preferredAirlines;
  final int? minDuration;
  final int? maxDuration;
  final SortOption sortOption;

  const FilterOptions({
    this.maxPrice,
    this.maxStops,
    this.preferredAirlines = const [],
    this.minDuration,
    this.maxDuration,
    this.sortOption = SortOption.best,
  });

  FilterOptions copyWith({
    double? maxPrice,
    int? maxStops,
    List<String>? preferredAirlines,
    int? minDuration,
    int? maxDuration,
    SortOption? sortOption,
  }) {
    return FilterOptions(
      maxPrice: maxPrice != null ? (maxPrice == -1.0 ? null : maxPrice) : this.maxPrice,
      maxStops: maxStops != null ? (maxStops == -1 ? null : maxStops) : this.maxStops,
      preferredAirlines: preferredAirlines ?? this.preferredAirlines,
      minDuration: minDuration != null ? (minDuration == -1 ? null : minDuration) : this.minDuration,
      maxDuration: maxDuration != null ? (maxDuration == -1 ? null : maxDuration) : this.maxDuration,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'sort': sortOption.value,
    };
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (maxStops != null) params['maxStops'] = maxStops;
    if (preferredAirlines.isNotEmpty) params['airlines'] = preferredAirlines.join(',');
    if (minDuration != null) params['minDuration'] = minDuration;
    if (maxDuration != null) params['maxDuration'] = maxDuration;
    return params;
  }

  bool get hasActiveFilters =>
      maxPrice != null || maxStops != null || preferredAirlines.isNotEmpty || maxDuration != null;

  int get activeFilterCount {
    int count = 0;
    if (maxPrice != null) count++;
    if (maxStops != null) count++;
    if (preferredAirlines.isNotEmpty) count++;
    if (maxDuration != null) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterOptions &&
        other.maxPrice == maxPrice &&
        other.maxStops == maxStops &&
        listEquals(other.preferredAirlines, preferredAirlines) &&
        other.minDuration == minDuration &&
        other.maxDuration == maxDuration &&
        other.sortOption == sortOption;
  }

  @override
  int get hashCode {
    return maxPrice.hashCode ^
        maxStops.hashCode ^
        preferredAirlines.hashCode ^
        minDuration.hashCode ^
        maxDuration.hashCode ^
        sortOption.hashCode;
  }
}
