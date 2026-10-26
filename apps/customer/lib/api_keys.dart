import 'dart:io';

class ApiKeys {
  ApiKeys._();
  String get adUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';
  static const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const String baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  //
}
