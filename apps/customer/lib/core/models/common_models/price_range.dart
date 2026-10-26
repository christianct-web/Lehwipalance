class PriceRange {
  final double min;
  final double max;
  final String currency;

  PriceRange({required this.min, required this.max, required this.currency});

  factory PriceRange.none() {
    return PriceRange(min: 0, max: 0, currency: 'USD');
  }
}
