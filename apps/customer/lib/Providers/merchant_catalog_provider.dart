// lib/providers/merchant_catalog_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/models/room_model.dart';
import 'package:lehwipalancecustomerv1/core/models/service_item_model.dart';
import 'package:lehwipalancecustomerv1/core/models/ticket_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

/// Provider for managing merchant catalog data

/// Provider for managing merchant catalog data
class MerchantCatalogProvider extends ChangeNotifier {
  final ApiService _apiService;

  // Cache for merchant listings
  MerchantListingDTO? _merchantListing;

  // Cache for items
  List<TicketDTO> _tickets = [];
  List<RoomDTO> _rooms = [];
  List<ServiceItemDTO> _services = [];

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoadingTickets = false;
  bool _isLoadingRooms = false;
  bool _isLoadingServices = false;

  // Error states
  String? _error;
  String? _ticketsError;
  String? _roomsError;
  String? _servicesError;

  MerchantCatalogProvider({ApiService? apiService})
    : _apiService = apiService ?? MockApiService();

  // =============================================
  // GETTERS
  // =============================================

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoadingTickets => _isLoadingTickets;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingServices => _isLoadingServices;

  String? get error => _error;
  String? get ticketsError => _ticketsError;
  String? get roomsError => _roomsError;
  String? get servicesError => _servicesError;

  MerchantListingDTO? get merchantListing => _merchantListing;
  List<TicketDTO> get tickets => _tickets;
  List<RoomDTO> get rooms => _rooms;
  List<ServiceItemDTO> get services => _services;

  // =============================================
  // TYPE CHECKERS (Using the unified DTO)
  // =============================================

  bool get isEvent => _merchantListing?.isEvent ?? false;
  bool get isAccommodation => _merchantListing?.isAccommodation ?? false;
  bool get isPlace => _merchantListing?.isPlace ?? false;
  bool get isService => _merchantListing?.isService ?? false;

  // =============================================
  // INITIALIZATION
  // =============================================

  /// Initialize the provider with a merchant ID
  Future<void> initialize({required String merchantId}) async {
    if (_isLoading) return;
    if (_isInitialized && _merchantListing?.id == merchantId) return;

    _isLoading = true;
    _error = null;
    _isInitialized = false;
    notifyListeners();

    try {
      // Load merchant listing
      _merchantListing = await _apiService.getMerchantListingById(merchantId);

      if (_merchantListing == null) {
        throw Exception('Merchant listing not found for ID: $merchantId');
      }

      debugPrint(
        'Loaded merchant listing: ${_merchantListing!.title} - Type: ${_merchantListing!.type}',
      );

      _isInitialized = true;

      // Auto-load items based on listing type
      await _loadAllItems();
    } catch (e) {
      _error = 'Failed to initialize catalog: $e';
      debugPrint('Error initializing catalog: $e');
      _merchantListing = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =============================================
  // ITEM LOADING
  // =============================================

  /// Load all items (tickets, rooms, services) based on merchant type
  Future<void> _loadAllItems() async {
    if (_merchantListing == null) return;

    final listing = _merchantListing!;

    // Load based on listing type using the unified DTO's type checkers
    if (listing.isEvent) {
      await loadTickets();
      _rooms = [];
      _services = [];
    } else if (listing.isAccommodation) {
      await Future.wait([loadRooms(), loadServices()]);
      // Accommodation might have tickets too (e.g., event tickets at a hotel)
      await loadTickets();
    } else if (listing.isPlace) {
      // Places might have services or tickets
      await Future.wait([loadServices(), loadTickets()]);
      _rooms = [];
    } else if (listing.isService) {
      // Services might have service items
      await loadServices();
      _tickets = [];
      _rooms = [];
    } else {
      // Generic merchant - try to load everything
      await Future.wait([loadTickets(), loadRooms(), loadServices()]);
    }
  }

  /// Load tickets for the current merchant
  Future<void> loadTickets() async {
    if (_isLoadingTickets) return;
    if (_merchantListing == null) {
      _ticketsError = 'Merchant not initialized';
      return;
    }

    _isLoadingTickets = true;
    _ticketsError = null;
    notifyListeners();

    try {
      final listing = _merchantListing!;

      // Use the appropriate method based on listing type
      if (listing.isEvent) {
        // For events, get tickets by ticketTypeIds from the DTO
        if (listing.ticketTypeIds != null &&
            listing.ticketTypeIds!.isNotEmpty) {
          _tickets = await _apiService.getTicketsByIds(listing.ticketTypeIds!);
        } else {
          _tickets = await _apiService.getTicketsByEventId(listing.id);
        }
      } else if (listing.isAccommodation) {
        // For accommodation, get tickets by event IDs or merchant ID
        if (listing.accommodationEventIds != null &&
            listing.accommodationEventIds!.isNotEmpty) {
          _tickets = await _apiService.getTicketsByEventIds(
            listing.accommodationEventIds!,
          );
        } else {
          _tickets = await _apiService.getTicketsByMerchantId(listing.id);
        }
      } else {
        // Generic merchant - try to get tickets by merchant ID
        _tickets = await _apiService.getTicketsByMerchantId(listing.id);
      }

      debugPrint('Loaded ${_tickets.length} tickets');
    } catch (e) {
      _ticketsError = 'Failed to load tickets: $e';
      _tickets = [];
      debugPrint('Error loading tickets: $e');
    } finally {
      _isLoadingTickets = false;
      notifyListeners();
    }
  }

  /// Load rooms for the current merchant
  Future<void> loadRooms() async {
    if (_isLoadingRooms) return;
    if (_merchantListing == null) {
      _roomsError = 'Merchant not initialized';
      return;
    }

    _isLoadingRooms = true;
    _roomsError = null;
    notifyListeners();

    try {
      final listing = _merchantListing!;

      if (listing.isAccommodation) {
        // For accommodation, use roomIds from the DTO
        if (listing.roomIds != null && listing.roomIds!.isNotEmpty) {
          _rooms = await _apiService.getRoomsByIds(listing.roomIds!);
        } else {
          _rooms = await _apiService.getRoomsByHotelId(listing.id);
        }
      } else {
        // For other types, try to get rooms by merchant ID
        _rooms = await _apiService.getRoomsByMerchantId(listing.id);
      }

      debugPrint('Loaded ${_rooms.length} rooms');
    } catch (e) {
      _roomsError = 'Failed to load rooms: $e';
      _rooms = [];
      debugPrint('Error loading rooms: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  /// Load services for the current merchant
  Future<void> loadServices() async {
    if (_isLoadingServices) return;
    if (_merchantListing == null) {
      _servicesError = 'Merchant not initialized';
      return;
    }

    _isLoadingServices = true;
    _servicesError = null;
    notifyListeners();

    try {
      final listing = _merchantListing!;

      if (listing.isAccommodation) {
        // For accommodation, use accommodationServiceIds
        if (listing.accommodationServiceIds != null &&
            listing.accommodationServiceIds!.isNotEmpty) {
          _services = await _apiService.getServicesByIds(
            listing.accommodationServiceIds!,
          );
        } else {
          _services = await _apiService.getServicesByHotelId(listing.id);
        }
      } else if (listing.isService) {
        // For service listings, use serviceTypeIds
        if (listing.serviceTypeIds != null &&
            listing.serviceTypeIds!.isNotEmpty) {
          _services = await _apiService.getServicesByIds(
            listing.serviceTypeIds!,
          );
        } else {
          _services = await _apiService.getServicesByMerchantId(listing.id);
        }
      } else if (listing.isPlace) {
        // For places, use placeServiceIds
        if (listing.placeServiceIds != null &&
            listing.placeServiceIds!.isNotEmpty) {
          _services = await _apiService.getServicesByIds(
            listing.placeServiceIds!,
          );
        } else {
          _services = await _apiService.getServicesByMerchantId(listing.id);
        }
      } else {
        // Generic merchant
        _services = await _apiService.getServicesByMerchantId(listing.id);
      }

      debugPrint('Loaded ${_services.length} services');
    } catch (e) {
      _servicesError = 'Failed to load services: $e';
      _services = [];
      debugPrint('Error loading services: $e');
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  // =============================================
  // ITEM RETRIEVAL
  // =============================================

  /// Get a listing by ID - searches through the merchant's items
  MerchantListingDTO? getListingById(String itemId) {
    // First check if this merchant itself matches
    if (_merchantListing?.id == itemId) {
      return _merchantListing;
    }

    // Check if the item belongs to this merchant (ticket, room, or service)
    final hasTicket = _tickets.any((t) => t.id == itemId);
    final hasRoom = _rooms.any((r) => r.id == itemId);
    final hasService = _services.any((s) => s.id == itemId);

    // If the item belongs to any of the merchant's collections, return the merchant
    if (hasTicket || hasRoom || hasService) {
      return _merchantListing;
    }

    return null;
  }

  /// Get a ticket by ID
  TicketDTO? getTicketById(String ticketId) {
    try {
      return _tickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  /// Get a room by ID
  RoomDTO? getRoomById(String roomId) {
    try {
      return _rooms.firstWhere((r) => r.id == roomId);
    } catch (_) {
      return null;
    }
  }

  /// Get a service by ID
  ServiceItemDTO? getServiceById(String serviceId) {
    try {
      return _services.firstWhere((s) => s.id == serviceId);
    } catch (_) {
      return null;
    }
  }

  // =============================================
  // FILTERED GETTERS
  // =============================================

  /// Get available tickets (on sale and not sold out)
  List<TicketDTO> get availableTickets {
    return _tickets.where((t) => t.isOnSale && !t.isSoldOut).toList();
  }

  /// Get available rooms (published status)
  List<RoomDTO> get availableRooms {
    return _rooms.where((r) => r.status == PublishStatus.published).toList();
  }

  /// Get available services (active and published)
  List<ServiceItemDTO> get availableServices {
    return _services
        .where((s) => s.isActive && s.status == PublishStatus.published)
        .toList();
  }

  /// Get tickets by category (if applicable)
  // List<TicketDTO> getTicketsByCategory(String category) {
  //  return _tickets.where((t) => t.category == category).toList();
  // }

  /// Get rooms by type
  //  List<RoomDTO> getRoomsByType(String roomType) {
  // return _rooms.where((r) => r.roomType == roomType).toList();
  // }

  /// Get services by category
  List<ServiceItemDTO> getServicesByCategory(String category) {
    // ignore: unrelated_type_equality_checks
    return _services.where((s) => s.category == category).toList();
  }

  // =============================================
  // ITEM COUNTS
  // =============================================

  bool get hasItems {
    return _tickets.isNotEmpty || _rooms.isNotEmpty || _services.isNotEmpty;
  }

  int get totalItemCount {
    return _tickets.length + _rooms.length + _services.length;
  }

  int get availableItemsCount {
    return availableTickets.length +
        availableRooms.length +
        availableServices.length;
  }

  // =============================================
  // REFRESH METHODS
  // =============================================

  /// Refresh all data
  Future<void> refreshCatalog() async {
    if (_merchantListing == null) {
      _error = 'Merchant not initialized';
      return;
    }

    final merchantId = _merchantListing!.id;
    // Clear cache
    _tickets = [];
    _rooms = [];
    _services = [];
    _ticketsError = null;
    _roomsError = null;
    _servicesError = null;

    // Reinitialize
    await initialize(merchantId: merchantId);
  }

  /// Refresh only tickets
  Future<void> refreshTickets() async {
    await loadTickets();
  }

  /// Refresh only rooms
  Future<void> refreshRooms() async {
    await loadRooms();
  }

  /// Refresh only services
  Future<void> refreshServices() async {
    await loadServices();
  }

  // =============================================
  // RESET
  // =============================================

  /// Reset the provider state
  void reset() {
    _merchantListing = null;
    _tickets = [];
    _rooms = [];
    _services = [];
    _isLoading = false;
    _isInitialized = false;
    _isLoadingTickets = false;
    _isLoadingRooms = false;
    _isLoadingServices = false;
    _error = null;
    _ticketsError = null;
    _roomsError = null;
    _servicesError = null;
    notifyListeners();
  }
}

// =============================================
// EXTENSION: Additional helper methods
// =============================================

extension MerchantCatalogProviderExtension on MerchantCatalogProvider {
  /// Get the merchant's average rating if available
  double? get averageRating {
    return _merchantListing?.averageRating;
  }

  /// Get the merchant's star rating if available
  int? get starRating {
    return _merchantListing?.starRating;
  }

  /// Get all event categories if this is an event
  Map<String, EventCategory>? get eventCategories {
    return _merchantListing?.eventCategories;
  }

  /// Get all place categories if this is a place
  Map<String, PlaceCategory>? get placeCategories {
    return _merchantListing?.placeCategories;
  }

  /// Get all service categories if this is a service
  Map<String, ServiceCategory>? get serviceCategories {
    return _merchantListing?.serviceCategories;
  }

  /// Get all accommodation categories if this is accommodation
  Map<String, AccommodationCategory>? get accommodationCategories {
    return _merchantListing?.accommodationCategories;
  }
}
