import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';

class ContactInfo {
  final SocialLinks socialLinks;
  final String email;
  final String? website;
  final String? phone;
  final String? qrCodeUrl;

  const ContactInfo({
    required this.socialLinks,
    required this.email,
    this.website,
    this.phone,
    this.qrCodeUrl,
  });

  // ==============================
  // 🔹 CopyWith
  // ==============================

  ContactInfo copyWith({
    SocialLinks? socialLinks,
    String? email,
    String? website,
    String? phone,
    String? qrCodeUrl,
  }) {
    return ContactInfo(
      socialLinks: socialLinks ?? this.socialLinks,
      email: email ?? this.email,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
    );
  }

  // ==============================
  // 🔹 Firestore Serialization
  // ==============================

  Map<String, dynamic> toJson() {
    return {
      'socialLinks': socialLinks.toJson(),
      'email': email,
      'website': website,
      'phone': phone,
      'qrCodeUrl': qrCodeUrl,
    };
  }

  // ==============================
  // 🔹 Firestore Deserialization
  // ==============================

  factory ContactInfo.fromJson(Map<String, dynamic>? map) {
    if (map == null) {
      return ContactInfo(socialLinks: SocialLinks(), email: '', qrCodeUrl: '');
    }

    return ContactInfo(
      socialLinks: SocialLinks.fromJson(map['socialLinks'] ?? {}),
      email: map['email'] ?? '',
      website: map['website'],
      phone: map['phone'],
      qrCodeUrl: map['qrCodeUrl'] ?? '',
    );
  }
}
