// lib/features/listing/widgets/sections/listing_description_section.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

class ListingDescriptionSection extends StatelessWidget {
  final MerchantListingDTO listing;
  const ListingDescriptionSection({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = listing.description?.trim().isNotEmpty == true
        ? listing.description!
        : LanguageConstants.noDescriptionAvailable;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Icon(
              Icons.info_outline_rounded,
              size: 30,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
