class RoomSummary {
  final int totalRooms;
  final double minPrice;
  final double maxPrice;
  final List<String> roomTypes;

  RoomSummary({
    required this.totalRooms,
    required this.minPrice,
    required this.maxPrice,
    required this.roomTypes,
  });

  // Changed toMap() to toJson()
  Map<String, dynamic> toJson() {
    return {
      'totalRooms': totalRooms,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'roomTypes': roomTypes,
    };
  }

  // Changed fromMap() to fromJson()
  factory RoomSummary.fromJson(Map<String, dynamic> map) {
    return RoomSummary(
      totalRooms: (map['totalRooms'] as num).toInt(),
      minPrice: (map['minPrice'] as num).toDouble(),
      maxPrice: (map['maxPrice'] as num).toDouble(),
      roomTypes: List<String>.from(map['roomTypes'] ?? []),
    );
  }
}
