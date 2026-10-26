/// Operational hours model to represent both:
/// - Regular weekly hours (e.g. Monday 9–5)
/// - Specific date overrides (e.g. holidays)
class OperationalHoursDTO {
  final List<OpeningHourModel> openingHours;

  OperationalHoursDTO({required this.openingHours});

  Map<String, dynamic> toJson() {
    return {'openingHours': openingHours.map((oh) => oh.toJson()).toList()};
  }

  factory OperationalHoursDTO.fromJson(Map<String, dynamic> map) {
    return OperationalHoursDTO(
      openingHours: (map['openingHours'] as List<dynamic>? ?? [])
          .map((ohMap) => OpeningHourModel.fromJson(ohMap))
          .toList(),
    );
  }

  /// Optional: sorted view for consistency
  List<OpeningHourModel> get sortedHours => [...openingHours]
    ..sort((a, b) {
      if (a.date != null && b.date != null) {
        return a.date!.compareTo(b.date!);
      }
      if (a.weekday != null && b.weekday != null) {
        return a.weekday!.index.compareTo(b.weekday!.index);
      }
      return 0;
    });
}

class OpeningHourModel {
  /// Weekly recurring day (e.g. Monday)
  final Weekday? weekday;

  /// Specific calendar override (e.g. holiday)
  final DateTime? date;

  /// Only time component is meaningful (date portion ignored for weekly entries)
  final DateTime? opensAt;

  /// Only time component is meaningful (date portion ignored for weekly entries)
  final DateTime? closesAt;

  /// Open all day
  final bool is24Hours;

  /// Closed all day
  final bool isClosed;

  const OpeningHourModel({
    this.weekday,
    this.date,
    this.opensAt,
    this.closesAt,
    this.is24Hours = false,
    this.isClosed = false,
  }) : assert(
         weekday != null || date != null,
         'Either weekday or date must be provided.',
       ),
       assert(!(is24Hours && isClosed), 'Cannot be both 24 hours and closed.'),
       assert(
         isClosed || is24Hours || (opensAt != null && closesAt != null),
         'Must provide opensAt/closesAt unless closed or 24 hours.',
       ),
       assert(
         !(is24Hours && (opensAt != null || closesAt != null)),
         '24-hour entries should not define opensAt/closesAt.',
       );

  OpeningHourModel copyWith({
    Weekday? weekday,
    DateTime? date,
    DateTime? opensAt,
    DateTime? closesAt,
    bool? is24Hours,
    bool? isClosed,
  }) {
    return OpeningHourModel(
      weekday: weekday ?? this.weekday,
      date: date ?? this.date,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      is24Hours: is24Hours ?? this.is24Hours,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  /// JSON serialization (no null fields written)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'is24Hours': is24Hours, 'isClosed': isClosed};

    if (weekday != null) map['weekday'] = weekday!.name;
    if (date != null) map['date'] = date!.toIso8601String();
    if (opensAt != null) map['opensAt'] = opensAt!.toIso8601String();
    if (closesAt != null) map['closesAt'] = closesAt!.toIso8601String();

    return map;
  }

  factory OpeningHourModel.fromJson(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return OpeningHourModel(
      weekday: _parseWeekday(map['weekday']),
      date: parseDateTime(map['date']),
      opensAt: parseDateTime(map['opensAt']),
      closesAt: parseDateTime(map['closesAt']),
      is24Hours: map['is24Hours'] ?? false,
      isClosed: map['isClosed'] ?? false,
    );
  }

  /// Local map serialization
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'is24Hours': is24Hours, 'isClosed': isClosed};

    if (weekday != null) map['weekday'] = weekday!.name;
    if (date != null) map['date'] = date!.millisecondsSinceEpoch;
    if (opensAt != null) {
      map['opensAt'] = opensAt!.millisecondsSinceEpoch;
    }
    if (closesAt != null) {
      map['closesAt'] = closesAt!.millisecondsSinceEpoch;
    }

    return map;
  }

  factory OpeningHourModel.fromMap(Map<String, dynamic> map) {
    return OpeningHourModel(
      weekday: _parseWeekday(map['weekday']),
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : null,
      opensAt: map['opensAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['opensAt'])
          : null,
      closesAt: map['closesAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['closesAt'])
          : null,
      is24Hours: map['is24Hours'] ?? false,
      isClosed: map['isClosed'] ?? false,
    );
  }

  /// Helpers

  /// True if this is a date-specific override
  bool get isOverride => date != null;

  /// Check if this entry applies to a given date
  bool appliesToDate(DateTime target) {
    if (date != null) {
      return date!.year == target.year &&
          date!.month == target.month &&
          date!.day == target.day;
    }

    if (weekday != null) {
      return weekday!.index == target.weekday - 1;
    }

    return false;
  }

  /// Safe enum parsing
  static Weekday? _parseWeekday(dynamic value) {
    if (value == null) return null;

    try {
      return Weekday.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

/// ui models
class OperationalHoursUIModel {
  final Map<Weekday, DayHoursUIModel> weeklyHours;
  final List<SpecialDayHoursUIModel> specialHours;

  OperationalHoursUIModel({
    required this.weeklyHours,
    required this.specialHours,
  });

  factory OperationalHoursUIModel.fromDTO(OperationalHoursDTO dto) {
    final weekly = <Weekday, DayHoursUIModel>{};
    final specials = <SpecialDayHoursUIModel>[];

    for (final entry in dto.openingHours) {
      if (entry.isOverride) {
        specials.add(SpecialDayHoursUIModel.fromModel(entry));
      } else if (entry.weekday != null) {
        weekly[entry.weekday!] = DayHoursUIModel.fromModel(entry);
      }
    }

    return OperationalHoursUIModel(
      weeklyHours: weekly,
      specialHours: specials..sort((a, b) => a.date.compareTo(b.date)),
    );
  }
}

class DayHoursUIModel {
  final Weekday weekday;
  final String label; // e.g. "Monday"
  final String displayText; // e.g. "9:00 AM - 5:00 PM"
  final bool isClosed;
  final bool is24Hours;

  DayHoursUIModel({
    required this.weekday,
    required this.label,
    required this.displayText,
    required this.isClosed,
    required this.is24Hours,
  });

  factory DayHoursUIModel.fromModel(OpeningHourModel model) {
    return DayHoursUIModel(
      weekday: model.weekday!,
      label: _formatWeekday(model.weekday!),
      displayText: _buildDisplayText(model),
      isClosed: model.isClosed,
      is24Hours: model.is24Hours,
    );
  }
}

class SpecialDayHoursUIModel {
  final DateTime date;
  final String label; // e.g. "Dec 25, 2025"
  final String displayText;
  final bool isClosed;
  final bool is24Hours;

  SpecialDayHoursUIModel({
    required this.date,
    required this.label,
    required this.displayText,
    required this.isClosed,
    required this.is24Hours,
  });

  factory SpecialDayHoursUIModel.fromModel(OpeningHourModel model) {
    return SpecialDayHoursUIModel(
      date: model.date!,
      label: _formatDate(model.date!),
      displayText: _buildDisplayText(model),
      isClosed: model.isClosed,
      is24Hours: model.is24Hours,
    );
  }
}

/// helper functions for formatting display text (could be moved to a separate utils file)
String _buildDisplayText(OpeningHourModel model) {
  if (model.isClosed) return 'Closed';
  if (model.is24Hours) return 'Open 24 hours';

  final open = _formatTime(model.opensAt!);
  final close = _formatTime(model.closesAt!);

  return '$open - $close';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;

  final period = hour >= 12 ? 'PM' : 'AM';
  final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
  final formattedMinute = minute.toString().padLeft(2, '0');

  return '$formattedHour:$formattedMinute $period';
}

String _formatWeekday(Weekday weekday) {
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

String _formatDate(DateTime date) {
  return '${_monthName(date.month)} ${date.day}, ${date.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

OperationalHoursDTO create24HourOperationalHours() {
  final weekdays = Weekday.values;
  final openingHours = weekdays
      .map(
        (weekday) => OpeningHourModel(
          weekday: weekday,
          is24Hours: true,
          isClosed: false,
        ),
      )
      .toList();

  return OperationalHoursDTO(openingHours: openingHours);
}

OperationalHoursDTO createStandardOperationalHours({
  required String openTime,
  required String closeTime,
  List<Weekday>? closedDays,
}) {
  final weekdays = Weekday.values;
  final closedDaysSet = Set<Weekday>.from(closedDays ?? []);

  final openingHours = weekdays.map((weekday) {
    if (closedDaysSet.contains(weekday)) {
      return OpeningHourModel(
        weekday: weekday,
        is24Hours: false,
        isClosed: true,
      );
    }

    final now = DateTime.now();
    final openDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(openTime.split(':')[0]),
      int.parse(openTime.split(':')[1]),
    );
    final closeDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(closeTime.split(':')[0]),
      int.parse(closeTime.split(':')[1]),
    );

    return OpeningHourModel(
      weekday: weekday,
      opensAt: openDateTime,
      closesAt: closeDateTime,
      is24Hours: false,
      isClosed: false,
    );
  }).toList();

  return OperationalHoursDTO(openingHours: openingHours);
}
