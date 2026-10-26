// lib/features/listing/widgets/common/listing_profile_placeholder.dart
import 'package:flutter/material.dart';

class ListingProfilePlaceholder extends StatelessWidget {
  const ListingProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_outline_rounded,
        size: 32,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
