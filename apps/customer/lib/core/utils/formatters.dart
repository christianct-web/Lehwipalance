import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String formatEventDate({DateTime? startDate, DateTime? endDate}) {
  if (startDate == null) return 'Date TBD';

  final dateFormat = DateFormat('MMM dd, yyyy');
  final timeFormat = DateFormat('h:mm a');

  if (endDate == null || startDate.isAtSameMomentAs(endDate)) {
    return '${dateFormat.format(startDate)} at ${timeFormat.format(startDate)}';
  }

  if (startDate.day == endDate.day && startDate.month == endDate.month) {
    return '${dateFormat.format(startDate)} • ${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}';
  }

  return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
}

// Format price for display
String formatPrice(double? price) {
  if (price == null) return 'TBD';
  if (price <= 0.0) return 'Free';
  if (price == price.truncateToDouble()) {
    return '\$${price.toInt()}';
  }
  return '\$${price.toStringAsFixed(2)}';
}

void launchExternalUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
