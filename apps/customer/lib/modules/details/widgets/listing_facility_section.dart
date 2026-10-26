// lib/features/listing/widgets/sections/listing_facility_section.dart
import 'package:flutter/material.dart';

class ListingFacilitySection extends StatelessWidget {
  const ListingFacilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    const facilities = [
      {'icon': Icons.restaurant, 'label': 'Food Stall'},
      {'icon': Icons.directions_car, 'label': 'Car parking'},
    ];
    if (facilities.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
          child: Text(
            'Facility',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: facilities.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
