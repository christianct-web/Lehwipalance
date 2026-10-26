import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

// =============================================
// UPDATED LISTINGHOSTREF WITH listingId
// =============================================
class LocationModel implements Identifiable {
  @override
  final String id;
  final LatLng coordinates;
  final String? geoHashCode;
  final String name;
  final String imageUrl;
  final AddressModel address;
  final String? additionalInfo;
  final String? mainVenueId; // Points to MerchantListingDTO.id
  final ListingType listingType;

  // New fields for location ownership/hierarchy
  final ListingHostRef? hostRef;
  final List<ListingHostRef>? childListings;

  // Add addresses list for multiple addresses per location
  final List<AddressModel>? savedAddresses;

  LocationModel({
    required this.id,
    required this.name,
    this.geoHashCode,
    required this.coordinates,
    required this.imageUrl,
    required this.address,
    this.additionalInfo,
    this.mainVenueId,
    this.hostRef,
    this.childListings,
    this.savedAddresses,
    required this.listingType,
  });

  /// Convert LocationModel to a Map for general use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'address': address.toJson(),
      'geoHashCode': geoHashCode,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'additionalInfo': additionalInfo,
      'mainVenueId': mainVenueId,
      'hostRef': hostRef?.toMap(),
      'childListings': childListings?.map((ref) => ref.toMap()).toList(),
      'savedAddresses': savedAddresses?.map((addr) => addr.toJson()).toList(),
      'listingType': listingType,
    };
  }

  /// Create LocationModel from a Map (general use)
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      address: AddressModel.fromJson(map['address'] ?? {}),
      geoHashCode: map['geoHashCode'],
      coordinates: map['coordinates'] is LatLng
          ? map['coordinates'] as LatLng
          : LatLng(
              (map['coordinates']?['latitude'] ?? 0.0).toDouble(),
              (map['coordinates']?['longitude'] ?? 0.0).toDouble(),
            ),
      additionalInfo: map['additionalInfo'],
      mainVenueId: map['mainVenueId'],
      hostRef: map['hostRef'] != null
          ? ListingHostRef.fromMap(map['hostRef'])
          : null,
      childListings: map['childListings'] != null
          ? (map['childListings'] as List)
                .map((ref) => ListingHostRef.fromMap(ref))
                .toList()
          : null,
      savedAddresses: map['savedAddresses'] != null
          ? (map['savedAddresses'] as List)
                .map((addr) => AddressModel.fromJson(addr))
                .toList()
          : null,
      listingType: map['listingType'],
    );
  }

  /// Convert LocationModel to Firestore document format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'address': address.toJson(),
      'geoHashCode': geoHashCode,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'additionalInfo': additionalInfo,
      'mainVenueId': mainVenueId,
      'hostRef': hostRef?.toMap(),
      'childListings': childListings?.map((ref) => ref.toMap()).toList(),
      'savedAddresses': savedAddresses?.map((addr) => addr.toJson()).toList(),
    };
  }

  /// Create LocationModel from Firestore document
  factory LocationModel.fromJson(Map<String, dynamic> map) {
    // Handle LatLng from Firestore
    LatLng coordinates;
    if (map['coordinates'] is LatLng) {
      coordinates = map['coordinates'] as LatLng;
    } else if (map['coordinates'] is Map) {
      final coordMap = map['coordinates'] as Map;
      coordinates = LatLng(
        (coordMap['latitude'] ?? 0.0).toDouble(),
        (coordMap['longitude'] ?? 0.0).toDouble(),
      );
    } else {
      coordinates = const LatLng(0.0, 0.0);
    }

    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      address: AddressModel.fromJson(map['address'] ?? {}),
      geoHashCode: map['geoHashCode'],
      coordinates: coordinates,
      additionalInfo: map['additionalInfo'],
      mainVenueId: map['mainVenueId'],
      hostRef: map['hostRef'] != null
          ? ListingHostRef.fromMap(map['hostRef'])
          : null,
      childListings: map['childListings'] != null
          ? (map['childListings'] as List)
                .map((ref) => ListingHostRef.fromMap(ref))
                .toList()
          : null,
      savedAddresses: map['savedAddresses'] != null
          ? (map['savedAddresses'] as List)
                .map((addr) => AddressModel.fromJson(addr))
                .toList()
          : null,
      listingType: map['listingType'],
    );
  }

  // Convenience getters
  String get fullAddress => address.fullAddress;
  String get street => address.street;
  String get city => address.city;
  String get state => address.state;
  String get country => address.country;
  String get postalCode => address.postalCode;
  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;

  LocationModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    AddressModel? address,
    String? geoHashCode,
    LatLng? coordinates,
    String? additionalInfo,
    String? mainVenueId,
    ListingHostRef? hostRef,
    List<ListingHostRef>? childListings,
    List<AddressModel>? savedAddresses,
    ListingType? listingType,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      geoHashCode: geoHashCode ?? this.geoHashCode,
      coordinates: coordinates ?? this.coordinates,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      mainVenueId: mainVenueId ?? this.mainVenueId,
      hostRef: hostRef ?? this.hostRef,
      childListings: childListings ?? this.childListings,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      listingType: listingType ?? this.listingType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationModel) return false;

    return other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl &&
        other.address == address &&
        other.geoHashCode == geoHashCode &&
        other.coordinates.latitude == coordinates.latitude &&
        other.coordinates.longitude == coordinates.longitude &&
        other.additionalInfo == additionalInfo &&
        other.mainVenueId == mainVenueId &&
        other.hostRef == hostRef &&
        _listEquals(other.childListings, childListings) &&
        _listEquals(other.savedAddresses, savedAddresses);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      imageUrl,
      address,
      geoHashCode,
      coordinates.latitude,
      coordinates.longitude,
      additionalInfo,
      mainVenueId,
      hostRef,
      childListings,
      savedAddresses,
    );
  }

  @override
  String toString() {
    return 'LocationModel(id: $id, name: $name, address: ${address.fullAddress})';
  }

  // Helper method for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ListingHostRef {
  final String id;
  final String imageUrl;
  final String listingId; // Changed from venueId
  final String name;
  final ListingType type;

  const ListingHostRef({
    required this.id,
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.listingId, // Changed from venueId
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'name': name,
    'imageUrl': imageUrl,
    'listingId': listingId,
  };

  factory ListingHostRef.fromMap(Map<String, dynamic> map) {
    return ListingHostRef(
      id: map['id'] ?? '',
      type: ListingType.values.firstWhere((e) => e.name == map['type']),
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      listingId: map['listingId'] ?? '',
    );
  }
}

// =============================================
// UPDATED MOCK LOCATIONS WITH LISTINGHOSTREF
// =============================================

final List<LocationModel> mockLocations = [
  // =============================================
  // MAIN VENUES (These have mainVenueId set)
  // =============================================

  // 1. Queen's Park Savannah - Main venue for Carnival events
  LocationModel(
    id: 'loc1',
    name: "Queen's Park Savannah",
    coordinates: const LatLng(10.6711, -61.5235),
    geoHashCode: 'd8k8q',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/6/6d/Queens_Park_Savannah_Trinidad.jpg',
    address: AddressModel(
      street: "Queen's Park West",
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120102',
    ),
    additionalInfo: 'Largest open space in Port of Spain',
    mainVenueId: 'plc_001',
    hostRef: ListingHostRef(
      id: 'plc_001',
      listingId: 'loc1',
      type: ListingType.place,
      name: "Queen's Park Savannah Experience",
      imageUrl: 'https://picsum.photos/400/300?random=301',
    ),
    childListings: [
      ListingHostRef(
        id: 'evt_002',
        listingId: 'loc1',
        type: ListingType.event,
        name: 'Trinidad Carnival Kickoff 2025',
        imageUrl: 'https://picsum.photos/400/300?random=105',
      ),
    ],
    listingType: ListingType.place,
  ),

  // 2. Maracas Beach
  LocationModel(
    id: 'loc2',
    listingType: ListingType.place,
    name: 'Maracas Beach',
    coordinates: const LatLng(10.7609, -61.4472),
    geoHashCode: 'd8k7x',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/9/9e/Maracas_Beach_Trinidad.jpg',
    address: AddressModel(
      street: 'North Coast Road',
      city: 'Maracas',
      state: 'San Juan-Laventille',
      country: 'Trinidad and Tobago',
      postalCode: '300101',
    ),
    additionalInfo: 'Famous for bake and shark',
    mainVenueId: 'plc_002',
    hostRef: ListingHostRef(
      id: 'plc_002',
      listingId: 'loc2',
      type: ListingType.place,
      name: 'Maracas Beach Day Trip',
      imageUrl: 'https://picsum.photos/400/300?random=305',
    ),
  ),

  // 3. Pigeon Point Heritage Park
  LocationModel(
    id: 'loc3',
    listingType: ListingType.place,
    name: 'Pigeon Point Heritage Park',
    coordinates: const LatLng(11.1496, -60.8393),
    geoHashCode: 'd8f7n',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/5/5a/Pigeon_Point_Tobago.jpg',
    address: AddressModel(
      street: 'Pigeon Point Road',
      city: 'Crown Point',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910102',
    ),
    additionalInfo: 'Iconic Tobago beach with jetty',
    mainVenueId: 'plc_004',
    hostRef: ListingHostRef(
      id: 'plc_004',
      listingId: 'loc3',
      type: ListingType.place,
      name: 'Pigeon Point Heritage Park',
      imageUrl: 'https://picsum.photos/400/300?random=311',
    ),
  ),

  // 4. Asa Wright Nature Centre
  LocationModel(
    id: 'loc4',
    listingType: ListingType.place,
    name: 'Asa Wright Nature Centre',
    coordinates: const LatLng(10.7171, -61.2933),
    geoHashCode: 'd8k8m',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/4/4b/Asa_Wright_Nature_Centre.jpg',
    address: AddressModel(
      street: 'Blanchisseuse Road',
      city: 'Arima',
      state: 'Arima',
      country: 'Trinidad and Tobago',
      postalCode: '300201',
    ),
    additionalInfo: 'Renowned bird watching destination',
  ),

  // 5. Pitch Lake
  LocationModel(
    id: 'loc5',
    listingType: ListingType.place,
    name: 'Pitch Lake',
    coordinates: const LatLng(10.2353, -61.6322),
    geoHashCode: 'd8k3r',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/3/3a/Pitch_Lake_Trinidad.jpg',
    address: AddressModel(
      street: 'La Brea Village',
      city: 'La Brea',
      state: 'Siparia',
      country: 'Trinidad and Tobago',
      postalCode: '720101',
    ),
    additionalInfo: 'Largest natural asphalt lake in the world',
    mainVenueId: 'plc_003',
    hostRef: ListingHostRef(
      id: 'plc_003',
      listingId: 'loc5',
      type: ListingType.place,
      name: 'Pitch Lake Tour',
      imageUrl: 'https://picsum.photos/400/300?random=308',
    ),
  ),

  // 6. Fort King George
  LocationModel(
    id: 'loc6',
    listingType: ListingType.place,
    name: 'Fort King George',
    coordinates: const LatLng(11.1844, -60.7365),
    geoHashCode: 'd8f7p',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/8/8f/Fort_King_George_Tobago.jpg',
    address: AddressModel(
      street: 'Fort Street',
      city: 'Scarborough',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910101',
    ),
    additionalInfo: 'Historic fort overlooking Scarborough',
    mainVenueId: 'plc_007',
    hostRef: ListingHostRef(
      id: 'plc_007',
      listingId: 'loc6',
      type: ListingType.place,
      name: 'Fort King George Historical Site',
      imageUrl: 'https://picsum.photos/400/300?random=320',
    ),
  ),

  // 7. Temple in the Sea
  LocationModel(
    id: 'loc7',
    listingType: ListingType.place,
    name: 'Temple in the Sea',
    coordinates: const LatLng(10.5036, -61.4722),
    geoHashCode: 'd8k6d',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/7/7e/Temple_in_the_Sea_Trinidad.jpg',
    address: AddressModel(
      street: 'Waterloo Road',
      city: 'Chaguanas',
      state: 'Caroni',
      country: 'Trinidad and Tobago',
      postalCode: '500101',
    ),
    additionalInfo: 'Spiritual and cultural landmark',
  ),

  // 8. Caroni Bird Sanctuary
  LocationModel(
    id: 'loc8',
    listingType: ListingType.place,
    name: 'Caroni Bird Sanctuary',
    coordinates: const LatLng(10.5833, -61.4167),
    geoHashCode: 'd8k6f',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/7/78/Scarlet_Ibis_at_Caroni_Swamp_Trinidad.jpg',
    address: AddressModel(
      street: 'Waterloo Road',
      city: 'Caroni',
      state: 'Caroni',
      country: 'Trinidad and Tobago',
      postalCode: '500102',
    ),
    additionalInfo: 'Home to the national bird - Scarlet Ibis',
    mainVenueId: 'plc_005',
    hostRef: ListingHostRef(
      id: 'plc_005',
      listingId: 'loc8',
      type: ListingType.place,
      name: 'Caroni Bird Sanctuary Tour',
      imageUrl: 'https://picsum.photos/400/300?random=314',
    ),
  ),

  // 9. Argyle Waterfall
  LocationModel(
    id: 'loc9',
    listingType: ListingType.place,
    name: 'Argyle Waterfall',
    coordinates: const LatLng(11.2591, -60.6063),
    geoHashCode: 'd8f7m',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/0/0e/Argyle_Waterfall_Tobago.jpg',
    address: AddressModel(
      street: 'Roxborough-Parlatuvier Road',
      city: 'Roxborough',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910201',
    ),
    additionalInfo: "Tobago's highest and most famous waterfall",
    mainVenueId: 'plc_006',
    hostRef: ListingHostRef(
      id: 'plc_006',
      listingId: 'loc9',
      type: ListingType.place,
      name: 'Argyle Waterfall Adventure',
      imageUrl: 'https://picsum.photos/400/300?random=317',
    ),
  ),

  // 10. Hanuman Murti
  LocationModel(
    id: 'loc10',
    listingType: ListingType.place,
    name: 'Hanuman Murti',
    coordinates: const LatLng(10.4656, -61.4258),
    geoHashCode: 'd8k5h',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/3/34/Hanuman_Statue_Trinidad.jpg',
    address: AddressModel(
      street: 'Waterloo Road',
      city: 'Carapichaima',
      state: 'Caroni',
      country: 'Trinidad and Tobago',
      postalCode: '500103',
    ),
    additionalInfo:
        '85-foot tall statue of Lord Hanuman, tallest in the Caribbean',
  ),

  // 11. Hyatt Regency Trinidad - Main location for events
  LocationModel(
    id: 'loc11',
    listingType: ListingType.place,
    name: 'Hyatt Regency Trinidad',
    coordinates: const LatLng(10.6527, -61.5174),
    geoHashCode: 'd8k9z',
    imageUrl: 'https://picsum.photos/400/300?random=903',
    address: AddressModel(
      street: '1 Avenue of the Republic',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120103',
    ),
    additionalInfo: 'Luxury waterfront hotel - Venue for TechConf 2025',
    mainVenueId: 'htl_001',
    hostRef: ListingHostRef(
      id: 'htl_001',
      listingId: 'loc11',
      type: ListingType.hotel,
      name: 'Hyatt Regency Trinidad - Luxury Stay',
      imageUrl: 'https://picsum.photos/400/300?random=201',
    ),
    childListings: [
      ListingHostRef(
        id: 'srv_001',
        listingId: 'loc11',
        type: ListingType.service,
        name: 'Luxury Spa Package at Hyatt',
        imageUrl: 'https://picsum.photos/400/300?random=401',
      ),
      ListingHostRef(
        id: 'evt_001',
        listingId: 'loc11',
        type: ListingType.event,
        name: 'TechConf 2025 - Trinidad',
        imageUrl: 'https://picsum.photos/400/300?random=101',
      ),
      ListingHostRef(
        id: 'evt_003',
        listingId: 'loc11',
        type: ListingType.event,
        name: 'Caribbean AI & Machine Learning Summit',
        imageUrl: 'https://picsum.photos/400/300?random=109',
      ),
    ],
  ),

  // 12. NAPA - National Academy for the Performing Arts
  LocationModel(
    id: 'loc12',
    listingType: ListingType.place,
    name: 'National Academy for the Performing Arts (NAPA)',
    coordinates: const LatLng(10.6542, -61.5161),
    geoHashCode: 'd8k9x',
    imageUrl: 'https://picsum.photos/400/300?random=904',
    address: AddressModel(
      street: '2-4 Frederick St',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120104',
    ),
    additionalInfo: 'Premier performing arts venue',
    childListings: [
      ListingHostRef(
        id: 'srv_002',
        listingId: 'loc12',
        type: ListingType.service,
        name: 'Steelpan Music Lessons',
        imageUrl: 'https://picsum.photos/400/300?random=404',
      ),
    ],
  ),

  // 13. Trinidad Convention Centre
  LocationModel(
    id: 'loc13',
    listingType: ListingType.place,
    name: 'Trinidad Convention Centre',
    coordinates: const LatLng(10.6545, -61.5201),
    geoHashCode: 'd8k9w',
    imageUrl: 'https://picsum.photos/400/300?random=901',
    address: AddressModel(
      street: '1-5 Wrightson Rd',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120101',
    ),
    additionalInfo: 'Main convention center in Trinidad',
  ),

  // 14. Courtyard by Marriott Port of Spain
  LocationModel(
    id: 'loc14',
    listingType: ListingType.place,
    name: 'Courtyard by Marriott Port of Spain',
    coordinates: const LatLng(10.6614, -61.5257),
    geoHashCode: 'd8k9v',
    imageUrl: 'https://picsum.photos/400/300?random=906',
    address: AddressModel(
      street: '12-16 Invaders Bay, Audrey Jeffers Hwy',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120105',
    ),
    additionalInfo: 'Modern hotel with waterfront views',
    mainVenueId: 'htl_004',
    hostRef: ListingHostRef(
      id: 'htl_004',
      listingId: 'loc14',
      type: ListingType.hotel,
      name: 'Courtyard by Marriott Port of Spain',
      imageUrl: 'https://picsum.photos/400/300?random=211',
    ),
  ),

  // 15. Hilton Trinidad & Conference Centre
  LocationModel(
    id: 'loc15',
    listingType: ListingType.place,
    name: 'Hilton Trinidad & Conference Centre',
    coordinates: const LatLng(10.6797, -61.5178),
    geoHashCode: 'd8k9u',
    imageUrl: 'https://picsum.photos/400/300?random=907',
    address: AddressModel(
      street: 'Lady Young Rd',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120106',
    ),
    additionalInfo: 'Iconic hotel with panoramic city views',
    mainVenueId: 'htl_002',
    hostRef: ListingHostRef(
      id: 'htl_002',
      listingId: 'loc15',
      type: ListingType.hotel,
      name: 'Hilton Trinidad & Conference Centre',
      imageUrl: 'https://picsum.photos/400/300?random=205',
    ),
  ),

  // 16. Magdalena Grand Beach & Golf Resort
  LocationModel(
    id: 'loc16',
    listingType: ListingType.place,
    name: 'Magdalena Grand Beach & Golf Resort',
    coordinates: const LatLng(11.1629, -60.7625),
    geoHashCode: 'd8f7r',
    imageUrl: 'https://picsum.photos/400/300?random=914',
    address: AddressModel(
      street: 'Lowlands',
      city: 'Lowlands',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910103',
    ),
    additionalInfo: 'Luxury resort with golf course',
    mainVenueId: 'htl_003',
    hostRef: ListingHostRef(
      id: 'htl_003',
      listingId: 'loc16',
      type: ListingType.hotel,
      name: 'Magdalena Grand Beach & Golf Resort',
      imageUrl: 'https://picsum.photos/400/300?random=208',
    ),
  ),

  // 17. Store Bay Beach Facility
  LocationModel(
    id: 'loc17',
    listingType: ListingType.place,
    name: 'Store Bay Beach Facility',
    coordinates: const LatLng(11.1473, -60.8356),
    geoHashCode: 'd8f7s',
    imageUrl: 'https://picsum.photos/400/300?random=913',
    address: AddressModel(
      street: 'Store Bay Local Rd',
      city: 'Crown Point',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910104',
    ),
    additionalInfo: 'Popular beach near airport',
    mainVenueId: 'htl_005',
    hostRef: ListingHostRef(
      id: 'htl_005',
      listingId: 'loc17',
      type: ListingType.hotel,
      name: 'Store Bay Beach Resort',
      imageUrl: 'https://picsum.photos/400/300?random=214',
    ),
  ),

  // 18. Piarco International Airport
  LocationModel(
    id: 'loc18',
    listingType: ListingType.place,
    name: 'Piarco International Airport',
    coordinates: const LatLng(10.5896, -61.3393),
    geoHashCode: 'd8k8n',
    imageUrl: 'https://picsum.photos/400/300?random=910',
    address: AddressModel(
      street: 'Golden Grove Rd',
      city: 'Piarco',
      state: 'Tunapuna-Piarco',
      country: 'Trinidad and Tobago',
      postalCode: '350104',
    ),
    additionalInfo: 'Main international airport',
  ),

  // 19. MovieTowne Port of Spain
  LocationModel(
    id: 'loc19',
    listingType: ListingType.place,
    name: 'MovieTowne Port of Spain',
    coordinates: const LatLng(10.6621, -61.5267),
    geoHashCode: 'd8k9t',
    imageUrl: 'https://picsum.photos/400/300?random=921',
    address: AddressModel(
      street: 'Invaders Bay, Audrey Jeffers Hwy',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120111',
    ),
    additionalInfo: 'Entertainment complex with cinemas and dining',
  ),

  // 20. Capsule CoWorking Space
  LocationModel(
    id: 'loc20',
    listingType: ListingType.place,
    name: 'Capsule CoWorking Space',
    coordinates: const LatLng(10.6507, -61.5169),
    geoHashCode: 'd8k9s',
    imageUrl: 'https://picsum.photos/400/300?random=908',
    address: AddressModel(
      street: '53-55 Sackville St',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120107',
    ),
    additionalInfo: 'Modern co-working space in downtown',
    childListings: [
      ListingHostRef(
        id: 'srv_003',
        listingId: 'loc20',
        type: ListingType.service,
        name: 'Professional Photography Services',
        imageUrl: 'https://picsum.photos/400/300?random=407',
      ),
      ListingHostRef(
        id: 'evt_004',
        listingId: 'loc20',
        type: ListingType.event,
        name: 'Startup Pitch Competition - Caribbean Edition',
        imageUrl: 'https://picsum.photos/400/300?random=112',
      ),
    ],
  ),

  // =============================================
  // CARIBBEAN AIRPORTS WITH PROPER RELATIONSHIPS
  // =============================================

  // 21. Antigua Airport - Has child listings
  LocationModel(
    id: 'antigua_vc_bird',
    listingType: ListingType.place,
    name: 'V.C. Bird International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1001',
    coordinates: const LatLng(17.1368, -61.7927),
    geoHashCode: 'd8f9k',
    address: AddressModel(
      street: '',
      city: "St. John's",
      state: '',
      country: 'Antigua and Barbuda',
      postalCode: '',
    ),
    additionalInfo: 'Main international airport serving Antigua and Barbuda',
    mainVenueId: 'antigua_airport',
    hostRef: ListingHostRef(
      id: 'antigua_airport',
      listingId: 'antigua_vc_bird',
      type: ListingType.place,
      name: 'V.C. Bird International Airport',
      imageUrl: 'https://picsum.photos/400/300?random=2001',
    ),
    childListings: [
      ListingHostRef(
        id: 'store_001',
        listingId: 'antigua_vc_bird',
        type: ListingType.place,
        name: 'Antigua Duty Free - Airport Store',
        imageUrl: 'https://picsum.photos/400/300?random=2004',
      ),
      ListingHostRef(
        id: 'store_002',
        listingId: 'antigua_vc_bird',
        type: ListingType.place,
        name: 'Sky Lounge Restaurant & Bar',
        imageUrl: 'https://picsum.photos/400/300?random=2007',
      ),
      ListingHostRef(
        id: 'store_003',
        listingId: 'antigua_vc_bird',
        type: ListingType.place,
        name: 'Antigua Car Rentals - Airport Desk',
        imageUrl: 'https://picsum.photos/400/300?random=2010',
      ),
    ],
  ),

  // 22. Bahamas Airport
  LocationModel(
    id: 'bahamas_lynden_pindling',
    listingType: ListingType.place,
    name: 'Lynden Pindling International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1002',
    coordinates: const LatLng(25.0393, -77.4662),
    geoHashCode: 'd9j7f',
    address: AddressModel(
      street: '',
      city: 'Nassau',
      state: '',
      country: 'Bahamas',
      postalCode: '',
    ),
    additionalInfo: 'Largest airport in the Bahamas',
  ),

  // 23. Barbados Airport
  LocationModel(
    id: 'barbados_grantley_adams',
    listingType: ListingType.place,
    name: 'Grantley Adams International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1003',
    coordinates: const LatLng(13.0746, -59.4925),
    geoHashCode: 'd8f4x',
    address: AddressModel(
      street: '',
      city: 'Bridgetown',
      state: '',
      country: 'Barbados',
      postalCode: '',
    ),
    additionalInfo: 'Main gateway to Barbados',
  ),

  // 24. Cuba Airport
  LocationModel(
    id: 'cuba_jose_marti',
    listingType: ListingType.place,
    name: 'José Martí International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1004',
    coordinates: const LatLng(22.9892, -82.4091),
    geoHashCode: 'd9j8v',
    address: AddressModel(
      street: '',
      city: 'Havana',
      state: '',
      country: 'Cuba',
      postalCode: '',
    ),
    additionalInfo: "Cuba's main international airport",
  ),

  // 25. Dominica Airport
  LocationModel(
    id: 'dominica_douglas_charles',
    listingType: ListingType.place,
    name: 'Douglas–Charles Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1005',
    coordinates: const LatLng(15.5471, -61.2999),
    geoHashCode: 'd8f7m',
    address: AddressModel(
      street: '',
      city: 'Roseau',
      state: '',
      country: 'Dominica',
      postalCode: '',
    ),
    additionalInfo: 'One of two airports in Dominica',
  ),

  // 26. Dominican Republic - Las Americas
  LocationModel(
    id: 'dominican_republic_las_americas',
    listingType: ListingType.place,
    name: 'Las Américas International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1006',
    coordinates: const LatLng(18.4297, -69.6689),
    geoHashCode: 'd8f5p',
    address: AddressModel(
      street: '',
      city: 'Santo Domingo',
      state: '',
      country: 'Dominican Republic',
      postalCode: '',
    ),
    additionalInfo: 'Major airport serving Santo Domingo',
  ),

  // 27. Grenada Airport
  LocationModel(
    id: 'grenada_maurice_bishop',
    listingType: ListingType.place,
    name: 'Maurice Bishop International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1007',
    coordinates: const LatLng(12.0043, -61.7862),
    geoHashCode: 'd8f8n',
    address: AddressModel(
      street: '',
      city: "St. George's",
      state: '',
      country: 'Grenada',
      postalCode: '',
    ),
    additionalInfo: "Grenada's main international airport",
  ),

  // 28. Haiti Airport
  LocationModel(
    id: 'haiti_toussaint_louverture',
    listingType: ListingType.place,
    name: 'Toussaint Louverture International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1008',
    coordinates: const LatLng(18.5797, -72.2938),
    geoHashCode: 'd8f3r',
    address: AddressModel(
      street: '',
      city: 'Port-au-Prince',
      state: '',
      country: 'Haiti',
      postalCode: '',
    ),
    additionalInfo: "Haiti's busiest airport",
  ),

  // 29. Jamaica - Norman Manley
  LocationModel(
    id: 'jamaica_norman_manley',
    listingType: ListingType.place,
    name: 'Norman Manley International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1009',
    coordinates: const LatLng(17.9357, -76.7875),
    geoHashCode: 'd9j6g',
    address: AddressModel(
      street: '',
      city: 'Kingston',
      state: '',
      country: 'Jamaica',
      postalCode: '',
    ),
    additionalInfo: "One of Jamaica's major international airports",
  ),

  // 30. Saint Kitts Airport
  LocationModel(
    id: 'saint_kitts_robert_bradshaw',
    listingType: ListingType.place,
    name: 'Robert L. Bradshaw International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1010',
    coordinates: const LatLng(17.3109, -62.7186),
    geoHashCode: 'd8f6h',
    address: AddressModel(
      street: '',
      city: 'Basseterre',
      state: '',
      country: 'Saint Kitts and Nevis',
      postalCode: '',
    ),
    additionalInfo: 'Main airport serving St. Kitts',
  ),

  // 31. Saint Lucia Airport
  LocationModel(
    id: 'saint_lucia_hewanorra',
    listingType: ListingType.place,
    name: 'Hewanorra International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1011',
    coordinates: const LatLng(13.7332, -60.9526),
    geoHashCode: 'd8f7p',
    address: AddressModel(
      street: '',
      city: 'Castries',
      state: '',
      country: 'Saint Lucia',
      postalCode: '',
    ),
    additionalInfo: "Saint Lucia's main international airport",
  ),

  // 32. Saint Vincent Airport
  LocationModel(
    id: 'saint_vincent_argyle',
    listingType: ListingType.place,
    name: 'Argyle International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1012',
    coordinates: const LatLng(13.1579, -61.2133),
    geoHashCode: 'd8f7n',
    address: AddressModel(
      street: '',
      city: 'Kingstown',
      state: '',
      country: 'Saint Vincent and the Grenadines',
      postalCode: '',
    ),
    additionalInfo: 'New international airport opened in 2017',
  ),

  // 33. Trinidad & Tobago - Piarco
  LocationModel(
    id: 'trinidad_tobago_piarco',
    listingType: ListingType.place,
    name: 'Piarco International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1013',
    coordinates: const LatLng(10.5954, -61.3372),
    geoHashCode: 'd8k8j',
    address: AddressModel(
      street: '',
      city: 'Port of Spain',
      state: '',
      country: 'Trinidad and Tobago',
      postalCode: '',
    ),
    additionalInfo: 'Main international airport of Trinidad and Tobago',
  ),

  // 34. Jamaica - Sangster
  LocationModel(
    id: 'jamaica_sangster',
    listingType: ListingType.place,
    name: 'Sangster International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1014',
    coordinates: const LatLng(18.5042, -77.9143),
    geoHashCode: 'd9j6h',
    address: AddressModel(
      street: '',
      city: 'Montego Bay',
      state: '',
      country: 'Jamaica',
      postalCode: '',
    ),
    additionalInfo: "Jamaica's busiest airport in Montego Bay",
  ),

  // 35. Aruba Airport
  LocationModel(
    id: 'aruba_reina_beatrix',
    listingType: ListingType.place,
    name: 'Queen Beatrix International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1015',
    coordinates: const LatLng(12.5014, -70.0152),
    geoHashCode: 'd8f2m',
    address: AddressModel(
      street: '',
      city: 'Oranjestad',
      state: '',
      country: 'Aruba',
      postalCode: '',
    ),
    additionalInfo: "Aruba's main international airport",
  ),

  // 36. Curacao Airport
  LocationModel(
    id: 'curacao_hato',
    listingType: ListingType.place,
    name: 'Hato International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1016',
    coordinates: const LatLng(12.1888, -68.9594),
    geoHashCode: 'd8f3p',
    address: AddressModel(
      street: '',
      city: 'Willemstad',
      state: '',
      country: 'Curaçao',
      postalCode: '',
    ),
    additionalInfo: "Curaçao's main airport",
  ),

  // 37. Puerto Rico Airport
  LocationModel(
    id: 'puerto_rico_luis_munoz',
    listingType: ListingType.place,
    name: 'Luis Muñoz Marín International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1017',
    coordinates: const LatLng(18.4394, -66.0018),
    geoHashCode: 'd8f5r',
    address: AddressModel(
      street: '',
      city: 'San Juan',
      state: '',
      country: 'Puerto Rico',
      postalCode: '',
    ),
    additionalInfo: "Puerto Rico's largest airport",
  ),

  // 38. Dominican Republic - Punta Cana
  LocationModel(
    id: 'dominican_republic_punta_cana',
    listingType: ListingType.place,
    name: 'Punta Cana International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1018',
    coordinates: const LatLng(18.5671, -68.3634),
    geoHashCode: 'd8f4r',
    address: AddressModel(
      street: '',
      city: 'Punta Cana',
      state: '',
      country: 'Dominican Republic',
      postalCode: '',
    ),
    additionalInfo: 'Busiest airport in the Dominican Republic',
  ),

  // 39. Bahamas - Grand Bahama
  LocationModel(
    id: 'bahamas_grand_bahama',
    listingType: ListingType.place,
    name: 'Grand Bahama International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1019',
    coordinates: const LatLng(26.5587, -78.6956),
    geoHashCode: 'd9j7h',
    address: AddressModel(
      street: '',
      city: 'Freeport',
      state: '',
      country: 'Bahamas',
      postalCode: '',
    ),
    additionalInfo: 'Serving Freeport on Grand Bahama Island',
  ),

  // 40. Sint Maarten Airport
  LocationModel(
    id: 'sint_maarten_princess_juliana',
    listingType: ListingType.place,
    name: 'Princess Juliana International Airport',
    imageUrl: 'https://picsum.photos/400/300?random=1020',
    coordinates: const LatLng(18.0401, -63.1090),
    geoHashCode: 'd8f6n',
    address: AddressModel(
      street: '',
      city: 'Philipsburg',
      state: '',
      country: 'Sint Maarten',
      postalCode: '',
    ),
    additionalInfo: 'Famous for low-flying aircraft approach over Maho Beach',
  ),
];
// Models for location relationships
// =============================================
// UPDATED LISTINGHOSTREF WITH listingId
// =============================================

// =============================================
// UPDATED MOCK LOCATIONS WITH LISTINGHOSTREF
// =============================================

class LocationFilter {
  final String? id;
  final String? name;
  final String? search;
  final String? country;
  final String? state;
  final String? city;
  final LatLng? center;
  final double? radiusKm;
  final bool Function(LocationModel)? customFilter;
  final bool isExclusive;

  const LocationFilter({
    this.id,
    this.name,
    this.search,
    this.country,
    this.state,
    this.city,
    this.center,
    this.radiusKm,
    this.customFilter,
    this.isExclusive = false,
  });

  bool get hasFilters =>
      search != null ||
      country != null ||
      state != null ||
      city != null ||
      center != null ||
      customFilter != null;

  bool get isPreset => id != null && name != null;

  LocationFilter copyWith({
    String? id,
    String? name,
    String? search,
    String? country,
    String? state,
    String? city,
    LatLng? center,
    double? radiusKm,
    bool Function(LocationModel)? customFilter,
    bool? isExclusive,
    bool clearSearch = false,
    bool clearCountry = false,
    bool clearState = false,
    bool clearCity = false,
    bool clearCenter = false,
    bool clearRadius = false,
    bool clearSortBy = false,
    bool clearCustomFilter = false,
  }) {
    return LocationFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      search: clearSearch ? null : search ?? this.search,
      country: clearCountry ? null : country ?? this.country,
      state: clearState ? null : state ?? this.state,
      city: clearCity ? null : city ?? this.city,
      center: clearCenter ? null : center ?? this.center,
      radiusKm: clearRadius ? null : radiusKm ?? this.radiusKm,
      customFilter: clearCustomFilter
          ? null
          : customFilter ?? this.customFilter,
      isExclusive: isExclusive ?? this.isExclusive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (search != null) 'search': search,
      if (country != null) 'country': country,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (center != null) ...{
        'centerLat': center!.latitude,
        'centerLng': center!.longitude,
      },
      if (radiusKm != null) 'radiusKm': radiusKm,
      'isExclusive': isExclusive,
    };
  }

  factory LocationFilter.fromJson(Map<String, dynamic> json) {
    return LocationFilter(
      id: json['id'] as String?,
      name: json['name'] as String?,
      search: json['search'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      center: json['centerLat'] != null && json['centerLng'] != null
          ? LatLng(
              (json['centerLat'] as num).toDouble(),
              (json['centerLng'] as num).toDouble(),
            )
          : null,
      radiusKm: json['radiusKm'] != null
          ? (json['radiusKm'] as num).toDouble()
          : null,
      isExclusive: json['isExclusive'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationFilter) return false;

    return other.id == id &&
        other.name == name &&
        other.search == search &&
        other.country == country &&
        other.state == state &&
        other.city == city &&
        other.center == center &&
        other.radiusKm == radiusKm &&
        other.isExclusive == isExclusive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      search,
      country,
      state,
      city,
      center,
      radiusKm,
      isExclusive,
    );
  }

  factory LocationFilter.preset({
    required String name,
    String? search,
    String? country,
    String? state,
    String? city,
    LatLng? center,
    double? radiusKm,
    bool isExclusive = false,
  }) {
    return LocationFilter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      search: search,
      country: country,
      state: state,
      city: city,
      center: center,
      radiusKm: radiusKm,
      isExclusive: isExclusive,
    );
  }

  @override
  String toString() {
    return 'LocationFilter(id: $id, name: $name, hasFilters: $hasFilters)';
  }
}

class AddressModel {
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String? title; // For naming addresses (Home, Office, etc.)
  final bool isDefault; // For default address selection

  const AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.title,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $state, $country';

  String get displayName => title?.isNotEmpty == true ? title! : fullAddress;

  factory AddressModel.fromJson(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      postalCode: map['postalCode'] ?? '',
      title: map['title'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "street": street,
    "city": city,
    "state": state,
    "country": country,
    "postalCode": postalCode,
    "title": title,
    "isDefault": isDefault,
  };

  AddressModel copyWith({
    String? street,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? title,
    bool? isDefault,
  }) {
    return AddressModel(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      title: title ?? this.title,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'AddressModel(street: $street, city: $city, state: $state, country: $country, postalCode: $postalCode, title: $title, isDefault: $isDefault)';
  }
}

// =============================================
// FIXED MOCK LOCATIONS WITH PROPER RELATIONSHIPS
// =============================================

String getFlag(String country) {
  switch (country.toLowerCase().trim()) {
    // Africa
    case 'nigeria':
      return '🇳🇬';
    case 'ghana':
      return '🇬🇭';
    case 'kenya':
      return '🇰🇪';
    case 'south africa':
      return '🇿🇦';
    case 'egypt':
      return '🇪🇬';
    case 'morocco':
      return '🇲🇦';
    case 'tanzania':
      return '🇹🇿';
    case 'uganda':
      return '🇺🇬';
    case 'rwanda':
      return '🇷🇼';
    case 'ethiopia':
      return '🇪🇹';
    // case 'ghana':
    //   return '🇬🇭';
    case 'senegal':
      return '🇸🇳';
    case 'ivory coast':
    case 'côte d\'ivoire':
      return '🇨🇮';
    case 'cameroon':
      return '🇨🇲';
    case 'angola':
      return '🇦🇴';
    case 'mozambique':
      return '🇲🇿';
    case 'zimbabwe':
      return '🇿🇼';
    case 'zambia':
      return '🇿🇲';
    case 'botswana':
      return '🇧🇼';
    case 'namibia':
      return '🇳🇦';
    case 'malawi':
      return '🇲🇼';
    case 'madagascar':
      return '🇲🇬';
    case 'mauritius':
      return '🇲🇺';
    case 'seychelles':
      return '🇸🇨';

    // Caribbean - Full List
    case 'antigua and barbuda':
      return '🇦🇬';
    case 'bahamas':
      return '🇧🇸';
    case 'barbados':
      return '🇧🇧';
    case 'cuba':
      return '🇨🇺';
    case 'dominica':
      return '🇩🇲';
    case 'dominican republic':
      return '🇩🇴';
    case 'grenada':
      return '🇬🇩';
    case 'haiti':
      return '🇭🇹';
    case 'jamaica':
      return '🇯🇲';
    case 'saint kitts and nevis':
    case 'st. kitts and nevis':
    case 'st kitts and nevis':
      return '🇰🇳';
    case 'saint lucia':
    case 'st. lucia':
    case 'st lucia':
      return '🇱🇨';
    case 'saint vincent and the grenadines':
    case 'st. vincent and the grenadines':
    case 'st vincent and the grenadines':
      return '🇻🇨';
    case 'trinidad and tobago':
      return '🇹🇹';

    // North America
    case 'united states':
    case 'usa':
    case 'united states of america':
      return '🇺🇸';
    case 'canada':
      return '🇨🇦';
    case 'mexico':
      return '🇲🇽';

    // Central America
    case 'belize':
      return '🇧🇿';
    case 'costa rica':
      return '🇨🇷';
    case 'el salvador':
      return '🇸🇻';
    case 'guatemala':
      return '🇬🇹';
    case 'honduras':
      return '🇭🇳';
    case 'nicaragua':
      return '🇳🇮';
    case 'panama':
      return '🇵🇦';

    // South America
    case 'argentina':
      return '🇦🇷';
    case 'bolivia':
      return '🇧🇴';
    case 'brazil':
      return '🇧🇷';
    case 'chile':
      return '🇨🇱';
    case 'colombia':
      return '🇨🇴';
    case 'ecuador':
      return '🇪🇨';
    case 'guyana':
      return '🇬🇾';
    case 'paraguay':
      return '🇵🇾';
    case 'peru':
      return '🇵🇪';
    case 'suriname':
      return '🇸🇷';
    case 'uruguay':
      return '🇺🇾';
    case 'venezuela':
      return '🇻🇪';

    // Europe
    case 'united kingdom':
    case 'uk':
    case 'england':
    case 'great britain':
      return '🇬🇧';
    case 'france':
      return '🇫🇷';
    case 'germany':
      return '🇩🇪';
    case 'italy':
      return '🇮🇹';
    case 'spain':
      return '🇪🇸';
    case 'portugal':
      return '🇵🇹';
    case 'netherlands':
      return '🇳🇱';
    case 'belgium':
      return '🇧🇪';
    case 'switzerland':
      return '🇨🇭';
    case 'austria':
      return '🇦🇹';
    case 'sweden':
      return '🇸🇪';
    case 'norway':
      return '🇳🇴';
    case 'denmark':
      return '🇩🇰';
    case 'finland':
      return '🇫🇮';
    case 'ireland':
      return '🇮🇪';
    case 'greece':
      return '🇬🇷';
    case 'turkey':
      return '🇹🇷';
    case 'russia':
      return '🇷🇺';
    case 'poland':
      return '🇵🇱';
    case 'ukraine':
      return '🇺🇦';
    case 'romania':
      return '🇷🇴';
    case 'hungary':
      return '🇭🇺';
    case 'czech republic':
    case 'czechia':
      return '🇨🇿';
    case 'slovakia':
      return '🇸🇰';
    case 'croatia':
      return '🇭🇷';
    case 'serbia':
      return '🇷🇸';
    case 'bulgaria':
      return '🇧🇬';

    // Asia
    case 'china':
      return '🇨🇳';
    case 'japan':
      return '🇯🇵';
    case 'south korea':
    case 'korea':
      return '🇰🇷';
    case 'india':
      return '🇮🇳';
    case 'pakistan':
      return '🇵🇰';
    case 'bangladesh':
      return '🇧🇩';
    case 'indonesia':
      return '🇮🇩';
    case 'malaysia':
      return '🇲🇾';
    case 'singapore':
      return '🇸🇬';
    case 'philippines':
      return '🇵🇭';
    case 'thailand':
      return '🇹🇭';
    case 'vietnam':
      return '🇻🇳';
    case 'myanmar':
      return '🇲🇲';
    case 'nepal':
      return '🇳🇵';
    case 'sri lanka':
      return '🇱🇰';
    case 'israel':
      return '🇮🇱';
    case 'saudi arabia':
      return '🇸🇦';
    case 'united arab emirates':
    case 'uae':
      return '🇦🇪';
    case 'qatar':
      return '🇶🇦';
    case 'kuwait':
      return '🇰🇼';
    case 'oman':
      return '🇴🇲';
    case 'bahrain':
      return '🇧🇭';
    case 'lebanon':
      return '🇱🇧';
    case 'jordan':
      return '🇯🇴';
    case 'iraq':
      return '🇮🇶';
    case 'iran':
      return '🇮🇷';
    case 'afghanistan':
      return '🇦🇫';
    case 'kazakhstan':
      return '🇰🇿';

    // Oceania
    case 'australia':
      return '🇦🇺';
    case 'new zealand':
      return '🇳🇿';
    case 'fiji':
      return '🇫🇯';
    case 'papua new guinea':
      return '🇵🇬';
    case 'samoa':
      return '🇼🇸';

    // Caribbean Islands (Additional)
    case 'anguilla':
      return '🇦🇮';
    case 'aruba':
      return '🇦🇼';
    case 'bermuda':
      return '🇧🇲';
    case 'bonaire':
      return '🇧🇶';
    case 'british virgin islands':
    case 'bvi':
      return '🇻🇬';
    case 'cayman islands':
      return '🇰🇾';
    case 'curacao':
      return '🇨🇼';
    case 'falkland islands':
      return '🇫🇰';
    case 'french guiana':
      return '🇬🇫';
    case 'greenland':
      return '🇬🇱';
    case 'guadeloupe':
      return '🇬🇵';
    case 'martinique':
      return '🇲🇶';
    case 'montserrat':
      return '🇲🇸';
    case 'puerto rico':
      return '🇵🇷';
    case 'saint barthélemy':
    case 'st. barthélemy':
    case 'st barthélemy':
      return '🇧🇱';
    case 'saint martin':
    case 'st. martin':
    case 'st martin':
      return '🇲🇫';
    case 'sint maarten':
      return '🇸🇽';
    case 'turks and caicos islands':
      return '🇹🇨';
    case 'us virgin islands':
    case 'usvi':
      return '🇻🇮';

    default:
      return '📍';
  }
}
