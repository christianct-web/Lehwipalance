import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/media_feed_model.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/router/customer_routes.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/modules/reels/media_feed_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

class MediaHighlightWidget extends StatefulWidget {
  final List<MerchantListingDTO> listings;
  final int maxItems;
  final String? title;
  final VoidCallback? onViewAll;

  const MediaHighlightWidget({
    super.key,
    required this.listings,
    this.maxItems = 6,
    this.title = 'Latest Media',
    this.onViewAll,
  });

  @override
  State<MediaHighlightWidget> createState() => _MediaHighlightWidgetState();
}

class _MediaHighlightWidgetState extends State<MediaHighlightWidget>
    with AutomaticKeepAliveClientMixin {
  List<MediaFeedItem> _mediaItems = [];
  final Map<String, bool> _isLiked = {};
  bool _isLoading = true;
  final Map<String, VideoPlayerController> _videoControllers = {};
  late MediaFeedProvider _provider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _provider = MediaFeedProvider(apiService: getIt<ApiService>());
    _loadMediaItems();
  }

  @override
  void didUpdateWidget(MediaHighlightWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listings != oldWidget.listings) {
      // Clean up old controllers
      for (final controller in _videoControllers.values) {
        controller.dispose();
      }
      _videoControllers.clear();
      _loadMediaItems();
    }
  }

  void _loadMediaItems() {
    setState(() => _isLoading = true);

    try {
      final items = <MediaFeedItem>[];

      // Extract media from all listings
      for (final listing in widget.listings) {
        final media = _extractMediaFromListing(listing);
        items.addAll(media);

        // Stop if we have enough items
        if (items.length >= widget.maxItems) break;
      }

      // If no media found, add fallback
      if (items.isEmpty && widget.listings.isNotEmpty) {
        items.addAll(_createFallbackMedia(widget.listings));
      }

      _mediaItems = items.take(widget.maxItems).toList();

      // Initialize like states from media items
      for (final item in _mediaItems) {
        _isLiked[item.id] = item.isLikedByUser;
      }

      // Initialize video controllers
      _initializeVideoControllers();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading media highlight: $e');
      setState(() => _isLoading = false);
    }
  }

  List<MediaFeedItem> _extractMediaFromListing(MerchantListingDTO listing) {
    final List<MediaFeedItem> mediaItems = [];
    final String orgName = listing.title;

    // Add videos
    if (listing.mediaUrls.videoUrls != null) {
      for (final videoUrl in listing.mediaUrls.videoUrls!) {
        mediaItems.add(
          MediaFeedItem(
            id: '${listing.id}_video_${videoUrl.hashCode}',
            url: videoUrl,
            mediaType: MediaType.video,
            title: listing.title,
            description: listing.description,
            listingId: listing.id,
            organizationId: listing.organizationId,
            organizationName: orgName,
            createdAt: listing.createdAt,
            likeCount: (videoUrl.hashCode.abs() % 100) + 1,
          ),
        );
      }
    }

    // Add images
    for (final imageUrl in listing.mediaUrls.imageUrls) {
      mediaItems.add(
        MediaFeedItem(
          id: '${listing.id}_image_${imageUrl.hashCode}',
          url: imageUrl,
          mediaType: MediaType.image,
          title: listing.title,
          description: listing.description,
          listingId: listing.id,
          organizationId: listing.organizationId,
          organizationName: orgName,
          createdAt: listing.createdAt,
          likeCount: (imageUrl.hashCode.abs() % 100) + 1,
        ),
      );
    }

    // Add main image if not already included
    if (listing.mediaUrls.mainImageUrl.isNotEmpty &&
        !mediaItems.any((item) => item.url == listing.mediaUrls.mainImageUrl)) {
      mediaItems.add(
        MediaFeedItem(
          id: '${listing.id}_main_${listing.mediaUrls.mainImageUrl.hashCode}',
          url: listing.mediaUrls.mainImageUrl,
          mediaType: MediaType.image,
          title: listing.title,
          description: listing.description,
          listingId: listing.id,
          organizationId: listing.organizationId,
          organizationName: orgName,
          createdAt: listing.createdAt,
          likeCount: (listing.mediaUrls.mainImageUrl.hashCode.abs() % 100) + 1,
        ),
      );
    }

    return mediaItems;
  }

  List<MediaFeedItem> _createFallbackMedia(List<MerchantListingDTO> listings) {
    final items = <MediaFeedItem>[];
    for (final listing in listings) {
      if (listing.mediaUrls.mainImageUrl.isNotEmpty) {
        items.add(
          MediaFeedItem(
            id: '${listing.id}_fallback_${listing.mediaUrls.mainImageUrl.hashCode}',
            url: listing.mediaUrls.mainImageUrl,
            mediaType: MediaType.image,
            title: listing.title,
            description: listing.description,
            listingId: listing.id,
            organizationId: listing.organizationId,
            organizationName: listing.title,
            createdAt: listing.createdAt,
          ),
        );
        if (items.length >= widget.maxItems) break;
      }
    }
    return items;
  }

  void _initializeVideoControllers() {
    for (final mediaItem in _mediaItems) {
      if (mediaItem.mediaType == MediaType.video) {
        _initializeVideoPlayer(mediaItem.url);
      }
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    if (_videoControllers.containsKey(url)) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.pause();

      if (mounted) {
        setState(() {
          _videoControllers[url] = controller;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player for $url: $e');
      _videoControllers.remove(url);
    }
  }

  Future<void> _handleLike(MediaFeedItem mediaItem) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) return;

    try {
      final newLikeState = !(_isLiked[mediaItem.id] ?? false);

      // Optimistic update
      setState(() {
        _isLiked[mediaItem.id] = newLikeState;
      });

      final response = await _provider.toggleLike(
        mediaId: mediaItem.id,
        isLiked: newLikeState,
        userId: userId,
      );

      if (!response.success) {
        // Revert on failure
        setState(() {
          _isLiked[mediaItem.id] = !newLikeState;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked[mediaItem.id] = !(_isLiked[mediaItem.id] ?? false);
      });
      debugPrint('Error updating like: $e');
    }
  }

  Future<void> _shareMedia(MediaFeedItem mediaItem) async {
    try {
      final message =
          '''
${mediaItem.title ?? 'Check this out'} from ${mediaItem.organizationName ?? 'Lehwi Palance'} ✨

${mediaItem.listingId != null ? '📍 View on Lehwi Palance: [Link to listing]' : ''}
#LehwiPalance #RealEstate
''';

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: mediaItem.title ?? 'Media from Lehwi Palance',
        ),
      );

      // Track share
      final userId = getIt<AuthProvider>().customerUser?.id;
      if (userId != null) {
        await _provider.trackShare(
          mediaId: mediaItem.id,
          userId: userId,
          platform: 'share_plus',
        );
      }
    } catch (e) {
      debugPrint('Error sharing media: $e');
    }
  }

  void _navigateToFullFeed() {
    debugPrint('[MediaHighlightWidget] Navigating to Media tab');

    // Try to use NavigationService first
    try {
      NavigationService().switchToMediaTab();
      debugPrint('[MediaHighlightWidget] NavigationService succeeded');
    } catch (e) {
      debugPrint('[MediaHighlightWidget] NavigationService failed: $e');
      // Fallback: Use context to navigate
      if (mounted) {
        context.goNamed(RouteNames.media);
      }
    }
  }

  void _navigateToListing(MediaFeedItem mediaItem) {
    if (mediaItem.listingId == null) return;
    // Navigate to listing detail
    try {
      context.pushNamed(
        RouteNames.listingDetails,
        pathParameters: {'listingId': mediaItem.listingId!},
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title ?? 'Latest Media',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.onViewAll != null ||
                  _mediaItems.length >= widget.maxItems)
                TextButton(
                  onPressed: widget.onViewAll ?? _navigateToFullFeed,
                  child: const Text('View All'),
                ),
            ],
          ),
        ),

        // Media Grid or Horizontal Scroll
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              final mediaItem = _mediaItems[index];
              return _buildMediaCard(mediaItem, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaFeedItem mediaItem, int index) {
    final isVideo = mediaItem.mediaType == MediaType.video;
    final controller = _videoControllers[mediaItem.url];
    final isLiked = _isLiked[mediaItem.id] ?? mediaItem.isLikedByUser;
    final isInitialized = controller?.value.isInitialized ?? false;

    return AspectRatio(
      aspectRatio: 1.6 / 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            debugPrint(
              '[MediaHighlightWidget] Media card tapped: ${mediaItem.title}',
            );
            _navigateToFullFeed();
          },
          onLongPress: () {
            _showMediaOptions(mediaItem);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media thumbnail
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Media content
                      isVideo &&
                              controller != null &&
                              controller.value.isInitialized
                          ? VideoPlayer(controller)
                          : CachedNetworkImage(
                              imageUrl: mediaItem.url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                            ),

                      // Show loading spinner for video that's initializing
                      if (isVideo && !isInitialized)
                        Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Video indicator overlay
                      if (isVideo)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),

                      // Video play icon
                      if (isVideo)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                      // Like count badge
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _handleLike(mediaItem),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${mediaItem.likeCount + (isLiked ? 1 : 0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Organization badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mediaItem.organizationName?.toUpperCase() ??
                                'MEDIA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info section
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mediaItem.organizationName ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mediaItem.title ?? 'No title',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaOptions(MediaFeedItem mediaItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareMedia(mediaItem);
              },
            ),
            if (mediaItem.listingId != null)
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text(
                  'View Listing',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToListing(mediaItem);
                },
              ),
            ListTile(
              leading: const Icon(Icons.bookmark_border, color: Colors.white),
              title: const Text(
                'Save to Collection',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                final userId = getIt<AuthProvider>().customerUser?.id;
                if (userId != null) {
                  _provider.saveMedia(mediaId: mediaItem.id, userId: userId);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
