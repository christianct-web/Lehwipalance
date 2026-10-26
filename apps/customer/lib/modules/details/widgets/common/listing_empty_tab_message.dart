// lib/features/listing/widgets/common/listing_empty_tab_message.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class ListingEmptyTabMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const ListingEmptyTabMessage({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          children: [
            Icon(icon, size: 42, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
