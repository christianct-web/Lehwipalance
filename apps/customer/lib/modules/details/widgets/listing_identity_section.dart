// lib/features/listing/widgets/sections/listing_identity_section.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_media_header.dart';

class ListingIdentitySection extends StatelessWidget {
  final MerchantDetailProvider provider;
  final MerchantListingDTO listing;

  /// Must match the radius used on the rounded body container in the screen.
  static const double topRadius = 28;

  const ListingIdentitySection({
    super.key,
    required this.provider,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Transform.translate(
      // Pull the rounded surface up so it overlaps the bottom of the header.
      offset: const Offset(0, -topRadius),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(topRadius),
          ),
        ),
        // Makes the rounded corners actually clip child content.
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            // Enough top padding for the avatar overhang + breathing room.
            ListingMediaHeader.avatarOverhang + 20,
            22,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (provider.organization != null)
                    Flexible(
                      child: Text(
                        provider.organization!.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
