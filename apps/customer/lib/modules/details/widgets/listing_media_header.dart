// lib/features/listing/widgets/media/listing_media_header.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/common/listing_header_button.dart';
import 'package:video_player/video_player.dart';

import 'listing_org_avatar.dart';

class ListingMediaHeader extends StatelessWidget {
  final MerchantDetailProvider provider;
  final PageController pageController;
  final VideoPlayerController? videoController;
  final VoidCallback onClose;
  final void Function(int) onPageChanged;
  final VoidCallback onToggleVideoPlayback;
  final void Function() onInitializeVideo;

  /// Height of the media area, INCLUDING the status bar inset so the media
  /// fills all the way to the top of the screen.
  static const double _mediaHeight = 300;

  /// How far the avatar sticks out below the header — the parent uses this
  /// to add matching top padding so content isn't hidden behind it.
  static const double avatarOverhang = 45;

  const ListingMediaHeader({
    super.key,
    required this.provider,
    required this.pageController,
    required this.videoController,
    required this.onClose,
    required this.onPageChanged,
    required this.onToggleVideoPlayback,
    required this.onInitializeVideo,
  });

  @override
  Widget build(BuildContext context) {
    final mediaItems = provider.mediaItems;
    final org = provider.organization;

    if (mediaItems.isEmpty) {
      return _buildPlaceholder(context, provider);
    }

    return SizedBox(
      height: _mediaHeight,
      child: Stack(
        // Allow the avatar to overflow downward.
        clipBehavior: Clip.none,
        children: [
          // -------- Full-bleed media, extends behind status bar --------
          Positioned.fill(
            child: PageView.builder(
              controller: pageController,
              itemCount: mediaItems.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final mediaItem = mediaItems[index];
                return GestureDetector(
                  onTap: () {
                    if (mediaItem.type == MediaType.video) {
                      provider.toggleVideoControls();
                      onInitializeVideo();
                    }
                  },
                  onDoubleTap: mediaItem.type == MediaType.video
                      ? onToggleVideoPlayback
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (mediaItem.type == MediaType.video)
                        _buildVideoContent(context)
                      else
                        _buildImageContent(context, mediaItem),
                      if (mediaItem.type == MediaType.video &&
                          provider.showVideoControls &&
                          videoController != null &&
                          videoController!.value.isInitialized)
                        _buildVideoControls(provider),
                    ],
                  ),
                );
              },
            ),
          ),

          // -------- Top controls, inset by safe area --------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ListingHeaderButton(icon: Icons.close, onTap: onClose),
                    Row(
                      children: [
                        ListingHeaderButton(
                          icon: Icons.share_rounded,
                          onTap: () => provider.shareListing(context),
                        ),
                        const SizedBox(width: 8),
                        ListingHeaderButton(
                          icon: provider.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          onTap: provider.toggleBookmark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------- Media counter --------
          if (mediaItems.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.currentMediaIndex + 1}/${mediaItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // -------- Org avatar, overhangs below the header --------
          Positioned(
            left: 20,
            bottom: -avatarOverhang,
            child: ListingOrgAvatar(provider: provider, org: org),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, MediaItem mediaItem) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3.0,
      child: CachedNetworkImage(
        imageUrl: mediaItem.url,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, _, _) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    if (videoController == null || !videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      ),
    );
  }

  Widget _buildVideoControls(MerchantDetailProvider provider) {
    final isPlaying = videoController?.value.isPlaying ?? false;
    return Positioned.fill(
      child: Center(
        child: GestureDetector(
          onTap: onToggleVideoPlayback,
          child: AnimatedOpacity(
            opacity: provider.showVideoControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    MerchantDetailProvider provider,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _mediaHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.image_outlined, size: 48)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ListingHeaderButton(icon: Icons.close, onTap: onClose),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: -avatarOverhang,
            child: ListingOrgAvatar(
              provider: provider,
              org: provider.organization,
            ),
          ),
        ],
      ),
    );
  }
}
