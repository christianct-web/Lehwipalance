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
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/modules/reels/media_feed_provider.dart';

import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

class MediaFeedScreen extends StatefulWidget {
  final String? organizationId;
  final String? listingId;
  final List<MediaFeedItem>? initialMedia;
  final bool showAppBar;

  const MediaFeedScreen({
    super.key,
    this.organizationId,
    this.listingId,
    this.initialMedia,
    this.showAppBar = false,
  });

  @override
  State<MediaFeedScreen> createState() => _MediaFeedScreenState();
}

class _MediaFeedScreenState extends State<MediaFeedScreen>
    with SingleTickerProviderStateMixin {
  List<MediaFeedItem> _mediaItems = [];
  bool _isLoading = true;
  String? _error;

  // Page controller for vertical scrolling
  late PageController _pageController;
  int _currentIndex = 0;

  // Video controllers for each media item
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _isVideoPlaying = {};

  // Auto-scroll timer
  Timer? _autoScrollTimer;
  bool _isAutoScrollEnabled = true;
  Timer? _autoResumeTimer;
  bool _isUserInteracting = false;

  // Interaction states
  final Map<String, bool> _isLiked = {};
  final Map<String, bool> _isFollowing = {};
  final Map<String, int> _likeCounts = {};

  late MediaFeedProvider _provider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Use shared provider if available
    try {
      if (getIt.isRegistered<MediaFeedProvider>()) {
        _provider = getIt<MediaFeedProvider>();
      } else {
        _provider = MediaFeedProvider(apiService: getIt<ApiService>());
        getIt.registerLazySingleton<MediaFeedProvider>(() => _provider);
      }
    } catch (e) {
      _provider = MediaFeedProvider(apiService: getIt<ApiService>());
    }

    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load media based on parameters
      if (widget.initialMedia != null && widget.initialMedia!.isNotEmpty) {
        _mediaItems = widget.initialMedia!;
      } else if (widget.listingId != null) {
        // FIXED: Use the paginated method with await
        await _provider.loadMediaByListing(
          listingId: widget.listingId!,
          page: 1,
          pageSize: 50,
          refresh: true,
        );
        _mediaItems = _provider.listingItems;
      } else if (widget.organizationId != null) {
        // FIXED: Use the paginated method with await
        await _provider.loadMediaByOrganization(
          organizationId: widget.organizationId!,
          page: 1,
          pageSize: 50,
          refresh: true,
        );
        _mediaItems = _provider.organizationItems;
      } else {
        // Load all media with pagination
        await _provider.loadMediaFeed(page: 1, pageSize: 50);
        _mediaItems = _provider.mediaItems;
      }

      // Initialize interaction states
      for (final mediaItem in _mediaItems) {
        _isLiked[mediaItem.id] = mediaItem.isLikedByUser;
        _isFollowing[mediaItem.organizationId ?? ''] = mediaItem.isFollowing;
        _likeCounts[mediaItem.id] = mediaItem.likeCount;
      }

      // Only initialize video for visible item
      if (_mediaItems.isNotEmpty &&
          _mediaItems[0].mediaType == MediaType.video) {
        await _initializeVideoPlayer(_mediaItems[0].url);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Start auto-scroll after loading
        _startAutoScroll();

        // Play first video if it exists
        if (_mediaItems.isNotEmpty &&
            _mediaItems[0].mediaType == MediaType.video) {
          _playVideoAtIndex(0);
        }
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Helper method to extract media from listing (for backward compatibility)
  // ignore: unused_element
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
        ),
      );
    }

    return mediaItems;
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
          _isVideoPlaying[url] = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player for $url: $e');
      _videoControllers.remove(url);
    }
  }

  void _playVideoAtIndex(int index) {
    // Pause all videos first
    for (final entry in _videoControllers.entries) {
      if (entry.value.value.isPlaying) {
        entry.value.pause();
        _isVideoPlaying[entry.key] = false;
      }
    }

    // Play video at current index
    if (index < _mediaItems.length) {
      final mediaItem = _mediaItems[index];
      if (mediaItem.mediaType == MediaType.video) {
        final controller = _videoControllers[mediaItem.url];
        if (controller != null && controller.value.isInitialized) {
          controller.play();
          setState(() {
            _isVideoPlaying[mediaItem.url] = true;
          });
        }
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_mediaItems.isEmpty) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isAutoScrollEnabled || _isUserInteracting || _mediaItems.isEmpty) {
        return;
      }

      final nextIndex = _currentIndex + 1;
      if (nextIndex < _mediaItems.length) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Loop back to start
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
      if (_isAutoScrollEnabled) {
        _isUserInteracting = false;
      }
    });

    if (_isAutoScrollEnabled) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _handleUserInteraction() {
    if (_isAutoScrollEnabled) {
      setState(() {
        _isUserInteracting = true;
      });
      _autoScrollTimer?.cancel();

      // Resume auto-scroll after 10 seconds of inactivity
      _autoResumeTimer?.cancel();
      _autoResumeTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isAutoScrollEnabled) {
          setState(() {
            _isUserInteracting = false;
          });
          _startAutoScroll();
        }
      });
    }
  }

  Future<void> _handleLike(MediaFeedItem mediaItem) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) return;

    try {
      final newLikeState = !mediaItem.isLikedByUser;

      // Optimistic update
      setState(() {
        _isLiked[mediaItem.id] = newLikeState;
        _likeCounts[mediaItem.id] =
            (_likeCounts[mediaItem.id] ?? 0) + (newLikeState ? 1 : -1);
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
          _likeCounts[mediaItem.id] =
              (_likeCounts[mediaItem.id] ?? 0) + (newLikeState ? -1 : 1);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      } else {
        // Update with actual count from server
        setState(() {
          _likeCounts[mediaItem.id] = response.likeCount;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked[mediaItem.id] = !(_isLiked[mediaItem.id] ?? false);
        _likeCounts[mediaItem.id] =
            (_likeCounts[mediaItem.id] ?? 0) +
            ((_isLiked[mediaItem.id] ?? false) ? 1 : -1);
      });
      debugPrint('Error updating like: $e');
    }
  }

  Future<void> _handleFollow(MediaFeedItem mediaItem) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null || mediaItem.organizationId == null) return;

    try {
      final newFollowState = !mediaItem.isFollowing;

      // Optimistic update
      setState(() {
        _isFollowing[mediaItem.organizationId!] = newFollowState;
      });

      final response = await _provider.toggleFollow(
        organizationId: mediaItem.organizationId!,
        isFollowing: newFollowState,
        userId: userId,
      );

      if (!response.success) {
        // Revert on failure
        setState(() {
          _isFollowing[mediaItem.organizationId!] = !newFollowState;
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
        _isFollowing[mediaItem.organizationId!] =
            !(_isFollowing[mediaItem.organizationId!] ?? false);
      });
      debugPrint('Error updating follow: $e');
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

      debugPrint('Shared media: ${mediaItem.url}');
    } catch (e) {
      debugPrint('Error sharing media: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to share media')));
      }
    }
  }

  void _navigateToListing(MediaFeedItem mediaItem) {
    if (mediaItem.listingId == null) return;

    try {
      final GoRouter router = GoRouter.of(context);
      router.pushNamed(
        RouteNames.listingDetails,
        pathParameters: {'listingId': mediaItem.listingId!},
      );
      debugPrint('Navigated to listing: ${mediaItem.listingId}');
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        context.goNamed(RouteNames.media);
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _autoResumeTimer?.cancel();
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _mediaItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'No media available'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadMedia, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main PageView for vertical scrolling
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _playVideoAtIndex(index);
                // Initialize video for next item if needed
                final nextIndex = index + 1;
                if (nextIndex < _mediaItems.length &&
                    _mediaItems[nextIndex].mediaType == MediaType.video &&
                    !_videoControllers.containsKey(
                      _mediaItems[nextIndex].url,
                    )) {
                  _initializeVideoPlayer(_mediaItems[nextIndex].url);
                }
              });
              _handleUserInteraction();
            },
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              final mediaItem = _mediaItems[index];
              return _buildMediaItem(mediaItem, index);
            },
          ),

          // Auto-scroll indicator
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              children: [
                // Auto-scroll toggle button
                GestureDetector(
                  onTap: _toggleAutoScroll,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAutoScrollEnabled ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_mediaItems.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(MediaFeedItem mediaItem, int index) {
    final isVideo = mediaItem.mediaType == MediaType.video;
    final controller = _videoControllers[mediaItem.url];
    final isPlaying = _isVideoPlaying[mediaItem.url] ?? false;
    final isLiked = _isLiked[mediaItem.id] ?? mediaItem.isLikedByUser;
    final likeCount = _likeCounts[mediaItem.id] ?? mediaItem.likeCount;
    final isFollowing =
        _isFollowing[mediaItem.organizationId ?? ''] ?? mediaItem.isFollowing;
    final isInitialized = controller?.value.isInitialized ?? false;

    return GestureDetector(
      onDoubleTap: () {
        _handleLike(mediaItem);
        // TODO: Add animation feedback
      },
      onTap: () {
        if (isVideo && controller != null && controller.value.isInitialized) {
          setState(() {
            if (controller.value.isPlaying) {
              controller.pause();
              _isVideoPlaying[mediaItem.url] = false;
            } else {
              controller.play();
              _isVideoPlaying[mediaItem.url] = true;
            }
          });
        }
        _handleUserInteraction();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media content
          isVideo && controller != null && controller.value.isInitialized
              ? VideoPlayer(controller)
              : CachedNetworkImage(
                  imageUrl: mediaItem.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 64,
                      ),
                    ),
                  ),
                ),

          // Show loading spinner for video that's initializing
          if (isVideo && !isInitialized)
            Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Gradient overlay for text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Video play/pause indicator
          if (isVideo && !isPlaying && isInitialized)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Bottom info section
          Positioned(
            bottom: 20,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organization name with follow button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mediaItem.organizationName ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _handleFollow(mediaItem),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowing ? Colors.transparent : Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFollowing
                                ? Colors.white
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: isFollowing ? Colors.white : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mediaItem.title ?? 'No title',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // View listing button
                if (mediaItem.listingId != null)
                  GestureDetector(
                    onTap: () => _navigateToListing(mediaItem),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'View Listing',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right side action buttons (Instagram Reels style)
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                // Like button
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  label: likeCount > 0 ? '$likeCount' : '',
                  onTap: () => _handleLike(mediaItem),
                ),
                const SizedBox(height: 20),

                // Comment button
                _buildActionButton(
                  icon: Icons.comment,
                  color: Colors.white,
                  label: '${mediaItem.commentCount}',
                  onTap: () {
                    // Navigate to comments or show details
                    _handleUserInteraction();
                  },
                ),
                const SizedBox(height: 20),

                // Share button
                _buildActionButton(
                  icon: Icons.share,
                  color: Colors.white,
                  label: '',
                  onTap: () => _shareMedia(mediaItem),
                ),
                const SizedBox(height: 20),

                // More options
                _buildActionButton(
                  icon: Icons.more_horiz,
                  color: Colors.white,
                  label: '',
                  onTap: () => _showMediaOptions(mediaItem),
                ),
              ],
            ),
          ),

          // Auto-scroll progress bar
          if (_isAutoScrollEnabled)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _mediaItems.length,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
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
            ListTile(
              leading: Icon(
                _isAutoScrollEnabled ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              title: Text(
                _isAutoScrollEnabled
                    ? 'Pause Auto-Scroll'
                    : 'Resume Auto-Scroll',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleAutoScroll();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
