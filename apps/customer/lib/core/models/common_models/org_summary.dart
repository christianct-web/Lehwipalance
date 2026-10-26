class OrganizationSummary {
  final String id;
  final String organizationId;
  final String name;
  final String description;
  final String imageUrl;

  final int followers;
  final String role;

  OrganizationSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.role,
    required this.organizationId,
    required this.followers,
  });

  // Changed toMap() to toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'role': role,
      'followers': followers,
    };
  }

  // Changed fromMap() to fromJson()
  factory OrganizationSummary.fromJson(Map<String, dynamic> map) {
    return OrganizationSummary(
      id: map['id'],
      organizationId: map['organizationId'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      role: map['role'],
      followers: map['followers'] ?? 0,
    );
  }

  // Keep original copyWith method
  OrganizationSummary copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? role,
    String? organizationId,
    int? followers,
  }) {
    return OrganizationSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      followers: followers ?? this.followers,
    );
  }
}

class MerchantSummary {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final String imageUrl;

  final int followers;
  final String role;

  MerchantSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.role,
    required this.merchantId,
    required this.followers,
  });

  // Changed toMap() to toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'role': role,
      'followers': followers,
    };
  }

  // Changed fromMap() to fromJson()
  factory MerchantSummary.fromJson(Map<String, dynamic> map) {
    return MerchantSummary(
      id: map['id'],
      merchantId: map['merchantId'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      role: map['role'],
      followers: map['followers'] ?? 0,
    );
  }

  // Keep original copyWith method
  MerchantSummary copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? role,
    String? merchantId,
    int? followers,
  }) {
    return MerchantSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      merchantId: merchantId ?? this.merchantId,
      followers: followers ?? this.followers,
    );
  }
}
