import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/media_feed_model.dart';
import 'package:lehwipalancecustomerv1/modules/reels/media_feed_provider.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:share_plus/share_plus.dart';

class ListingMediaGridScreen extends StatefulWidget {
  final String listingId;
  final String? listingTitle;

  const ListingMediaGridScreen({
    super.key,
    required this.listingId,
    this.listingTitle,
  });

  @override
  State<ListingMediaGridScreen> createState() => _ListingMediaGridScreenState();
}

class _ListingMediaGridScreenState extends State<ListingMediaGridScreen> {
  late MediaFeedProvider _provider;
  late ScrollController _scrollController;
  bool _isInitialized = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Use shared provider if available, otherwise create new one
    try {
      if (getIt.isRegistered<MediaFeedProvider>()) {
        _provider = getIt<MediaFeedProvider>();
        debugPrint('[ListingMediaGrid] Using registered MediaFeedProvider');
      } else {
        _provider = MediaFeedProvider(apiService: getIt<ApiService>());
        getIt.registerLazySingleton<MediaFeedProvider>(() => _provider);
        debugPrint(
          '[ListingMediaGrid] Created and registered new MediaFeedProvider',
        );
      }
    } catch (e) {
      _provider = MediaFeedProvider(apiService: getIt<ApiService>());
      debugPrint('[ListingMediaGrid] Created fallback MediaFeedProvider');
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _provider.loadMediaByListing(
        listingId: widget.listingId,
        page: 1,
        pageSize: 30,
        refresh: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('[ListingMediaGrid] Error loading media: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMoreMedia() async {
    if (_isRefreshing) return;
    if (!_provider.hasMoreListingItems) return;
    if (_provider.listingItems.isEmpty) return;
    if (_provider.isLoadingMore) return;

    try {
      await _provider.loadMoreListingMedia();
    } catch (e) {
      debugPrint('[ListingMediaGrid] Error loading more media: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMedia();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.listingTitle ?? 'Listing Media',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _loadMedia,
            ),
          ],
        ),
        body: Consumer<MediaFeedProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && !_isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.listingItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading media',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMedia,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.listingItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No media available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This listing has no media yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadMedia,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.75,
                ),
                itemCount:
                    provider.listingItems.length +
                    (provider.hasMoreListingItems ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.listingItems.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final item = provider.listingItems[index];
                  return MediaGridTile(
                    mediaItem: item,
                    onTap: () {
                      _navigateToMediaView(item, provider.listingItems);
                    },
                    onLike: () {
                      _handleLike(item);
                    },
                    onSave: () {
                      _handleSave(item);
                    },
                    onLongPress: () {
                      _showMediaOptions(item, provider.listingItems);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToMediaView(MediaFeedItem item, List<MediaFeedItem> allItems) {
    try {
      final router = GoRouter.of(context);
      router.pushNamed(
        RouteNames.media,
        extra: {
          'mediaItem': item,
          'mediaItems': allItems,
          'currentIndex': allItems.indexOf(item),
          'listingId': widget.listingId,
          'listingTitle': widget.listingTitle,
        },
      );
    } catch (e) {
      debugPrint('[ListingMediaGrid] Navigation error: $e');
      _showMediaDetailsDialog(item);
    }
  }

  void _showMediaDetailsDialog(MediaFeedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title ?? 'Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.mediaType == MediaType.image)
              CachedNetworkImage(
                imageUrl: item.url,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 200,
                  child: Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 16),
            Text('Likes: ${item.likeCount}'),
            Text('Comments: ${item.commentCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLike(MediaFeedItem item) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      await _provider.toggleLike(
        mediaId: item.id,
        isLiked: !item.isLikedByUser,
        userId: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like: $e')));
      }
    }
  }

  void _handleSave(MediaFeedItem item) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      if (item.isSavedByUser) {
        await _provider.unsaveMedia(mediaId: item.id, userId: userId);
      } else {
        await _provider.saveMedia(mediaId: item.id, userId: userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _showMediaOptions(MediaFeedItem item, List<MediaFeedItem> allItems) {
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
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                'View Details',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToMediaView(item, allItems);
              },
            ),
            ListTile(
              leading: Icon(
                item.isSavedByUser ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              title: Text(
                item.isSavedByUser ? 'Remove from Saved' : 'Save to Collection',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleSave(item);
              },
            ),
            if (item.listingId != null)
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.white),
                title: const Text(
                  'View Listing',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  try {
                    context.pushNamed(
                      RouteNames.listingDetails,
                      pathParameters: {'listingId': item.listingId!},
                    );
                  } catch (e) {
                    debugPrint('[ListingMediaGrid] Navigation error: $e');
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareMedia(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(MediaFeedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this media?'),
            const SizedBox(height: 16),
            _buildReportButton(context, item, 'Inappropriate Content'),
            _buildReportButton(context, item, 'Spam'),
            _buildReportButton(context, item, 'Copyright Violation'),
            _buildReportButton(context, item, 'Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    MediaFeedItem item,
    String reason,
  ) {
    return TextButton(
      onPressed: () => _reportMedia(item, reason),
      child: Text(reason),
    );
  }

  void _reportMedia(MediaFeedItem item, String reason) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      await _provider.reportMedia(mediaId: item.id, reason: reason);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareMedia(MediaFeedItem item) async {
    try {
      final message =
          '''
${item.title ?? 'Check this out'} from ${item.organizationName ?? 'Lehwi Palance'} ✨

${item.listingId != null ? '📍 View on Lehwi Palance: [Link to listing]' : ''}
#LehwiPalance #RealEstate
''';

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: item.title ?? 'Media from Lehwi Palance',
        ),
      );

      final userId = getIt<AuthProvider>().customerUser?.id;
      if (userId != null) {
        await _provider.trackShare(
          mediaId: item.id,
          userId: userId,
          platform: 'share_plus',
        );
      }
    } catch (e) {
      debugPrint('[ListingMediaGrid] Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share media'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login to perform this action'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// ============================================================
// FIXED: OrganizationMediaGridScreen
// ============================================================
class OrganizationMediaGridScreen extends StatefulWidget {
  final String organizationId;
  final String? organizationName;

  const OrganizationMediaGridScreen({
    super.key,
    required this.organizationId,
    this.organizationName,
  });

  @override
  State<OrganizationMediaGridScreen> createState() =>
      _OrganizationMediaGridScreenState();
}

class _OrganizationMediaGridScreenState
    extends State<OrganizationMediaGridScreen>
    with AutomaticKeepAliveClientMixin {
  late MediaFeedProvider _provider;
  late ScrollController _scrollController;

  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Use shared provider if available, otherwise create new one
    try {
      if (getIt.isRegistered<MediaFeedProvider>()) {
        _provider = getIt<MediaFeedProvider>();
        debugPrint(
          '[OrganizationMediaGrid] Using registered MediaFeedProvider',
        );
      } else {
        _provider = MediaFeedProvider(apiService: getIt<ApiService>());
        getIt.registerLazySingleton<MediaFeedProvider>(() => _provider);
        debugPrint(
          '[OrganizationMediaGrid] Created and registered new MediaFeedProvider',
        );
      }
    } catch (e) {
      _provider = MediaFeedProvider(apiService: getIt<ApiService>());
      debugPrint('[OrganizationMediaGrid] Created fallback MediaFeedProvider');
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load initial media
    _loadInitialMedia();
  }

  Future<void> _loadInitialMedia() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Use the paginated method
      await _provider.loadMediaByOrganization(
        organizationId: widget.organizationId,
        page: 1,
        pageSize: 30,
        refresh: true,
      );

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('[OrganizationMediaGrid] Error loading media: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMoreMedia() async {
    // Check if we can load more
    if (_isRefreshing) return;
    if (!_provider.hasMoreOrganizationItems) return;
    if (_provider.organizationItems.isEmpty) return;
    if (_provider.isLoadingMore) return;

    try {
      await _provider.loadMoreOrganizationMedia();
    } catch (e) {
      debugPrint('[OrganizationMediaGrid] Error loading more media: $e');
    }
  }

  void _onScroll() {
    // Check if we're near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMedia();
    }
  }

  Future<void> _refreshMedia() async {
    await _loadInitialMedia();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.organizationName ?? 'Organization Media',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshMedia,
            ),
          ],
        ),
        body: Consumer<MediaFeedProvider>(
          builder: (context, provider, child) {
            // Initial loading state
            if (provider.isLoading && provider.organizationItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading media...'),
                  ],
                ),
              );
            }

            // Error state
            if (provider.error != null && provider.organizationItems.isEmpty) {
              return _buildErrorWidget(provider.error!);
            }

            // Empty state
            if (provider.organizationItems.isEmpty) {
              return _buildEmptyWidget();
            }

            // Main grid with data
            return RefreshIndicator(
              onRefresh: _refreshMedia,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.75,
                ),
                itemCount:
                    provider.organizationItems.length +
                    (provider.hasMoreOrganizationItems ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end if we have more items
                  if (index == provider.organizationItems.length) {
                    return _buildLoadingMoreWidget();
                  }

                  final item = provider.organizationItems[index];
                  return MediaGridTile(
                    mediaItem: item,
                    onTap: () {
                      _navigateToMediaView(item, provider.organizationItems);
                    },
                    onLike: () {
                      _handleLike(item);
                    },
                    onSave: () {
                      _handleSave(item);
                    },
                    onLongPress: () {
                      _showMediaOptions(item, provider.organizationItems);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading media',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isRefreshing ? null : _refreshMedia,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No media available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'This organization has no media yet',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshMedia,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  void _navigateToMediaView(MediaFeedItem item, List<MediaFeedItem> allItems) {
    try {
      final router = GoRouter.of(context);
      router.pushNamed(
        RouteNames.media,
        extra: {
          'mediaItem': item,
          'mediaItems': allItems,
          'currentIndex': allItems.indexOf(item),
          'organizationId': widget.organizationId,
          'organizationName': widget.organizationName,
        },
      );
    } catch (e) {
      debugPrint('[OrganizationMediaGrid] Navigation error: $e');
      _showMediaDetailsDialog(item);
    }
  }

  void _showMediaDetailsDialog(MediaFeedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title ?? 'Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.mediaType == MediaType.image)
              CachedNetworkImage(
                imageUrl: item.url,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 200,
                  child: Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 16),
            Text('Likes: ${item.likeCount}'),
            Text('Comments: ${item.commentCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLike(MediaFeedItem item) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      await _provider.toggleLike(
        mediaId: item.id,
        isLiked: !item.isLikedByUser,
        userId: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSave(MediaFeedItem item) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      if (item.isSavedByUser) {
        await _provider.unsaveMedia(mediaId: item.id, userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from saved'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } else {
        await _provider.saveMedia(mediaId: item.id, userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to collection'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMediaOptions(MediaFeedItem item, List<MediaFeedItem> allItems) {
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
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                'View Details',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToMediaView(item, allItems);
              },
            ),
            ListTile(
              leading: Icon(
                item.isSavedByUser ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              title: Text(
                item.isSavedByUser ? 'Remove from Saved' : 'Save to Collection',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleSave(item);
              },
            ),
            if (item.listingId != null)
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.white),
                title: const Text(
                  'View Listing',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  try {
                    context.pushNamed(
                      RouteNames.listingDetails,
                      pathParameters: {'listingId': item.listingId!},
                    );
                  } catch (e) {
                    debugPrint('[OrganizationMediaGrid] Navigation error: $e');
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareMedia(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(MediaFeedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this media?'),
            const SizedBox(height: 16),
            _buildReportButton(context, item, 'Inappropriate Content'),
            _buildReportButton(context, item, 'Spam'),
            _buildReportButton(context, item, 'Copyright Violation'),
            _buildReportButton(context, item, 'Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    MediaFeedItem item,
    String reason,
  ) {
    return TextButton(
      onPressed: () => _reportMedia(item, reason),
      child: Text(reason),
    );
  }

  void _reportMedia(MediaFeedItem item, String reason) async {
    final userId = getIt<AuthProvider>().customerUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    try {
      await _provider.reportMedia(mediaId: item.id, reason: reason);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareMedia(MediaFeedItem item) async {
    try {
      final message =
          '''
${item.title ?? 'Check this out'} from ${item.organizationName ?? 'Lehwi Palance'} ✨

${item.listingId != null ? '📍 View on Lehwi Palance: [Link to listing]' : ''}
#LehwiPalance #RealEstate
''';

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: item.title ?? 'Media from Lehwi Palance',
        ),
      );

      final userId = getIt<AuthProvider>().customerUser?.id;
      if (userId != null) {
        await _provider.trackShare(
          mediaId: item.id,
          userId: userId,
          platform: 'share_plus',
        );
      }
    } catch (e) {
      debugPrint('[OrganizationMediaGrid] Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share media'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login to perform this action'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// ============================================================
// MEDIA GRID TILE WIDGET
// ============================================================

class MediaGridTile extends StatelessWidget {
  final MediaFeedItem mediaItem;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onLongPress;

  const MediaGridTile({
    super.key,
    required this.mediaItem,
    required this.onTap,
    required this.onLike,
    required this.onSave,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media thumbnail
          _buildThumbnail(),

          // Media type indicator
          if (mediaItem.mediaType == MediaType.video)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

          // Like count overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mediaItem.isLikedByUser
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: mediaItem.isLikedByUser ? Colors.red : Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${mediaItem.likeCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Save indicator
          if (mediaItem.isSavedByUser)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (mediaItem.mediaType == MediaType.video) {
      // video_thumbnail package not available - show a simple placeholder
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.videocam, color: Colors.grey)),
      );
    }

    return CachedNetworkImage(
      imageUrl: mediaItem.url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

// ============================================================
// MEDIA GRID TILE WIDGET
// ============================================================
