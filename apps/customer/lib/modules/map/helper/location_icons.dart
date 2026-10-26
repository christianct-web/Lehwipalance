// Location icon mapping
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

class LocationIcons {
  static IconData getLocationIcon(LocationModel location) {
    final name = location.name.toLowerCase();

    if (name.contains('park') || name.contains('garden')) {
      return Icons.park;
    } else if (name.contains('museum') || name.contains('gallery')) {
      return Icons.museum;
    } else if (name.contains('theater') || name.contains('cinema')) {
      return Icons.theater_comedy;
    } else if (name.contains('center') || name.contains('conference')) {
      return Icons.business_center;
    } else if (name.contains('stadium') || name.contains('arena')) {
      return Icons.sports_baseball;
    } else if (name.contains('hotel') || name.contains('resort')) {
      return Icons.hotel;
    } else if (name.contains('restaurant') || name.contains('cafe')) {
      return Icons.restaurant;
    } else if (name.contains('hospital') || name.contains('clinic')) {
      return Icons.local_hospital;
    } else if (name.contains('school') || name.contains('university')) {
      return Icons.school;
    } else if (name.contains('mall') || name.contains('market')) {
      return Icons.shopping_cart;
    }

    return Icons.location_on;
  }
}
