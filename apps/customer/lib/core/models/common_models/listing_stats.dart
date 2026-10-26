import 'package:equatable/equatable.dart';

/// Statistics for listings
class ListingStats extends Equatable {
  final int availableItems;
  //   for events, this could represent the number of confirmed attendees or tickets sold
  final int confirmed;

  ///
  final int checkIns; //   for check-ins or confirmations
  final int saves;
  final int shares;
  //
  // final double? averageRating;
  // final int totalReviews;
  // final int followerCount;
  //  final int followingCount;
  ///
  final double revenue;
  final int totalSales;

  const ListingStats({
    required this.totalSales,
    required this.availableItems,
    required this.confirmed,
    this.checkIns = 0,
    this.saves = 0,
    this.shares = 0,
    this.revenue = 0.0,
  });

  @override
  List<Object?> get props => [
    totalSales,
    availableItems,
    confirmed,
    checkIns,
    saves,
    shares,
    revenue,
  ];
  static ListingStats empty() =>
      const ListingStats(totalSales: 0, availableItems: 0, confirmed: 0);
  Map<String, dynamic> toJson() {
    return {
      'totalSales': totalSales,
      'availableItems': availableItems,
      'confirmed': confirmed,
      'checkIns': checkIns,
      'saves': saves,
      'shares': shares,
      'revenue': revenue,
    };
  }

  factory ListingStats.fromJson(Map<String, dynamic> data) {
    return ListingStats(
      totalSales: data['totalSales'] ?? 0,
      availableItems: data['availableItems'] ?? 0,
      confirmed: data['confirmed'] ?? 0,
      checkIns: data['checkIns'] ?? 0,
      saves: data['saves'] ?? 0,
      shares: data['shares'] ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ListingStats copyWith({
    int? totalSales,
    int? availableItems,
    int? confirmed,
    int? checkIns,
    int? saves,
    int? shares,
    int? bookings,
    double? revenue,
  }) {
    return ListingStats(
      totalSales: totalSales ?? this.totalSales,
      availableItems: availableItems ?? this.availableItems,
      confirmed: confirmed ?? this.confirmed,
      checkIns: checkIns ?? this.checkIns,
      saves: saves ?? this.saves,
      shares: shares ?? this.shares,
      revenue: revenue ?? this.revenue,
    );
  }
}

class AccommodationStats extends ListingStats {
  final int bookingCount;
  final int shareCount;

  const AccommodationStats({
    required super.totalSales,
    required super.availableItems,
    required super.confirmed,
    super.checkIns = 0,
    super.saves = 0,
    super.shares = 0,
    super.revenue = 0.0,
    required this.bookingCount,
    required this.shareCount,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({'bookingCount': bookingCount, 'shareCount': shareCount});
    return map;
  }

  factory AccommodationStats.fromJson(Map<String, dynamic> map) {
    return AccommodationStats(
      totalSales: map['totalSales'] ?? 0,
      availableItems: map['availableItems'] ?? 0,
      confirmed: map['confirmed'] ?? 0,
      checkIns: map['checkIns'] ?? 0,
      saves: map['saves'] ?? 0,
      shares: map['shares'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      bookingCount: map['bookingCount'] ?? 0,
      shareCount: map['shareCount'] ?? 0,
    );
  }
}

class EventStats extends ListingStats {
  final int ticketsSold;
  final int attendees;

  const EventStats({
    required super.totalSales,
    required super.availableItems,
    required super.confirmed,
    super.checkIns = 0,
    super.saves = 0,
    super.shares = 0,
    super.revenue = 0.0,
    this.ticketsSold = 0,
    this.attendees = 0,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({'ticketsSold': ticketsSold, 'attendees': attendees});
    return map;
  }

  factory EventStats.fromJson(Map<String, dynamic> map) {
    return EventStats(
      totalSales: map['totalSales'] ?? 0,
      availableItems: map['availableItems'] ?? 0,
      confirmed: map['confirmed'] ?? 0,
      checkIns: map['checkIns'] ?? 0,
      saves: map['saves'] ?? 0,
      shares: map['shares'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      ticketsSold: map['ticketsSold'] ?? 0,
      attendees: map['attendees'] ?? 0,
    );
  }
}

class PlaceStats extends ListingStats {
  final int visitCount;

  const PlaceStats({
    required super.totalSales,
    required super.availableItems,
    required super.confirmed,
    super.checkIns = 0,
    super.saves = 0,
    super.shares = 0,
    super.revenue = 0.0,
    this.visitCount = 0,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({'visitCount': visitCount});
    return map;
  }

  factory PlaceStats.fromJson(Map<String, dynamic> map) {
    return PlaceStats(
      totalSales: map['totalSales'] ?? 0,
      availableItems: map['availableItems'] ?? 0,
      confirmed: map['confirmed'] ?? 0,
      checkIns: map['checkIns'] ?? 0,
      saves: map['saves'] ?? 0,
      shares: map['shares'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      visitCount: map['visitCount'] ?? 0,
    );
  }
}

class ServiceStats extends ListingStats {
  final int jobsCompleted;

  const ServiceStats({
    required super.totalSales,
    required super.availableItems,
    required super.confirmed,
    super.checkIns = 0,
    super.saves = 0,
    super.shares = 0,
    super.revenue = 0.0,
    this.jobsCompleted = 0,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({'jobsCompleted': jobsCompleted});
    return map;
  }

  factory ServiceStats.fromJson(Map<String, dynamic> map) {
    return ServiceStats(
      totalSales: map['totalSales'] ?? 0,
      availableItems: map['availableItems'] ?? 0,
      confirmed: map['confirmed'] ?? 0,
      checkIns: map['checkIns'] ?? 0,
      saves: map['saves'] ?? 0,
      shares: map['shares'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      jobsCompleted: map['jobsCompleted'] ?? 0,
    );
  }
}
