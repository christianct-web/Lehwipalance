// Model Classes

import 'package:flutter/material.dart';

import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

class RoomDTO implements Identifiable, Timestamped, Publishable {
  @override
  final String id;
  final bool isPublished;
  @override
  final PublishStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  bool get isActive => status == PublishStatus.published;
  final String hotelId;
  final String name;
  final String description;
  final String imageUrl;
  final double basePrice;
  final int maxGuests;
  final double rating;
  final List<String> features;
  final String size;
  final String bedType;

  /// Booked date ranges (UTC, inclusive)
  final List<DateTimeRange> bookedRanges;

  const RoomDTO({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.maxGuests,
    this.rating = 4.5,
    this.features = const [],
    required this.size,
    required this.bedType,
    this.bookedRanges = const [],
    required this.createdAt,
    this.updatedAt,
    this.isPublished = false,
    this.status = PublishStatus.draft,
  });

  // ---------------- AVAILABILITY ----------------

  bool isAvailableFor(DateTimeRange range) {
    return !bookedRanges.any(
      (b) => range.start.isBefore(b.end) && range.end.isAfter(b.start),
    );
  }

  // ---------------- COPY ----------------

  RoomDTO copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? description,
    String? imageUrl,
    double? basePrice,
    int? maxGuests,
    double? rating,
    List<String>? features,
    String? size,
    String? bedType,
    List<DateTimeRange>? bookedRanges,
    bool? isPublished,
    PublishStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomDTO(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      maxGuests: maxGuests ?? this.maxGuests,
      rating: rating ?? this.rating,
      features: features ?? this.features,
      size: size ?? this.size,
      bedType: bedType ?? this.bedType,
      bookedRanges: bookedRanges ?? this.bookedRanges,
      isPublished: isPublished ?? this.isPublished,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------- JSON ----------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotelId': hotelId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'maxGuests': maxGuests,
      'rating': rating,
      'features': features,
      'size': size,
      'bedType': bedType,
      'bookedRanges': bookedRanges
          .map(
            (r) => {
              'start': r.start.toIso8601String(),
              'end': r.end.toIso8601String(),
            },
          )
          .toList(),
      'isPublished': isPublished,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory RoomDTO.fromJson(Map<String, dynamic> data) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    // Parse booked ranges
    List<DateTimeRange> parseBookedRanges(List<dynamic>? ranges) {
      if (ranges == null) return [];
      return ranges.map((e) {
        final map = e as Map<String, dynamic>;
        return DateTimeRange(
          start: parseDateTime(map['start']) ?? DateTime.now(),
          end: parseDateTime(map['end']) ?? DateTime.now(),
        );
      }).toList();
    }

    return RoomDTO(
      id: data['id']?.toString() ?? '',
      hotelId: data['hotelId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      maxGuests: (data['maxGuests'] as num?)?.toInt() ?? 1,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      features: List<String>.from(data['features'] ?? []),
      size: data['size']?.toString() ?? '',
      bedType: data['bedType']?.toString() ?? '',
      bookedRanges: parseBookedRanges(data['bookedRanges'] as List<dynamic>?),
      isPublished: data['isPublished'] as bool? ?? false,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == data['status']?.toString(),
        orElse: () => PublishStatus.draft,
      ),
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Null get currency => null;
}

final List<RoomDTO> mockRooms = [
  // Hyatt Regency Trinidad (htl_001) - roomIds should be ['room_001', 'room_002']
  RoomDTO(
    id: 'room_001', // Matches htl_001 roomIds[0]
    hotelId: 'htl_001',
    name: 'Deluxe Suite',
    description:
        'Spacious suite with city view, king-size bed, and private balcony.',
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
    basePrice: 220.0,
    maxGuests: 3,
    rating: 4.8,
    features: ['Balcony', 'Air Conditioning', 'Smart TV', 'Wi-Fi'],
    size: '45 sqm',
    bedType: 'King',
    bookedRanges: [
      DateTimeRange(start: DateTime(2026, 2, 10), end: DateTime(2026, 2, 15)),
    ],
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  RoomDTO(
    id: 'room_002', // Matches htl_001 roomIds[1]
    hotelId: 'htl_001',
    name: 'Standard Room',
    description: 'Cozy standard room with queen-size bed and modern bathroom.',
    imageUrl: 'https://images.unsplash.com/photo-1560067174-8947b595b6d6',
    basePrice: 120.0,
    maxGuests: 2,
    rating: 4.4,
    features: ['Wi-Fi', 'Air Conditioning', 'Flat Screen TV'],
    size: '25 sqm',
    bedType: 'Queen',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  // Hilton Trinidad (htl_002) - roomIds should be ['room_003', 'room_004']
  RoomDTO(
    id: 'room_003', // Matches htl_002 roomIds[0]
    hotelId: 'htl_002',
    name: 'Ocean View Suite',
    description: 'Luxury suite with panoramic sea views and balcony.',
    imageUrl: 'https://images.unsplash.com/photo-1590490359683-658d3d20b360',
    basePrice: 300.0,
    maxGuests: 4,
    rating: 4.7,
    features: ['Ocean View', 'Private Balcony', 'Minibar', 'Wi-Fi'],
    size: '50 sqm',
    bedType: 'King',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  RoomDTO(
    id: 'room_004', // Matches htl_002 roomIds[1]
    hotelId: 'htl_002',
    name: 'Garden Room',
    description: 'Peaceful garden-facing room with double bed.',
    imageUrl: 'https://images.unsplash.com/photo-1598928506310-1d55d26a8d6b',
    basePrice: 150.0,
    maxGuests: 2,
    rating: 4.3,
    features: ['Garden View', 'Private Terrace', 'Wi-Fi'],
    size: '30 sqm',
    bedType: 'Double',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  // Magdalena Grand Beach & Golf Resort (htl_003) - roomIds should be ['room_005', 'room_006']
  RoomDTO(
    id: 'room_005', // Matches htl_003 roomIds[0]
    hotelId: 'htl_003',
    name: 'Executive Room',
    description: 'Modern business-class room with workspace and fast Wi-Fi.',
    imageUrl: 'https://images.unsplash.com/photo-1600047509358-9dc75507c759',
    basePrice: 180.0,
    maxGuests: 2,
    rating: 4.5,
    features: ['Workspace', 'Fast Wi-Fi', 'Coffee Machine'],
    size: '28 sqm',
    bedType: 'Queen',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  RoomDTO(
    id: 'room_006', // Matches htl_003 roomIds[1]
    hotelId: 'htl_003',
    name: 'Penthouse Suite',
    description: 'Luxurious penthouse with rooftop terrace and skyline view.',
    imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b',
    basePrice: 500.0,
    maxGuests: 5,
    rating: 4.9,
    features: ['Rooftop Terrace', 'Skyline View', 'Private Bar', 'Jacuzzi'],
    size: '70 sqm',
    bedType: 'King',
    bookedRanges: [
      DateTimeRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 10)),
    ],
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  // Courtyard by Marriott (htl_004) - roomIds should be ['room_007', 'room_008']
  RoomDTO(
    id: 'room_007', // Matches htl_004 roomIds[0]
    hotelId: 'htl_004',
    name: 'Mountain View Suite',
    description: 'Spacious suite with breathtaking views of the mountains.',
    imageUrl: 'https://images.unsplash.com/photo-1628744876497-f4a14a2fdbef',
    basePrice: 350.0,
    maxGuests: 4,
    rating: 4.8,
    features: ['Mountain View', 'Fireplace', 'Private Balcony'],
    size: '55 sqm',
    bedType: 'King',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  RoomDTO(
    id: 'room_008', // Matches htl_004 roomIds[1]
    hotelId: 'htl_004',
    name: 'Cozy Cabin Room',
    description: 'Rustic cabin-style room perfect for couples.',
    imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9',
    basePrice: 200.0,
    maxGuests: 2,
    rating: 4.6,
    features: ['Rustic Decor', 'Wooden Interior', 'Cozy Fireplace'],
    size: '35 sqm',
    bedType: 'Queen',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  // Store Bay Beach Resort (htl_005) - roomIds should be ['room_009', 'room_010']
  RoomDTO(
    id: 'room_009', // Matches htl_005 roomIds[0]
    hotelId: 'htl_005',
    name: 'Family Suite',
    description: 'Spacious suite with separate kids room and play area.',
    imageUrl: 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6',
    basePrice: 280.0,
    maxGuests: 5,
    rating: 4.7,
    features: ['Kids Room', 'Play Area', 'Kitchenette', 'Wi-Fi'],
    size: '60 sqm',
    bedType: 'King + Bunk Beds',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
  RoomDTO(
    id: 'room_010', // Matches htl_005 roomIds[1]
    hotelId: 'htl_005',
    name: 'Connecting Rooms',
    description: 'Two connecting rooms perfect for larger families.',
    imageUrl: 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
    basePrice: 350.0,
    maxGuests: 6,
    rating: 4.8,
    features: ['Connecting Rooms', 'Two Bathrooms', 'Living Area'],
    size: '70 sqm',
    bedType: 'Queen + Twin Beds',
    createdAt: DateTime.now(),
    status: PublishStatus.published,
  ),
];
