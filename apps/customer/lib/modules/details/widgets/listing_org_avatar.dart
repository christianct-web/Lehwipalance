// lib/features/listing/widgets/media/listing_org_avatar.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/common/listing_profile_placeholder.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_detail_row.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

class ListingOrgAvatar extends StatelessWidget {
  final MerchantDetailProvider provider;
  final OrganisationDTO? org;
  const ListingOrgAvatar({
    super.key,
    required this.provider,
    required this.org,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: buildNetworkImage(
              org?.media.mainImageUrl,
              fallback: const ListingProfilePlaceholder(),
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: 3,
          child: GestureDetector(
            onTap: provider.toggleFollow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: provider.isFollowing
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.isFollowing
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 13,
                    color: provider.isFollowing
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    provider.isFollowing
                        ? LanguageConstants.following
                        : LanguageConstants.follow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: provider.isFollowing
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
