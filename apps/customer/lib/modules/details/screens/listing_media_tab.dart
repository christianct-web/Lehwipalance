// lib/features/listing/widgets/tabs/listing_media_tab.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/common/listing_empty_tab_message.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

class ListingMediaTab extends StatelessWidget {
  final MerchantDetailProvider provider;
  final PageController mediaPageController;
  const ListingMediaTab({
    super.key,
    required this.provider,
    required this.mediaPageController,
  });

  @override
  Widget build(BuildContext context) {
    final mediaItems = provider.mediaItems;
    final colorScheme = context.colors;

    if (mediaItems.isEmpty) {
      return const ListingEmptyTabMessage(
        icon: Icons.photo_library_outlined,
        message: LanguageConstants.noMediaAvailable,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mediaItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppConstants.paddingS,
          mainAxisSpacing: AppConstants.paddingS,
        ),
        itemBuilder: (context, index) {
          final item = mediaItems[index];
          return GestureDetector(
            onTap: () {
              mediaPageController.jumpToPage(index);
              provider.setSelectedTab(ListingDetailTab.info);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  if (item.type == MediaType.video)
                    ColoredBox(
                      color: colorScheme.scrim.withValues(alpha: 0.2),
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: colorScheme.scrim.withValues(
                            alpha: 0.55,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
