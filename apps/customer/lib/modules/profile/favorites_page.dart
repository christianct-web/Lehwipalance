import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/new_widgets.dart';
import 'package:lehwipalancecustomerv1/modules/home/palance_widget.dart';

//import 'package:lehwipalancecustomerv1/organiser/widgets/palance_widget.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final authProvider = context.watch<AuthProvider>();

    final customer = authProvider.customerUser;
    final favorites = customerProvider.favoriteItems;
    final isLoading = customerProvider.isLoading;
    final hasFollowing = customerProvider.followedOrganizations.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer != null ? '${customer.name}\'s Favorites' : 'Favorites',
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: favorites.isEmpty && !hasFollowing
                  ? _EmptyFavorites(customer: customer)
                  : _FavoritesContent(
                      favorites: favorites,
                      customerProvider: customerProvider,
                      hasFollowing: hasFollowing,
                    ),
            ),
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  final List<PalanceItem> favorites;
  final CustomerProvider customerProvider;
  final bool hasFollowing;

  const _FavoritesContent({
    required this.favorites,
    required this.customerProvider,
    required this.hasFollowing,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-group favorites by type for the favorites section
    final groupedFavorites = _groupFavoritesByType();

    return CustomScrollView(
      slivers: [
        // Favorites List by Category
        if (groupedFavorites.isNotEmpty)
          ...groupedFavorites.entries.map((entry) {
            return SliverToBoxAdapter(
              child: _FavoriteSection(
                type: entry.key,
                items: entry.value,
                customerProvider: customerProvider,
              ),
            );
          })
        else
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring and save items you love',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to explore page
                      context.push('/home/explore');
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Now'),
                  ),
                ],
              ),
            ),
          ),
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Following Section (if user follows any organizations)
        if (hasFollowing)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: FollowingSection(customerProvider: customerProvider),
            ),
          ),
      ],
    );
  }

  Map<ListingType, List<PalanceItem>> _groupFavoritesByType() {
    final map = <ListingType, List<PalanceItem>>{};

    for (final item in favorites) {
      map.putIfAbsent(item.type, () => []).add(item);
    }

    // Sort items within each category
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.title.compareTo(b.title));
    }

    return map;
  }
}

// Update the existing _EmptyFavorites widget to be more comprehensive
class _EmptyFavorites extends StatelessWidget {
  final dynamic customer;

  const _EmptyFavorites({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            customer != null
                ? '${customer.name}, no favorites yet'
                : 'No favorites yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse and save items you love',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/home/explore');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }
}

// Updated _FavoriteSection with better styling
class _FavoriteSection extends StatelessWidget {
  final ListingType type;
  final List<PalanceItem> items;
  final CustomerProvider customerProvider;

  const _FavoriteSection({
    required this.type,
    required this.items,
    required this.customerProvider,
  });

  @override
  Widget build(BuildContext context) {
    final validItems = items.toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: type.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${validItems.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: type.color,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to category page
                  context.push('/home/category/${type.name}');
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: type.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: validItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = validItems[index];
              final isFavorite = customerProvider.isFavorite(
                item.type,
                item.id,
              );

              return SizedBox(
                width: 160,
                child: PalanceGridCard(
                  item: item,
                  onTap: () {
                    context.push('/home/listing/${item.id}');
                  },
                  onFavoriteToggle: () async {
                    await customerProvider.toggleFavorite(item.type, item.id);
                  },
                  isFavorite: isFavorite,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class FollowingSection extends StatelessWidget {
  final CustomerProvider customerProvider;

  const FollowingSection({super.key, required this.customerProvider});

  @override
  Widget build(BuildContext context) {
    final organizationProvider = context.watch<OrganizationProvider>();
    final followedIds = customerProvider.followedOrganizations;

    if (followedIds.isEmpty) {
      return _buildEmptyState(context);
    }

    // Get the actual organization objects from the provider
    final followedOrganizations = organizationProvider.allOrganizations
        .where((org) => followedIds.contains(org.id))
        .toList();

    if (followedOrganizations.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, followedOrganizations.length),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: followedOrganizations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final org = followedOrganizations[index];
              return _OrganizationCard(
                organization: org,
                isFollowing: true,
                onToggleFollow: () async {
                  await customerProvider.toggleFollowOrganization(org.id);
                },
                onTap: () {
                  // Navigate to organization details page
                  context.push('/home/organization/${org.id}');
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Following',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // Navigate to all followed organizations
              context.push('/home/following');
            },
            child: const Text('View all'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No organizations followed yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Follow organizations to see their updates here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore page
                context.push('/home/explore');
              },
              icon: const Icon(Icons.explore, size: 18),
              label: const Text('Explore Organizations'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final OrganisationDTO organization;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback onTap;

  const _OrganizationCard({
    required this.organization,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Organization image/logo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  _buildImage(context),
                  // Verified badge
                  if (organization.isVerified)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Follow button overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildFollowButton(context),
                  ),
                ],
              ),
            ),
            // Organization info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (organization.shortBio != null)
                    Text(
                      organization.shortBio!,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        organization.averageRating.toStringAsFixed(1),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 2),
                      Text(
                        _formatFollowers(organization.followerCount),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final hasImage = organization.media.mainImageUrl.isNotEmpty;

    if (hasImage) {
      return CachedNetworkImage(
        imageUrl: organization.media.mainImageUrl,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 110,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    } else {
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.business, size: 40, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleFollow,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowing
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFollowing
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFollowing ? Icons.check_circle : Icons.add_circle_outline,
                size: 14,
                color: isFollowing ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
