import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const Distance distance = Distance();

  static List<T> filterByRadius<T>({
    required LatLng center,
    required List<T> items,
    required double radiusMeters,
    required LatLng Function(T) getLocation,
  }) {
    return items.where((item) {
      final meters = distance(center, getLocation(item));
      return meters <= radiusMeters;
    }).toList();
  }

  static bool isWithinBounds({
    required LatLng point,
    required LatLng northEast,
    required LatLng southWest,
  }) {
    return point.latitude <= northEast.latitude &&
        point.latitude >= southWest.latitude &&
        point.longitude <= northEast.longitude &&
        point.longitude >= southWest.longitude;
  }

  static String boundsKey(LatLng northEast, LatLng southWest) {
    return '${northEast.latitude.toStringAsFixed(3)}'
        ':${northEast.longitude.toStringAsFixed(3)}'
        ':${southWest.latitude.toStringAsFixed(3)}'
        ':${southWest.longitude.toStringAsFixed(3)}';
  }

  static double calculateDistance(LatLng point1, LatLng point2) {
    return distance(point1, point2);
  }
}
