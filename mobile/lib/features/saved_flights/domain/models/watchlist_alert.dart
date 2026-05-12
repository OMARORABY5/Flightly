// watchlist_alert.dart — FLIGHTLY Smart Watchlist Price Tracking
// Data model representing a single price monitoring alert.
// Pure Dart — no Flutter dependencies.

/// The category of watchlist alert produced by the PriceDropEvaluator.
enum WatchlistAlertType {
  /// Current price is meaningfully lower than the saved (watched) price.
  priceDrop,

  /// A nearby date (±2 days auto / ±5 days manual) is significantly cheaper.
  flexibleDate,

  /// Current price is the lowest in the nearby date spread — good time to book.
  goodPriceWindow,
}

/// A single price monitoring alert for a watched flight route.
class WatchlistAlert {
  /// The saveId from [SavedFlight] — used for deduplication and display.
  final String saveId;

  /// The flight id this alert is about.
  final String flightId;

  /// Route IATA codes for display and notification copy.
  final String originIata;
  final String destinationIata;

  /// Human-readable city names (may be null if not enriched).
  final String? originCity;
  final String? destinationCity;

  /// The category of this alert.
  final WatchlistAlertType type;

  /// Price that was saved when the user added the flight to the watchlist.
  final double savedPrice;

  /// The current price of the flight as of this evaluation.
  final double currentPrice;

  /// How much cheaper vs savedPrice (positive = savings). Null for non-priceDrop.
  final double? priceDrop;

  /// Drop as a percentage of the saved price. Null for non-priceDrop.
  final double? dropPercent;

  /// The cheaper price found on a nearby date. Only set for [flexibleDate].
  final double? suggestedPrice;

  /// The nearby date that is cheaper. Only set for [flexibleDate].
  final DateTime? suggestedDate;

  /// How many days offset from the watched date the suggestion is.
  /// Negative = earlier, positive = later. Only set for [flexibleDate].
  final int? suggestedDayOffset;

  /// Savings vs current price on the suggested date. Only set for [flexibleDate].
  final double? flexibleSaving;

  /// Notification title — ready to use directly in the push payload.
  final String notificationTitle;

  /// Notification body — ready to use directly in the push payload.
  final String notificationBody;

  /// When this alert was created (used for freshness checks).
  final DateTime createdAt;

  const WatchlistAlert({
    required this.saveId,
    required this.flightId,
    required this.originIata,
    required this.destinationIata,
    this.originCity,
    this.destinationCity,
    required this.type,
    required this.savedPrice,
    required this.currentPrice,
    this.priceDrop,
    this.dropPercent,
    this.suggestedPrice,
    this.suggestedDate,
    this.suggestedDayOffset,
    this.flexibleSaving,
    required this.notificationTitle,
    required this.notificationBody,
    required this.createdAt,
  });

  /// Display-friendly route string, e.g. "Cairo → Dubai".
  String get routeLabel {
    final from = originCity ?? originIata;
    final to = destinationCity ?? destinationIata;
    return '$from → $to';
  }

  /// Whether this alert has an actionable saving amount to show.
  bool get hasSaving =>
      (priceDrop != null && priceDrop! > 0) ||
      (flexibleSaving != null && flexibleSaving! > 0);
}
