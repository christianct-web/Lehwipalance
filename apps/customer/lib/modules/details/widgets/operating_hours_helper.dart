// lib/features/listing/helpers/operating_hours_helper.dart
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/opening_hour_model.dart';

String formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

String formatDate(DateTime date) =>
    DateFormat('MMM d, y').format(date.toLocal());

String formatTime(DateTime dateTime) => DateFormat('h:mm a').format(dateTime);

String formatDateTime(DateTime dateTime) =>
    '${formatDate(dateTime)} • ${formatTime(dateTime)}';

String formatTimeOnly(DateTime dateTime) =>
    DateFormat('h:mm a').format(dateTime);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String? formatOperatingHours(OpeningHourModel hours) {
  if (hours.isClosed) return 'Closed today';
  if (hours.is24Hours) return 'Open 24 hours';
  if (hours.opensAt == null || hours.closesAt == null) return null;
  return '${formatTime(hours.opensAt!)} - ${formatTime(hours.closesAt!)}';
}

OpeningHourModel? getTodayHours(List<OpeningHourModel> hours, DateTime now) {
  for (final hour in hours) {
    if (hour.date != null &&
        hour.date!.year == now.year &&
        hour.date!.month == now.month &&
        hour.date!.day == now.day) {
      return hour;
    }
  }

  final weekday = Weekday.values[now.weekday - 1];

  for (final hour in hours) {
    if (hour.weekday == weekday && hour.date == null) {
      return hour;
    }
  }

  return null;
}

bool isCurrentlyOpen(OpeningHourModel hours, DateTime now) {
  if (hours.isClosed) return false;
  if (hours.is24Hours) return true;
  if (hours.opensAt == null || hours.closesAt == null) return false;

  final openMinutes = hours.opensAt!.hour * 60 + hours.opensAt!.minute;
  final closeMinutes = hours.closesAt!.hour * 60 + hours.closesAt!.minute;
  final currentMinutes = now.hour * 60 + now.minute;

  if (closeMinutes < openMinutes) {
    return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
  }

  return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
}

bool isClosingSoon(OpeningHourModel hours, DateTime now) {
  if (hours.isClosed || hours.is24Hours) return false;
  if (hours.opensAt == null || hours.closesAt == null) return false;

  const closingSoonMinutes = 60;
  final openMinutes = hours.opensAt!.hour * 60 + hours.opensAt!.minute;
  final closeMinutes = hours.closesAt!.hour * 60 + hours.closesAt!.minute;
  final currentMinutes = now.hour * 60 + now.minute;

  if (!isCurrentlyOpen(hours, now)) return false;

  if (closeMinutes >= openMinutes) {
    final minutesUntilClose = closeMinutes - currentMinutes;
    return minutesUntilClose > 0 && minutesUntilClose <= closingSoonMinutes;
  }

  final minutesUntilClose = currentMinutes >= openMinutes
      ? (24 * 60 - currentMinutes) + closeMinutes
      : closeMinutes - currentMinutes;

  return minutesUntilClose > 0 && minutesUntilClose <= closingSoonMinutes;
}

String weekdayLabel(Weekday weekday) {
  switch (weekday) {
    case Weekday.monday:
      return 'Monday';
    case Weekday.tuesday:
      return 'Tuesday';
    case Weekday.wednesday:
      return 'Wednesday';
    case Weekday.thursday:
      return 'Thursday';
    case Weekday.friday:
      return 'Friday';
    case Weekday.saturday:
      return 'Saturday';
    case Weekday.sunday:
      return 'Sunday';
  }
}
