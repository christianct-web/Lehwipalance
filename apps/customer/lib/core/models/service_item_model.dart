import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

// Helper extension for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}

enum ServiceItemCategory {
  massage,
  facial,
  manicure,
  pedicure,
  hairTreatment,
  bodyTreatment,
  personalTraining,
  yoga,
  meditation,
  roomService,
  laundry,
  dryCleaning,
  shuttle,
  carRental,
  tour,
  equipmentRental,
  babysitting,
  petSitting,
  translation,
  photography,
  catering,
  eventPlanning,
  other,
}

class ServiceItemDTO implements Identifiable, Timestamped, Publishable {
  @override
  final String id;
  final String serviceListingId; // Reference to ServiceListingDTO
  final String name;
  final String description;
  final String? shortDescription;
  final List<String> imageUrls;
  final double price;
  final String? currency;
  final ServiceItemCategory category;
  final List<String> features;
  final Duration duration; // How long the service takes
  final bool isAvailable24_7;
  final TimeOfDay? availableFrom;
  final TimeOfDay? availableTo;
  final List<int> availableDays; // 1 = Monday, 7 = Sunday
  final int? maxCapacityPerSlot;
  final bool requiresBooking;
  final int? advanceBookingDays;
  final int? cancellationHours;
  final int? bufferMinutesBetweenBookings;
  final List<String> addOnIds; // Related add-ons/upgrades
  final Map<String, dynamic>? metadata;
  final int? maxBookingsPerDay;
  final int? currentBookingsCount; // For tracking daily bookings
  final DateTime? lastBookingDate; // Last date when booking count was reset

  @override
  final PublishStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  const ServiceItemDTO({
    required this.id,
    required this.serviceListingId,
    required this.name,
    required this.description,
    this.shortDescription,
    this.imageUrls = const [],
    required this.price,
    this.currency,
    this.category = ServiceItemCategory.other,
    this.features = const [],
    required this.duration,
    this.isAvailable24_7 = false,
    this.availableFrom,
    this.availableTo,
    this.availableDays = const [1, 2, 3, 4, 5, 6, 7], // All days by default
    this.maxCapacityPerSlot,
    this.requiresBooking = true,
    this.advanceBookingDays,
    this.cancellationHours,
    this.bufferMinutesBetweenBookings,
    this.addOnIds = const [],
    this.metadata,
    this.maxBookingsPerDay,
    this.currentBookingsCount = 0,
    this.lastBookingDate,
    this.status = PublishStatus.draft,
    required this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  @override
  bool get isActive => status == PublishStatus.published;

  bool get isAvailableNow {
    if (!isActive) return false;
    if (isAvailable24_7) return true;

    final now = DateTime.now();
    final currentDay = now.weekday;

    if (!availableDays.contains(currentDay)) return false;

    if (availableFrom != null && availableTo != null) {
      final currentTime = TimeOfDay.fromDateTime(now);
      return _isTimeInRange(currentTime, availableFrom!, availableTo!);
    }

    return true;
  }

  String get priceDisplay {
    final symbol = currency ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
  }

  String get durationDisplay {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}min';
      }
      return '${hours}h';
    }
    return '${duration.inMinutes}min';
  }

  String get categoryDisplay {
    switch (category) {
      case ServiceItemCategory.massage:
        return 'Massage';
      case ServiceItemCategory.facial:
        return 'Facial';
      case ServiceItemCategory.manicure:
        return 'Manicure';
      case ServiceItemCategory.pedicure:
        return 'Pedicure';
      case ServiceItemCategory.hairTreatment:
        return 'Hair Treatment';
      case ServiceItemCategory.bodyTreatment:
        return 'Body Treatment';
      case ServiceItemCategory.personalTraining:
        return 'Personal Training';
      case ServiceItemCategory.yoga:
        return 'Yoga';
      case ServiceItemCategory.meditation:
        return 'Meditation';
      case ServiceItemCategory.roomService:
        return 'Room Service';
      case ServiceItemCategory.laundry:
        return 'Laundry';
      case ServiceItemCategory.dryCleaning:
        return 'Dry Cleaning';
      case ServiceItemCategory.shuttle:
        return 'Shuttle Service';
      case ServiceItemCategory.carRental:
        return 'Car Rental';
      case ServiceItemCategory.tour:
        return 'Tour';
      case ServiceItemCategory.equipmentRental:
        return 'Equipment Rental';
      case ServiceItemCategory.babysitting:
        return 'Babysitting';
      case ServiceItemCategory.petSitting:
        return 'Pet Sitting';
      case ServiceItemCategory.translation:
        return 'Translation';
      case ServiceItemCategory.photography:
        return 'Photography';
      case ServiceItemCategory.catering:
        return 'Catering';
      case ServiceItemCategory.eventPlanning:
        return 'Event Planning';
      case ServiceItemCategory.other:
        return 'Other Services';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ServiceItemCategory.massage:
        return Icons.spa;
      case ServiceItemCategory.facial:
        return Icons.face;
      case ServiceItemCategory.manicure:
        return Icons.content_cut;
      case ServiceItemCategory.pedicure:
        return Icons.accessibility_new;
      case ServiceItemCategory.hairTreatment:
        return Icons.face_retouching_natural;
      case ServiceItemCategory.bodyTreatment:
        return Icons.fitness_center;
      case ServiceItemCategory.personalTraining:
        return Icons.fitness_center;
      case ServiceItemCategory.yoga:
        return Icons.self_improvement;
      case ServiceItemCategory.meditation:
        return Icons.self_improvement;
      case ServiceItemCategory.roomService:
        return Icons.room_service;
      case ServiceItemCategory.laundry:
        return Icons.local_laundry_service;
      case ServiceItemCategory.dryCleaning:
        return Icons.dry_cleaning;
      case ServiceItemCategory.shuttle:
        return Icons.directions_bus;
      case ServiceItemCategory.carRental:
        return Icons.directions_car;
      case ServiceItemCategory.tour:
        return Icons.tour;
      case ServiceItemCategory.equipmentRental:
        return Icons.build;
      case ServiceItemCategory.babysitting:
        return Icons.child_care;
      case ServiceItemCategory.petSitting:
        return Icons.pets;
      case ServiceItemCategory.translation:
        return Icons.translate;
      case ServiceItemCategory.photography:
        return Icons.camera_alt;
      case ServiceItemCategory.catering:
        return Icons.restaurant;
      case ServiceItemCategory.eventPlanning:
        return Icons.event;
      case ServiceItemCategory.other:
        return Icons.miscellaneous_services;
    }
  }

  // Availability methods
  bool isAvailableOnDate(DateTime date) {
    final dayOfWeek = date.weekday;
    if (!availableDays.contains(dayOfWeek)) return false;

    if (maxBookingsPerDay != null && currentBookingsCount != null) {
      // Reset daily count if it's a new day
      if (lastBookingDate == null ||
          lastBookingDate!.day != date.day ||
          lastBookingDate!.month != date.month ||
          lastBookingDate!.year != date.year) {
        return true; // New day, bookings reset
      }

      if (currentBookingsCount! >= maxBookingsPerDay!) {
        return false;
      }
    }

    return true;
  }

  bool isAvailableAtTime(DateTime dateTime) {
    if (!isAvailableOnDate(dateTime)) return false;
    if (isAvailable24_7) return true;

    if (availableFrom != null && availableTo != null) {
      final time = TimeOfDay.fromDateTime(dateTime);
      return _isTimeInRange(time, availableFrom!, availableTo!);
    }

    return true;
  }

  bool canBook(DateTime bookingDateTime) {
    if (!isAvailableAtTime(bookingDateTime)) return false;
    if (!requiresBooking) return true;

    if (advanceBookingDays != null) {
      final daysDifference = bookingDateTime.difference(DateTime.now()).inDays;
      if (daysDifference > advanceBookingDays!) return false;
      if (daysDifference < 0) return false;
    }

    return true;
  }

  bool canCancel(DateTime bookingDateTime, int hoursBeforeBooking) {
    if (cancellationHours == null) return true;
    return hoursBeforeBooking >= cancellationHours!;
  }

  bool hasCapacity(int requestedSlots) {
    if (maxCapacityPerSlot == null) return true;
    return requestedSlots <= maxCapacityPerSlot!;
  }

  Duration getTotalDurationWithBuffer(int numberOfBookings) {
    final totalDuration = duration * numberOfBookings;
    if (bufferMinutesBetweenBookings == null) return totalDuration;

    final bufferDuration = Duration(minutes: bufferMinutesBetweenBookings!);
    return totalDuration + (bufferDuration * (numberOfBookings - 1));
  }

  bool _isTimeInRange(TimeOfDay time, TimeOfDay from, TimeOfDay to) {
    final timeMinutes = time.hour * 60 + time.minute;
    final fromMinutes = from.hour * 60 + from.minute;
    final toMinutes = to.hour * 60 + to.minute;

    return timeMinutes >= fromMinutes && timeMinutes <= toMinutes;
  }

  // Booking tracking methods
  ServiceItemDTO incrementBookingCount(DateTime bookingDate) {
    final shouldReset =
        lastBookingDate == null ||
        lastBookingDate!.day != bookingDate.day ||
        lastBookingDate!.month != bookingDate.month ||
        lastBookingDate!.year != bookingDate.year;

    return copyWith(
      currentBookingsCount: shouldReset ? 1 : (currentBookingsCount ?? 0) + 1,
      lastBookingDate: bookingDate,
      updatedAt: DateTime.now(),
    );
  }

  ServiceItemDTO decrementBookingCount(DateTime bookingDate) {
    final shouldReset =
        lastBookingDate == null ||
        lastBookingDate!.day != bookingDate.day ||
        lastBookingDate!.month != bookingDate.month ||
        lastBookingDate!.year != bookingDate.year;

    if (shouldReset) return this;

    return copyWith(
      currentBookingsCount: ((currentBookingsCount ?? 0) - 1).clamp(
        0,
        maxBookingsPerDay ?? 999999,
      ),
      updatedAt: DateTime.now(),
    );
  }

  // Copy method
  ServiceItemDTO copyWith({
    String? id,
    String? serviceListingId,
    String? name,
    String? description,
    String? shortDescription,
    List<String>? imageUrls,
    double? price,
    String? currency,
    ServiceItemCategory? category,
    List<String>? features,
    Duration? duration,
    bool? isAvailable24_7,
    TimeOfDay? availableFrom,
    TimeOfDay? availableTo,
    List<int>? availableDays,
    int? maxCapacityPerSlot,
    bool? requiresBooking,
    int? advanceBookingDays,
    int? cancellationHours,
    int? bufferMinutesBetweenBookings,
    List<String>? addOnIds,
    Map<String, dynamic>? metadata,
    int? maxBookingsPerDay,
    int? currentBookingsCount,
    DateTime? lastBookingDate,
    PublishStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceItemDTO(
      id: id ?? this.id,
      serviceListingId: serviceListingId ?? this.serviceListingId,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      features: features ?? this.features,
      duration: duration ?? this.duration,
      isAvailable24_7: isAvailable24_7 ?? this.isAvailable24_7,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      availableDays: availableDays ?? this.availableDays,
      maxCapacityPerSlot: maxCapacityPerSlot ?? this.maxCapacityPerSlot,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
      cancellationHours: cancellationHours ?? this.cancellationHours,
      bufferMinutesBetweenBookings:
          bufferMinutesBetweenBookings ?? this.bufferMinutesBetweenBookings,
      addOnIds: addOnIds ?? this.addOnIds,
      metadata: metadata ?? this.metadata,
      maxBookingsPerDay: maxBookingsPerDay ?? this.maxBookingsPerDay,
      currentBookingsCount: currentBookingsCount ?? this.currentBookingsCount,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceListingId': serviceListingId,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'imageUrls': imageUrls,
      'price': price,
      'currency': currency,
      'category': category.name,
      'features': features,
      'durationMinutes': duration.inMinutes,
      'isAvailable24_7': isAvailable24_7,
      'availableFrom': availableFrom != null
          ? '${availableFrom!.hour.toString().padLeft(2, '0')}:${availableFrom!.minute.toString().padLeft(2, '0')}'
          : null,
      'availableTo': availableTo != null
          ? '${availableTo!.hour.toString().padLeft(2, '0')}:${availableTo!.minute.toString().padLeft(2, '0')}'
          : null,
      'availableDays': availableDays,
      'maxCapacityPerSlot': maxCapacityPerSlot,
      'requiresBooking': requiresBooking,
      'advanceBookingDays': advanceBookingDays,
      'cancellationHours': cancellationHours,
      'bufferMinutesBetweenBookings': bufferMinutesBetweenBookings,
      'addOnIds': addOnIds,
      'metadata': metadata,
      'maxBookingsPerDay': maxBookingsPerDay,
      'currentBookingsCount': currentBookingsCount,
      'lastBookingDate': lastBookingDate?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ServiceItemDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return ServiceItemDTO(
      id: json['id'] as String,
      serviceListingId: json['serviceListingId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      shortDescription: json['shortDescription'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String?,
      category: ServiceItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ServiceItemCategory.other,
      ),
      features: List<String>.from(json['features'] ?? []),
      duration: Duration(minutes: json['durationMinutes'] as int),
      isAvailable24_7: json['isAvailable24_7'] as bool? ?? false,
      availableFrom: parseTimeOfDay(json['availableFrom'] as String?),
      availableTo: parseTimeOfDay(json['availableTo'] as String?),
      availableDays: List<int>.from(
        json['availableDays'] ?? [1, 2, 3, 4, 5, 6, 7],
      ),
      maxCapacityPerSlot: json['maxCapacityPerSlot'] as int?,
      requiresBooking: json['requiresBooking'] as bool? ?? true,
      advanceBookingDays: json['advanceBookingDays'] as int?,
      cancellationHours: json['cancellationHours'] as int?,
      bufferMinutesBetweenBookings:
          json['bufferMinutesBetweenBookings'] as int?,
      addOnIds: List<String>.from(json['addOnIds'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      maxBookingsPerDay: json['maxBookingsPerDay'] as int?,
      currentBookingsCount: json['currentBookingsCount'] as int? ?? 0,
      lastBookingDate: parseDateTime(json['lastBookingDate']),
      status: PublishStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PublishStatus.draft,
      ),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'ServiceItemDTO(id: $id, name: $name, price: $priceDisplay, serviceListingId: $serviceListingId)';
  }
}

final List<ServiceItemDTO> mockServiceItems = [
  // srv_001 - Luxury Spa Package serviceTypeIds: ['spa_massage', 'spa_facial', 'spa_body_wrap', 'spa_aroma']
  ServiceItemDTO(
    id: 'spa_massage', // Matches srv_001 serviceTypeIds[0]
    serviceListingId: 'srv_001',
    name: 'Deep Tissue Massage',
    description: '60-minute deep tissue massage to relieve muscle tension',
    shortDescription: 'Relax and rejuvenate',
    imageUrls: ['https://example.com/massage.jpg'],
    price: 120.0,
    currency: 'USD',
    category: ServiceItemCategory.massage,
    features: ['Essential Oils', 'Hot Towels', 'Soothing Music'],
    duration: Duration(minutes: 60),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 9, minute: 0),
    availableTo: TimeOfDay(hour: 21, minute: 0),
    availableDays: [1, 2, 3, 4, 5, 6],
    maxCapacityPerSlot: 5,
    requiresBooking: true,
    advanceBookingDays: 1,
    cancellationHours: 24,
    bufferMinutesBetweenBookings: 15,
    currentBookingsCount: 12,
    maxBookingsPerDay: 20,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 8, 1),
  ),
  ServiceItemDTO(
    id: 'spa_facial', // Matches srv_001 serviceTypeIds[1]
    serviceListingId: 'srv_001',
    name: 'Organic Facial Treatment',
    description: '90-minute organic facial with natural ingredients',
    shortDescription: 'Glowing skin naturally',
    imageUrls: ['https://example.com/facial.jpg'],
    price: 150.0,
    currency: 'USD',
    category: ServiceItemCategory.facial,
    features: ['Organic Products', 'Face Massage', 'Steam Treatment'],
    duration: Duration(minutes: 90),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 10, minute: 0),
    availableTo: TimeOfDay(hour: 20, minute: 0),
    availableDays: [2, 3, 4, 5, 6],
    maxCapacityPerSlot: 3,
    requiresBooking: true,
    advanceBookingDays: 2,
    cancellationHours: 48,
    currentBookingsCount: 8,
    maxBookingsPerDay: 10,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 8, 1),
  ),
  ServiceItemDTO(
    id: 'spa_body_wrap', // Matches srv_001 serviceTypeIds[2]
    serviceListingId: 'srv_001',
    name: 'Detox Body Wrap',
    description: '75-minute body wrap for detoxification and skin rejuvenation',
    shortDescription: 'Cleanse and refresh',
    imageUrls: ['https://example.com/body-wrap.jpg'],
    price: 180.0,
    currency: 'USD',
    category: ServiceItemCategory.bodyTreatment,
    features: ['Seaweed Wrap', 'Detoxifying', 'Hydrating'],
    duration: Duration(minutes: 75),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 11, minute: 0),
    availableTo: TimeOfDay(hour: 19, minute: 0),
    availableDays: [1, 3, 5],
    maxCapacityPerSlot: 4,
    requiresBooking: true,
    advanceBookingDays: 3,
    cancellationHours: 24,
    currentBookingsCount: 5,
    maxBookingsPerDay: 8,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 8, 1),
  ),
  ServiceItemDTO(
    id: 'spa_aroma', // Matches srv_001 serviceTypeIds[3]
    serviceListingId: 'srv_001',
    name: 'Aromatherapy Session',
    description: '45-minute aromatherapy with essential oils',
    shortDescription: 'Balance your senses',
    imageUrls: ['https://example.com/aroma.jpg'],
    price: 90.0,
    currency: 'USD',
    category: ServiceItemCategory.massage,
    features: ['Essential Oils', 'Relaxation Music', 'Aromatherapy'],
    duration: Duration(minutes: 45),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 9, minute: 0),
    availableTo: TimeOfDay(hour: 21, minute: 0),
    availableDays: [1, 2, 3, 4, 5, 6],
    maxCapacityPerSlot: 6,
    requiresBooking: true,
    advanceBookingDays: 1,
    cancellationHours: 12,
    currentBookingsCount: 15,
    maxBookingsPerDay: 25,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 8, 1),
  ),
  // srv_002 - Steelpan Music Lessons serviceTypeIds: ['steelpan', 'soca', 'calypso', 'ensemble']
  ServiceItemDTO(
    id: 'steelpan',
    serviceListingId: 'srv_002',
    name: 'Steelpan Basics',
    description: 'Learn the fundamentals of playing steelpan',
    shortDescription: 'Start your pan journey',
    imageUrls: ['https://example.com/steelpan.jpg'],
    price: 45.0,
    currency: 'USD',
    category: ServiceItemCategory.other,
    features: ['Instrument Provided', 'Group Lesson', 'Music Theory'],
    duration: Duration(minutes: 60),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 10, minute: 0),
    availableTo: TimeOfDay(hour: 20, minute: 0),
    availableDays: [1, 2, 3, 4, 5],
    requiresBooking: true,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 7, 15),
  ),
  ServiceItemDTO(
    id: 'soca',
    serviceListingId: 'srv_002',
    name: 'Soca Music Workshop',
    description: 'Learn to play and compose soca music',
    shortDescription: 'Create the sound of Carnival',
    imageUrls: ['https://example.com/soca.jpg'],
    price: 55.0,
    currency: 'USD',
    category: ServiceItemCategory.other,
    features: ['Recording Studio', 'Professional Guidance'],
    duration: Duration(minutes: 90),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 11, minute: 0),
    availableTo: TimeOfDay(hour: 19, minute: 0),
    availableDays: [2, 4, 6],
    requiresBooking: true,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 7, 20),
  ),
  ServiceItemDTO(
    id: 'calypso',
    serviceListingId: 'srv_002',
    name: 'Calypso Vocal Training',
    description: 'Develop your calypso singing style',
    shortDescription: 'Find your voice',
    imageUrls: ['https://example.com/calypso.jpg'],
    price: 40.0,
    currency: 'USD',
    category: ServiceItemCategory.other,
    features: ['Vocal Coaching', 'Lyric Writing'],
    duration: Duration(minutes: 45),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 9, minute: 0),
    availableTo: TimeOfDay(hour: 18, minute: 0),
    availableDays: [1, 3, 5],
    requiresBooking: true,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 7, 18),
  ),
  ServiceItemDTO(
    id: 'ensemble',
    serviceListingId: 'srv_002',
    name: 'Steelpan Ensemble',
    description: 'Play in a steelpan band ensemble',
    shortDescription: 'Join the band',
    imageUrls: ['https://example.com/ensemble.jpg'],
    price: 65.0,
    currency: 'USD',
    category: ServiceItemCategory.other,
    features: ['Full Ensemble', 'Performance Training'],
    duration: Duration(minutes: 120),
    isAvailable24_7: false,
    availableFrom: TimeOfDay(hour: 14, minute: 0),
    availableTo: TimeOfDay(hour: 21, minute: 0),
    availableDays: [1, 3, 5],
    requiresBooking: true,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 7, 22),
  ),
  // Additional services for other listings...
  ServiceItemDTO(
    id: 'event',
    serviceListingId: 'srv_003',
    name: 'Event Photography',
    description: 'Professional event photography coverage',
    shortDescription: 'Capture your moments',
    imageUrls: ['https://example.com/event-photo.jpg'],
    price: 200.0,
    currency: 'USD',
    category: ServiceItemCategory.photography,
    duration: Duration(hours: 2),
    requiresBooking: true,
    status: PublishStatus.published,
    createdAt: DateTime(2024, 5, 10),
  ),
];
