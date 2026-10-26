// lib/features/listing/widgets/operating_hours/operating_hours_display.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/opening_hour_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/operating_hours_bottom_sheet.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class OperatingHoursDisplay extends StatelessWidget {
  final String status;
  final String hours;
  final OperatingStatus statusType;
  final OperationalHoursDTO? operationalHours;

  const OperatingHoursDisplay({
    super.key,
    required this.status,
    required this.hours,
    required this.statusType,
    this.operationalHours,
  });

  Color _statusColor(BuildContext context) {
    switch (statusType) {
      case OperatingStatus.open:
        return const Color(0xFF2E7D32);
      case OperatingStatus.closingSoon:
        return const Color(0xFFEF6C00);
      case OperatingStatus.closed:
        return context.colors.error;
    }
  }

  IconData get _statusIcon {
    switch (statusType) {
      case OperatingStatus.open:
        return Icons.check_circle_outline_rounded;
      case OperatingStatus.closingSoon:
        return Icons.access_time_rounded;
      case OperatingStatus.closed:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context);
    final canExpand = operationalHours != null;

    return InkWell(
      onTap: canExpand
          ? () => _showOperatingHoursSheet(context, operationalHours!)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_statusIcon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (hours.isNotEmpty && hours != status)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        hours,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (canExpand)
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _showOperatingHoursSheet(BuildContext context, OperationalHoursDTO dto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => OperatingHoursBottomSheet(dto: dto),
    );
  }
}
