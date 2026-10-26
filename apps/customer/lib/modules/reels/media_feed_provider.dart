import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/media_feed_model.dart';

class MediaFeedProvider extends ChangeNotifier {
  final ApiService _apiService;

  // State
  List<MediaFeedItem> _mediaItems = [];
  List<MediaFeedItem> _trendingItems = [];
  List<MediaFeedItem> _recommendedItems = [];
  List<MediaFeedItem> _savedItems = [];
  List<MediaFeedItem> _organizationItems = [];
  List<MediaFeedItem> _listingItems = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _organizationPage = 1;
  int _listingPage = 1;
  bool _hasMore = true;
  bool _hasMoreOrganizationItems = true;
  bool _hasMoreListingItems = true;
  String? _currentSearchQuery;
  MediaType? _currentMediaType;
  String? _currentOrganizationId;
  String? _currentListingId;

  // Getters
  List<MediaFeedItem> get mediaItems => _mediaItems;
  List<MediaFeedItem> get trendingItems => _trendingItems;
  List<MediaFeedItem> get recommendedItems => _recommendedItems;
  List<MediaFeedItem> get savedItems => _savedItems;
  List<MediaFeedItem> get organizationItems => _organizationItems;
  List<MediaFeedItem> get listingItems => _listingItems;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get hasMoreOrganizationItems => _hasMoreOrganizationItems;
  bool get hasMoreListingItems => _hasMoreListingItems;
  int get currentPage => _currentPage;
  int get organizationPage => _organizationPage;
  int get listingPage => _listingPage;

  MediaFeedProvider({required ApiService apiService})
    : _apiService = apiService;

  /// Load media feed with pagination
  Future<void> loadMediaFeed({
    int page = 1,
    int pageSize = 20,
    String? organizationId,
    String? listingId,
    MediaType? mediaType,
    String? searchQuery,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _mediaItems.clear();
      _hasMore = true;
    }

    if (_isLoading || _isLoadingMore) return;

    _setLoading(true, false);
    _error = null;

    try {
      _currentOrganizationId = organizationId ?? _currentOrganizationId;
      _currentListingId = listingId ?? _currentListingId;
      _currentMediaType = mediaType ?? _currentMediaType;
      _currentSearchQuery = searchQuery ?? _currentSearchQuery;

      final result = await _apiService.getMediaFeed(
        page: page,
        pageSize: pageSize,
        organizationId: _currentOrganizationId,
        listingId: _currentListingId,
        mediaType: _currentMediaType,
        searchQuery: _currentSearchQuery,
      );

      if (refresh || page == 1) {
        _mediaItems = result.items;
      } else {
        _mediaItems.addAll(result.items);
      }

      _currentPage = page;
      _hasMore = result.hasNextPage;

      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load more items (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    await loadMediaFeed(page: _currentPage + 1);
  }

  /// Load trending media
  Future<void> loadTrendingMedia({int limit = 10}) async {
    _setLoading(true, false);
    _error = null;

    try {
      _trendingItems = await _apiService.getTrendingMedia(limit: limit);
      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load recommended media
  Future<void> loadRecommendedMedia({int limit = 10}) async {
    _setLoading(true, false);
    _error = null;

    try {
      _recommendedItems = await _apiService.getRecommendedMedia(limit: limit);
      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load media for a specific organization with pagination
  Future<void> loadMediaByOrganization({
    required String organizationId,
    int page = 1,
    int pageSize = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      _organizationPage = 1;
      _organizationItems.clear();
      _hasMoreOrganizationItems = true;
    }

    if (_isLoading || _isLoadingMore) return;

    _setLoading(true, false);
    _error = null;

    try {
      _currentOrganizationId = organizationId;

      final result = await _apiService.getMediaFeed(
        page: page,
        pageSize: pageSize,
        organizationId: organizationId,
        mediaType: _currentMediaType,
        searchQuery: _currentSearchQuery,
      );

      if (refresh || page == 1) {
        _organizationItems = result.items;
      } else {
        _organizationItems.addAll(result.items);
      }

      _organizationPage = page;
      _hasMoreOrganizationItems = result.hasNextPage;

      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load more organization media items (pagination)
  Future<void> loadMoreOrganizationMedia() async {
    if (!_hasMoreOrganizationItems || _isLoadingMore || _isLoading) return;
    if (_currentOrganizationId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await loadMediaByOrganization(
        organizationId: _currentOrganizationId!,
        page: _organizationPage + 1,
        refresh: false,
      );
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load media for a specific listing with pagination
  Future<void> loadMediaByListing({
    required String listingId,
    int page = 1,
    int pageSize = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      _listingPage = 1;
      _listingItems.clear();
      _hasMoreListingItems = true;
    }

    if (_isLoading || _isLoadingMore) return;

    _setLoading(true, false);
    _error = null;

    try {
      _currentListingId = listingId;

      final result = await _apiService.getMediaFeed(
        page: page,
        pageSize: pageSize,
        listingId: listingId,
        mediaType: _currentMediaType,
        searchQuery: _currentSearchQuery,
      );

      if (refresh || page == 1) {
        _listingItems = result.items;
      } else {
        _listingItems.addAll(result.items);
      }

      _listingPage = page;
      _hasMoreListingItems = result.hasNextPage;

      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load more listing media items (pagination)
  Future<void> loadMoreListingMedia() async {
    if (!_hasMoreListingItems || _isLoadingMore || _isLoading) return;
    if (_currentListingId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await loadMediaByListing(
        listingId: _currentListingId!,
        page: _listingPage + 1,
        refresh: false,
      );
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Legacy method - kept for backward compatibility
  /// Load media for a specific organization (non-paginated)
  Future<void> loadMediaByOrganizationLegacy(String organizationId) async {
    _setLoading(true, false);
    _error = null;

    try {
      _organizationItems = await _apiService.getMediaByOrganizationId(
        organizationId,
      );
      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Legacy method - kept for backward compatibility
  /// Load media for a specific listing (non-paginated)
  Future<void> loadMediaByListingLegacy(String listingId) async {
    _setLoading(true, false);
    _error = null;

    try {
      _listingItems = await _apiService.getMediaByListingId(listingId);
      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Load saved media for user
  Future<void> loadSavedMedia(String userId, {int limit = 20}) async {
    _setLoading(true, false);
    _error = null;

    try {
      _savedItems = await _apiService.getSavedMedia(
        userId: userId,
        limit: limit,
      );
      _setLoading(false, false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false, false);
    }
  }

  /// Toggle like on a media item
  Future<LikeResponse> toggleLike({
    required String mediaId,
    required bool isLiked,
    String? userId,
  }) async {
    try {
      final response = await _apiService.toggleLike(
        mediaId: mediaId,
        isLiked: isLiked,
        userId: userId,
      );

      _updateMediaItemLikes(mediaId, isLiked, response.likeCount);

      return response;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  /// Toggle follow on an organization
  Future<FollowResponse> toggleFollow({
    required String organizationId,
    required bool isFollowing,
    String? userId,
  }) async {
    try {
      final response = await _apiService.toggleFollow(
        organizationId: organizationId,
        isFollowing: isFollowing,
        userId: userId,
      );

      _updateMediaItemFollow(organizationId, isFollowing);

      return response;
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      rethrow;
    }
  }

  /// Save media to user's collection
  Future<void> saveMedia({
    required String mediaId,
    required String userId,
    String? collectionName,
  }) async {
    try {
      await _apiService.saveMedia(
        mediaId: mediaId,
        userId: userId,
        collectionName: collectionName,
      );
      _updateMediaItemSave(mediaId, true);
    } catch (e) {
      debugPrint('Error saving media: $e');
      rethrow;
    }
  }

  /// Unsave media from user's collection
  Future<void> unsaveMedia({
    required String mediaId,
    required String userId,
  }) async {
    try {
      await _apiService.unsaveMedia(mediaId: mediaId, userId: userId);
      _updateMediaItemSave(mediaId, false);
    } catch (e) {
      debugPrint('Error unsaving media: $e');
      rethrow;
    }
  }

  /// Track share for analytics
  Future<void> trackShare({
    required String mediaId,
    required String userId,
    String? platform,
  }) async {
    try {
      await _apiService.trackShare(
        mediaId: mediaId,
        userId: userId,
        platform: platform,
      );
    } catch (e) {
      debugPrint('Error tracking share: $e');
    }
  }

  /// Track view for analytics
  Future<void> trackView({
    required String mediaId,
    required String userId,
    Duration? viewDuration,
  }) async {
    try {
      await _apiService.trackView(
        mediaId: mediaId,
        userId: userId,
        viewDuration: viewDuration,
      );
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  /// Get media statistics
  Future<MediaStats> getMediaStats(String mediaId) async {
    try {
      return await _apiService.getMediaStats(mediaId);
    } catch (e) {
      debugPrint('Error getting media stats: $e');
      return const MediaStats();
    }
  }

  /// Report inappropriate media
  Future<void> reportMedia({
    required String mediaId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiService.reportMedia(
        mediaId: mediaId,
        reason: reason,
        description: description,
      );
    } catch (e) {
      debugPrint('Error reporting media: $e');
      rethrow;
    }
  }

  /// Search media
  Future<void> searchMedia(String query) async {
    _currentSearchQuery = query;
    await loadMediaFeed(page: 1, searchQuery: query, refresh: true);
  }

  /// Clear search
  void clearSearch() {
    _currentSearchQuery = null;
    loadMediaFeed(refresh: true);
  }

  /// Filter by media type
  void filterByMediaType(MediaType? mediaType) {
    _currentMediaType = mediaType;
    loadMediaFeed(refresh: true);
  }

  /// Reset all filters
  void resetFilters() {
    _currentOrganizationId = null;
    _currentListingId = null;
    _currentMediaType = null;
    _currentSearchQuery = null;
    loadMediaFeed(refresh: true);
  }

  // Helper methods
  void _setLoading(bool loading, bool loadingMore) {
    _isLoading = loading;
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  void _updateMediaItemLikes(String mediaId, bool isLiked, int likeCount) {
    _updateItemInList(_mediaItems, mediaId, isLiked, likeCount);
    _updateItemInList(_trendingItems, mediaId, isLiked, likeCount);
    _updateItemInList(_recommendedItems, mediaId, isLiked, likeCount);
    _updateItemInList(_savedItems, mediaId, isLiked, likeCount);
    _updateItemInList(_organizationItems, mediaId, isLiked, likeCount);
    _updateItemInList(_listingItems, mediaId, isLiked, likeCount);
    notifyListeners();
  }

  void _updateItemInList(
    List<MediaFeedItem> list,
    String mediaId,
    bool isLiked,
    int likeCount,
  ) {
    final index = list.indexWhere((item) => item.id == mediaId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        isLikedByUser: isLiked,
        likeCount: likeCount,
      );
    }
  }

  void _updateMediaItemFollow(String organizationId, bool isFollowing) {
    _updateFollowInList(_mediaItems, organizationId, isFollowing);
    _updateFollowInList(_trendingItems, organizationId, isFollowing);
    _updateFollowInList(_recommendedItems, organizationId, isFollowing);
    _updateFollowInList(_savedItems, organizationId, isFollowing);
    _updateFollowInList(_organizationItems, organizationId, isFollowing);
    _updateFollowInList(_listingItems, organizationId, isFollowing);
    notifyListeners();
  }

  void _updateFollowInList(
    List<MediaFeedItem> list,
    String organizationId,
    bool isFollowing,
  ) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].organizationId == organizationId) {
        list[i] = list[i].copyWith(isFollowing: isFollowing);
      }
    }
  }

  void _updateMediaItemSave(String mediaId, bool isSaved) {
    _updateSaveInList(_mediaItems, mediaId, isSaved);
    _updateSaveInList(_trendingItems, mediaId, isSaved);
    _updateSaveInList(_recommendedItems, mediaId, isSaved);
    _updateSaveInList(_organizationItems, mediaId, isSaved);
    _updateSaveInList(_listingItems, mediaId, isSaved);
    notifyListeners();
  }

  void _updateSaveInList(
    List<MediaFeedItem> list,
    String mediaId,
    bool isSaved,
  ) {
    final index = list.indexWhere((item) => item.id == mediaId);
    if (index != -1) {
      list[index] = list[index].copyWith(isSavedByUser: isSaved);
    }
  }
}
