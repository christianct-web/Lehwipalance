// lib/features/listing/widgets/sections/listing_collaborators_section.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/common/listing_profile_placeholder.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/listing_detail_row.dart';

class ListingCollaboratorsSection extends StatelessWidget {
  const ListingCollaboratorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const collaborators = [
      {
        'name': 'Hardwell',
        'role': "Dj's",
        'image': 'https://i.pravatar.cc/150?u=1',
      },
      {
        'name': 'Alison Wonderland',
        'role': 'Remix',
        'image': 'https://i.pravatar.cc/150?u=2',
      },
      {
        'name': 'DJ Gina',
        'role': 'Mixer',
        'image': 'https://i.pravatar.cc/150?u=3',
      },
    ];
    if (collaborators.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
          child: Text(
            "Collaborators",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            scrollDirection: Axis.horizontal,
            itemCount: collaborators.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = collaborators[index];
              return _CollaboratorItem(
                image: item['image']!,
                role: item['role']!,
                name: item['name']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CollaboratorItem extends StatelessWidget {
  final String image;
  final String role;
  final String name;
  const _CollaboratorItem({
    required this.image,
    required this.role,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: buildNetworkImage(
                  image,
                  fallback: const ListingProfilePlaceholder(),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: -7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Text(
                  role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
