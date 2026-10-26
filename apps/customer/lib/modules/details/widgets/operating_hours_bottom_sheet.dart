// lib/features/listing/widgets/operating_hours/operating_hours_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/opening_hour_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/operating_hours_helper.dart';

class OperatingHoursBottomSheet extends StatelessWidget {
  final OperationalHoursDTO dto;
  const OperatingHoursBottomSheet({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayWeekday = Weekday.values[now.weekday - 1];

    final hoursByWeekday = <Weekday, OpeningHourModel>{};
    for (final h in dto.openingHours) {
      if (h.weekday != null && h.date == null) {
        hoursByWeekday[h.weekday!] = h;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Opening Hours',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final weekday in Weekday.values)
              _buildWeekdayRow(
                context,
                weekday,
                hoursByWeekday[weekday],
                weekday == todayWeekday,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow(
    BuildContext context,
    Weekday weekday,
    OpeningHourModel? hours,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final label = weekdayLabel(weekday);

    String hoursText;
    Color? textColor;

    if (hours == null) {
      hoursText = '—';
      textColor = theme.colorScheme.onSurfaceVariant;
    } else if (hours.isClosed) {
      hoursText = 'Closed';
      textColor = theme.colorScheme.error;
    } else if (hours.is24Hours) {
      hoursText = 'Open 24 hours';
      textColor = const Color(0xFF2E7D32);
    } else if (hours.opensAt != null && hours.closesAt != null) {
      hoursText =
          '${formatTime(hours.opensAt!)} - ${formatTime(hours.closesAt!)}';
      textColor = theme.colorScheme.onSurface;
    } else {
      hoursText = '—';
      textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hoursText,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
