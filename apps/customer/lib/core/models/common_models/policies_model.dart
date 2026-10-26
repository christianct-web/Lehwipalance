abstract class BaseListingPolicies {
  final CustomerPermissions permissions;

  final String cancellationPolicy;
  final Map<String, dynamic> additionalPolicies;

  const BaseListingPolicies({
    this.permissions = const CustomerPermissions(),
    this.cancellationPolicy = 'flexible',
    this.additionalPolicies = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'permissions': permissions.toMap(),
      'cancellationPolicy': cancellationPolicy,
      'additionalPolicies': additionalPolicies,
    };
  }
}

class CustomerPermissions {
  final bool adultsOnly;
  final bool requiresDeposit;
  final bool partiesAllowed;
  final bool petsAllowed;
  final bool smokingAllowed;
  final bool alcoholAllowed;
  final bool outsideFoodAllowed;
  final bool photographyAllowed;

  final bool loudMusicAllowed;
  final bool walkInsAllowed;
  final bool sameDayBookingAllowed;
  final bool refundsAllowed;
  final bool rescheduleAllowed;
  final bool requiresRegistration;
  final bool wheelchairAccessible;
  final bool parkingAvailable;
  final bool isRefundable;

  const CustomerPermissions({
    this.requiresDeposit = false,
    this.partiesAllowed = false,
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.alcoholAllowed = false,
    this.outsideFoodAllowed = false,
    this.photographyAllowed = false,
    this.loudMusicAllowed = false,
    this.walkInsAllowed = false,
    this.sameDayBookingAllowed = false,
    this.refundsAllowed = false,
    this.rescheduleAllowed = false,
    this.requiresRegistration = false,
    this.wheelchairAccessible = false,
    this.parkingAvailable = false,
    this.isRefundable = false,
    this.adultsOnly = false,
  });

  factory CustomerPermissions.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return CustomerPermissions(
      adultsOnly: data['adultsOnly'] ?? false,
      petsAllowed: data['petsAllowed'] ?? false,
      smokingAllowed: data['smokingAllowed'] ?? false,
      alcoholAllowed: data['alcoholAllowed'] ?? false,
      outsideFoodAllowed: data['outsideFoodAllowed'] ?? false,
      photographyAllowed: data['photographyAllowed'] ?? false,
      loudMusicAllowed: data['loudMusicAllowed'] ?? false,
      walkInsAllowed: data['walkInsAllowed'] ?? false,
      sameDayBookingAllowed: data['sameDayBookingAllowed'] ?? false,
      refundsAllowed: data['refundsAllowed'] ?? false,
      rescheduleAllowed: data['rescheduleAllowed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'adultsOnly': adultsOnly,
        'petsAllowed': petsAllowed,
        'smokingAllowed': smokingAllowed,
        'alcoholAllowed': alcoholAllowed,
        'outsideFoodAllowed': outsideFoodAllowed,
        'photographyAllowed': photographyAllowed,
        'loudMusicAllowed': loudMusicAllowed,
        'walkInsAllowed': walkInsAllowed,
        'sameDayBookingAllowed': sameDayBookingAllowed,
        'refundsAllowed': refundsAllowed,
        'rescheduleAllowed': rescheduleAllowed,
      };

  CustomerPermissions copyWith({
    bool? adultsOnly,
    bool? childrenAllowed,
    bool? petsAllowed,
    bool? smokingAllowed,
    bool? alcoholAllowed,
    bool? outsideFoodAllowed,
    bool? photographyAllowed,
    bool? videoRecordingAllowed,
    bool? loudMusicAllowed,
    bool? walkInsAllowed,
    bool? sameDayBookingAllowed,
    bool? refundsAllowed,
    bool? rescheduleAllowed,
  }) {
    return CustomerPermissions(
      adultsOnly: adultsOnly ?? this.adultsOnly,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      alcoholAllowed: alcoholAllowed ?? this.alcoholAllowed,
      outsideFoodAllowed: outsideFoodAllowed ?? this.outsideFoodAllowed,
      photographyAllowed: photographyAllowed ?? this.photographyAllowed,
      loudMusicAllowed: loudMusicAllowed ?? this.loudMusicAllowed,
      walkInsAllowed: walkInsAllowed ?? this.walkInsAllowed,
      sameDayBookingAllowed:
          sameDayBookingAllowed ?? this.sameDayBookingAllowed,
      refundsAllowed: refundsAllowed ?? this.refundsAllowed,
      rescheduleAllowed: rescheduleAllowed ?? this.rescheduleAllowed,
    );
  }
}

class ServicePolicies extends BaseListingPolicies {
  const ServicePolicies({
    super.permissions = const CustomerPermissions(),
    super.cancellationPolicy = 'flexible',
    super.additionalPolicies = const {},
  });

  factory ServicePolicies.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return ServicePolicies(
      cancellationPolicy: data['cancellationPolicy'] ?? 'flexible',
      additionalPolicies:
          Map<String, dynamic>.from(data['additionalPolicies'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
    };
  }
}

class EventPolicies extends BaseListingPolicies {
  const EventPolicies({
    super.permissions = const CustomerPermissions(),
    super.cancellationPolicy = 'flexible',
    super.additionalPolicies = const {},
  });

  factory EventPolicies.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return EventPolicies(
      cancellationPolicy: data['cancellationPolicy'] ?? 'flexible',
      additionalPolicies:
          Map<String, dynamic>.from(data['additionalPolicies'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
    };
  }
}

class PlacePolicies extends BaseListingPolicies {
  const PlacePolicies({
    super.permissions = const CustomerPermissions(),
    super.cancellationPolicy = 'flexible',
    super.additionalPolicies = const {},
  });

  factory PlacePolicies.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return PlacePolicies(
      permissions: CustomerPermissions.fromMap(data['permissions']),
      cancellationPolicy: data['cancellationPolicy'] ?? 'flexible',
      additionalPolicies:
          Map<String, dynamic>.from(data['additionalPolicies'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
    };
  }
}

class HotelPolicies extends BaseListingPolicies {
  final String checkInTime;
  final String checkOutTime;

  const HotelPolicies({
    this.checkInTime = '15:00',
    this.checkOutTime = '11:00',
    super.permissions = const CustomerPermissions(),
    super.cancellationPolicy = 'flexible',
    super.additionalPolicies = const {},
  });

  factory HotelPolicies.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return HotelPolicies(
      checkInTime: data['checkInTime'] ?? '15:00',
      checkOutTime: data['checkOutTime'] ?? '11:00',
      permissions: CustomerPermissions.fromMap(data['permissions']),
      cancellationPolicy: data['cancellationPolicy'] ?? 'flexible',
      additionalPolicies:
          Map<String, dynamic>.from(data['additionalPolicies'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
    };
  }
}

class CustomerAccessPolicy {
  final bool requiresLogin;
  final bool requiresEmailVerification;
  final bool requiresPhoneVerification;
  final bool requiresIdentityVerification;
  final bool requiresProfileCompletion;
  final bool requiresMembership;
  final bool requiresApproval;
  final bool requiresWaiverAcceptance;

  final bool allowsGuests;
  final bool allowsGroupBooking;
  final bool allowsRepeatBooking;

  final bool adultsOnly;
  final int? minimumAge;
  final int? maximumTicketsPerCustomer;

  const CustomerAccessPolicy({
    this.requiresLogin = true,
    this.requiresEmailVerification = false,
    this.requiresPhoneVerification = false,
    this.requiresIdentityVerification = false,
    this.requiresProfileCompletion = false,
    this.requiresMembership = false,
    this.requiresApproval = false,
    this.requiresWaiverAcceptance = false,
    this.allowsGuests = false,
    this.allowsGroupBooking = false,
    this.allowsRepeatBooking = true,
    this.adultsOnly = false,
    this.minimumAge,
    this.maximumTicketsPerCustomer,
  });

  factory CustomerAccessPolicy.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return CustomerAccessPolicy(
      requiresLogin: data['requiresLogin'] ?? true,
      requiresEmailVerification: data['requiresEmailVerification'] ?? false,
      requiresPhoneVerification: data['requiresPhoneVerification'] ?? false,
      requiresIdentityVerification:
          data['requiresIdentityVerification'] ?? false,
      requiresProfileCompletion: data['requiresProfileCompletion'] ?? false,
      requiresMembership: data['requiresMembership'] ?? false,
      requiresApproval: data['requiresApproval'] ?? false,
      requiresWaiverAcceptance: data['requiresWaiverAcceptance'] ?? false,
      allowsGuests: data['allowsGuests'] ?? false,
      allowsGroupBooking: data['allowsGroupBooking'] ?? false,
      allowsRepeatBooking: data['allowsRepeatBooking'] ?? true,
      adultsOnly: data['adultsOnly'] ?? false,
      minimumAge: data['minimumAge'],
      maximumTicketsPerCustomer: data['maximumTicketsPerCustomer'],
    );
  }

  Map<String, dynamic> toMap() => {
        'requiresLogin': requiresLogin,
        'requiresEmailVerification': requiresEmailVerification,
        'requiresPhoneVerification': requiresPhoneVerification,
        'requiresIdentityVerification': requiresIdentityVerification,
        'requiresProfileCompletion': requiresProfileCompletion,
        'requiresMembership': requiresMembership,
        'requiresApproval': requiresApproval,
        'requiresWaiverAcceptance': requiresWaiverAcceptance,
        'allowsGuests': allowsGuests,
        'allowsGroupBooking': allowsGroupBooking,
        'allowsRepeatBooking': allowsRepeatBooking,
        'adultsOnly': adultsOnly,
        'minimumAge': minimumAge,
        'maximumTicketsPerCustomer': maximumTicketsPerCustomer,
      };

  CustomerAccessPolicy copyWith({
    bool? requiresLogin,
    bool? requiresEmailVerification,
    bool? requiresPhoneVerification,
    bool? requiresIdentityVerification,
    bool? requiresProfileCompletion,
    bool? requiresMembership,
    bool? requiresApproval,
    bool? requiresWaiverAcceptance,
    bool? allowsGuests,
    bool? allowsGroupBooking,
    bool? allowsRepeatBooking,
    bool? adultsOnly,
    int? minimumAge,
    int? maximumTicketsPerCustomer,
  }) {
    return CustomerAccessPolicy(
      requiresLogin: requiresLogin ?? this.requiresLogin,
      requiresEmailVerification:
          requiresEmailVerification ?? this.requiresEmailVerification,
      requiresPhoneVerification:
          requiresPhoneVerification ?? this.requiresPhoneVerification,
      requiresIdentityVerification:
          requiresIdentityVerification ?? this.requiresIdentityVerification,
      requiresProfileCompletion:
          requiresProfileCompletion ?? this.requiresProfileCompletion,
      requiresMembership: requiresMembership ?? this.requiresMembership,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      requiresWaiverAcceptance:
          requiresWaiverAcceptance ?? this.requiresWaiverAcceptance,
      allowsGuests: allowsGuests ?? this.allowsGuests,
      allowsGroupBooking: allowsGroupBooking ?? this.allowsGroupBooking,
      allowsRepeatBooking: allowsRepeatBooking ?? this.allowsRepeatBooking,
      adultsOnly: adultsOnly ?? this.adultsOnly,
      minimumAge: minimumAge ?? this.minimumAge,
      maximumTicketsPerCustomer:
          maximumTicketsPerCustomer ?? this.maximumTicketsPerCustomer,
    );
  }
}

class ListingAccessPermissions {
  final bool canView;
  final bool canBook;
  final bool canMessage;
  final bool canCall;
  final bool canEmail;
  final bool canVisitWebsite;
  final bool canShare;
  final bool canSave;
  final bool canReview;
  final bool canRequestQuote;
  final bool canCancelBooking;
  final bool canRescheduleBooking;

  const ListingAccessPermissions({
    this.canView = true,
    this.canBook = false,
    this.canMessage = true,
    this.canCall = true,
    this.canEmail = true,
    this.canVisitWebsite = true,
    this.canShare = true,
    this.canSave = true,
    this.canReview = true,
    this.canRequestQuote = false,
    this.canCancelBooking = false,
    this.canRescheduleBooking = false,
  });

  factory ListingAccessPermissions.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return ListingAccessPermissions(
      canView: data['canView'] ?? true,
      canBook: data['canBook'] ?? false,
      canMessage: data['canMessage'] ?? true,
      canCall: data['canCall'] ?? true,
      canEmail: data['canEmail'] ?? true,
      canVisitWebsite: data['canVisitWebsite'] ?? true,
      canShare: data['canShare'] ?? true,
      canSave: data['canSave'] ?? true,
      canReview: data['canReview'] ?? true,
      canRequestQuote: data['canRequestQuote'] ?? false,
      canCancelBooking: data['canCancelBooking'] ?? false,
      canRescheduleBooking: data['canRescheduleBooking'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'canView': canView,
        'canBook': canBook,
        'canMessage': canMessage,
        'canCall': canCall,
        'canEmail': canEmail,
        'canVisitWebsite': canVisitWebsite,
        'canShare': canShare,
        'canSave': canSave,
        'canReview': canReview,
        'canRequestQuote': canRequestQuote,
        'canCancelBooking': canCancelBooking,
        'canRescheduleBooking': canRescheduleBooking,
      };

  ListingAccessPermissions copyWith({
    bool? canView,
    bool? canBook,
    bool? canMessage,
    bool? canCall,
    bool? canEmail,
    bool? canVisitWebsite,
    bool? canShare,
    bool? canSave,
    bool? canReview,
    bool? canRequestQuote,
    bool? canCancelBooking,
    bool? canRescheduleBooking,
  }) {
    return ListingAccessPermissions(
      canView: canView ?? this.canView,
      canBook: canBook ?? this.canBook,
      canMessage: canMessage ?? this.canMessage,
      canCall: canCall ?? this.canCall,
      canEmail: canEmail ?? this.canEmail,
      canVisitWebsite: canVisitWebsite ?? this.canVisitWebsite,
      canShare: canShare ?? this.canShare,
      canSave: canSave ?? this.canSave,
      canReview: canReview ?? this.canReview,
      canRequestQuote: canRequestQuote ?? this.canRequestQuote,
      canCancelBooking: canCancelBooking ?? this.canCancelBooking,
      canRescheduleBooking: canRescheduleBooking ?? this.canRescheduleBooking,
    );
  }
}
