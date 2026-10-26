import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class OrganizationSection extends StatelessWidget {
  final String title;
  final List<OrganisationDTO> organizations;
  final VoidCallback? onViewAll;
  final int maxItems;
  final bool showViewAll;
  final double cardWidth;
  final double cardHeight;

  const OrganizationSection({
    super.key,
    required this.title,
    required this.organizations,
    this.onViewAll,
    this.maxItems = 5,
    this.showViewAll = true,
    this.cardWidth = 180,
    this.cardHeight = 190,
  });

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) return const SizedBox.shrink();
    final displayItems = organizations.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showViewAll && onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(LanguageConstants.viewAll),
                ),
            ],
          ),
        if (title.isNotEmpty) const SizedBox(height: AppConstants.space4),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppConstants.space5),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                child: OrganizationCard(
                  organization: displayItems[index],
                  onTap: () => _navigateToOrganizationDetails(
                    context,
                    displayItems[index],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToOrganizationDetails(
    BuildContext context,
    OrganisationDTO organization,
  ) {
    debugPrint('Navigate to organization: ${organization.name}');
  }
}

class OrganizationCard extends StatelessWidget {
  final OrganisationDTO organization;
  final VoidCallback? onTap;
  final bool showRating;
  final bool showVerifiedBadge;

  const OrganizationCard({
    super.key,
    required this.organization,
    this.onTap,
    this.showRating = true,
    this.showVerifiedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCompactCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    final colorScheme = context.colors;
    return Card(
      elevation: AppConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildProfileIcon(colorScheme)),
              const SizedBox(height: AppConstants.space5),
              _buildNameOnly(),
              const SizedBox(height: AppConstants.space1),
              _buildFollowerCount(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: organization.isVerified
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: 2,
            ),
            image: organization.media.mainImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(organization.media.mainImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: organization.media.mainImageUrl.isEmpty
              ? Icon(
                  Icons.business_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        if (showVerifiedBadge && organization.isVerified)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.space1),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                size: AppConstants.iconS,
                color: colorScheme.primary,
              ),
            ),
          ),
        if (showRating)
          Positioned(bottom: -10, child: _buildRatingBadge(colorScheme)),
      ],
    );
  }

  Widget _buildNameOnly() {
    return Text(
      organization.name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
    );
  }

  Widget _buildRatingBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space3,
        vertical: AppConstants.space1,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(color: colorScheme.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 2),
          Text(
            organization.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          Text(
            ' (${organization.totalReviews})',
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCount(ColorScheme colorScheme) {
    if (organization.followerCount == 0) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          '${organization.followerCount} followers',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
