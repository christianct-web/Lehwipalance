// lib/customer/modules/reels/media_feed_model.dart
// lib/customer/modules/reels/media_feed_model.dart

import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';

/// Media type enum
enum MediaType { image, video }

/// Media feed item model - represents a reel/advertisement for an organization or listing
class MediaFeedItem {
  final String id;
  final String url;
  final MediaType mediaType;
  final String? title;
  final String? description;
  final String? listingId;
  final String? organizationId;
  final String? organizationName;
  final String? organizationAvatar;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool isLikedByUser;
  final bool isSavedByUser;
  final bool isFollowing;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  MediaFeedItem({
    required this.id,
    required this.url,
    required this.mediaType,
    this.title,
    this.description,
    this.listingId,
    this.organizationId,
    this.organizationName,
    this.organizationAvatar,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.isLikedByUser = false,
    this.isSavedByUser = false,
    this.isFollowing = false,
    this.tags,
    this.metadata,
  });

  /// Factory constructor from MediaModel
  factory MediaFeedItem.fromMediaModel(
    MediaModel model, {
    String? id,
    String? title,
    String? description,
    String? listingId,
    String? organizationId,
    String? organizationName,
    String? organizationAvatar,
    DateTime? createdAt,
    bool isVideo = false,
    int likeCount = 0,
    int commentCount = 0,
    int shareCount = 0,
    int viewCount = 0,
  }) {
    final mediaType = isVideo ? MediaType.video : MediaType.image;
    final url =
        isVideo && model.videoUrls != null && model.videoUrls!.isNotEmpty
        ? model.videoUrls!.first
        : model.imageUrls.isNotEmpty
        ? model.imageUrls.first
        : model.mainImageUrl;

    return MediaFeedItem(
      id: id ?? url.hashCode.toString(),
      url: url,
      mediaType: mediaType,
      title: title,
      description: description ?? title,
      listingId: listingId,
      organizationId: organizationId,
      organizationName: organizationName,
      organizationAvatar: organizationAvatar,
      createdAt: createdAt ?? DateTime.now(),
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      viewCount: viewCount,
    );
  }

  /// Factory constructor from MerchantListingDTO
  factory MediaFeedItem.fromListing(
    MerchantListingDTO listing, {
    String? mediaUrl,
    MediaType? mediaType,
    bool isVideo = false,
    int likeCount = 0,
    int commentCount = 0,
    int shareCount = 0,
    int viewCount = 0,
  }) {
    final type = mediaType ?? (isVideo ? MediaType.video : MediaType.image);
    final url = mediaUrl ?? listing.mediaUrls.mainImageUrl;

    return MediaFeedItem(
      id: '${listing.id}_${url.hashCode}',
      url: url,
      mediaType: type,
      title: listing.title,
      description: listing.description,
      listingId: listing.id,
      organizationId: listing.organizationId,
      organizationName: listing.title,
      organizationAvatar: null,
      createdAt: listing.createdAt,
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      viewCount: viewCount,
    );
  }

  /// Create from JSON
  factory MediaFeedItem.fromJson(Map<String, dynamic> json) {
    return MediaFeedItem(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      mediaType: MediaType.values.firstWhere(
        (e) => e.toString() == json['mediaType'],
        orElse: () => MediaType.image,
      ),
      title: json['title'],
      description: json['description'],
      listingId: json['listingId'],
      organizationId: json['organizationId'],
      organizationName: json['organizationName'],
      organizationAvatar: json['organizationAvatar'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      isSavedByUser: json['isSavedByUser'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      tags: json['tags']?.cast<String>(),
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'mediaType': mediaType.toString(),
      'title': title,
      'description': description,
      'listingId': listingId,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'organizationAvatar': organizationAvatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'isLikedByUser': isLikedByUser,
      'isSavedByUser': isSavedByUser,
      'isFollowing': isFollowing,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  MediaFeedItem copyWith({
    String? id,
    String? url,
    MediaType? mediaType,
    String? title,
    String? description,
    String? listingId,
    String? organizationId,
    String? organizationName,
    String? organizationAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    bool? isLikedByUser,
    bool? isSavedByUser,
    bool? isFollowing,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return MediaFeedItem(
      id: id ?? this.id,
      url: url ?? this.url,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      description: description ?? this.description,
      listingId: listingId ?? this.listingId,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      organizationAvatar: organizationAvatar ?? this.organizationAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isSavedByUser: isSavedByUser ?? this.isSavedByUser,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFeedItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Like response model
class LikeResponse {
  final bool success;
  final String message;
  final int likeCount;

  const LikeResponse({
    required this.success,
    required this.message,
    this.likeCount = 0,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      likeCount: json['likeCount'] ?? 0,
    );
  }

  LikeResponse copyWith({bool? success, String? message, int? likeCount}) {
    return LikeResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}

/// Follow response model
class FollowResponse {
  final bool success;
  final String message;
  final int followersCount;

  const FollowResponse({
    required this.success,
    required this.message,
    this.followersCount = 0,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) {
    return FollowResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      followersCount: json['followersCount'] ?? 0,
    );
  }

  FollowResponse copyWith({
    bool? success,
    String? message,
    int? followersCount,
  }) {
    return FollowResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}

/// Media statistics model
class MediaStats {
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final double? averageWatchTime;
  final double? engagementRate;
  final DateTime? lastViewed;

  const MediaStats({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.averageWatchTime,
    this.engagementRate,
    this.lastViewed,
  });

  factory MediaStats.fromJson(Map<String, dynamic> json) {
    return MediaStats(
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      saves: json['saves'] ?? 0,
      averageWatchTime: json['averageWatchTime']?.toDouble(),
      engagementRate: json['engagementRate']?.toDouble(),
      lastViewed: json['lastViewed'] != null
          ? DateTime.parse(json['lastViewed'])
          : null,
    );
  }

  MediaStats copyWith({
    int? views,
    int? likes,
    int? comments,
    int? shares,
    int? saves,
    double? averageWatchTime,
    double? engagementRate,
    DateTime? lastViewed,
  }) {
    return MediaStats(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      averageWatchTime: averageWatchTime ?? this.averageWatchTime,
      engagementRate: engagementRate ?? this.engagementRate,
      lastViewed: lastViewed ?? this.lastViewed,
    );
  }
}

/// Media comment model
class MediaComment {
  final String id;
  final String mediaId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool isLikedByUser;
  final List<MediaComment>? replies;

  const MediaComment({
    required this.id,
    required this.mediaId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.isLikedByUser = false,
    this.replies,
  });

  factory MediaComment.fromJson(Map<String, dynamic> json) {
    return MediaComment(
      id: json['id'] ?? '',
      mediaId: json['mediaId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: json['userAvatarUrl'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      likeCount: json['likeCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((e) => MediaComment.fromJson(e))
                .toList()
          : null,
    );
  }

  MediaComment copyWith({
    String? id,
    String? mediaId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    bool? isLikedByUser,
    List<MediaComment>? replies,
  }) {
    return MediaComment(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      replies: replies ?? this.replies,
    );
  }
}

final List<MediaFeedItem> mockMediaFeedItems = [
  MediaFeedItem(
    id: 'feed_001',
    url: 'https://picsum.photos/400/600?random=1',
    mediaType: MediaType.image,
    title: 'TechConf 2025 - Trinidad',
    description: 'The biggest tech conference of the year',
    listingId: 'evt_001',
    organizationId: 'org_001',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likeCount: 342,
    commentCount: 45,
    shareCount: 89,
    viewCount: 1234,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['technology', 'conference', 'networking'],
  ),
  MediaFeedItem(
    id: 'feed_002',
    url: 'https://picsum.photos/400/600?random=2',
    mediaType: MediaType.video,
    title: 'Trinidad Carnival Kickoff 2025',
    description: 'Three days of incredible music',
    listingId: 'evt_002',
    organizationId: 'org_music_fest',
    organizationName: 'Tobago Events & Hospitality',
    organizationAvatar: 'https://picsum.photos/100/100?random=org2',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likeCount: 567,
    commentCount: 78,
    shareCount: 123,
    viewCount: 2345,
    isLikedByUser: true,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['music', 'carnival', 'soca'],
  ),
  MediaFeedItem(
    id: 'feed_003',
    url: 'https://picsum.photos/400/600?random=3',
    mediaType: MediaType.image,
    title: 'Hyatt Regency Trinidad - Luxury Stay',
    description: '5-star luxury hotel in downtown Port of Spain',
    listingId: 'htl_001',
    organizationId: 'org_hospitality',
    organizationName: 'Caribbean Hotel Group',
    organizationAvatar: 'https://picsum.photos/100/100?random=org3',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    likeCount: 234,
    commentCount: 34,
    shareCount: 56,
    viewCount: 987,
    isLikedByUser: false,
    isSavedByUser: true,
    isFollowing: false,
    tags: ['luxury', 'hotel', 'accommodation'],
  ),
  MediaFeedItem(
    id: 'feed_004',
    url: 'https://picsum.photos/400/600?random=4',
    mediaType: MediaType.image,
    title: "Queen's Park Savannah Experience",
    description: 'Explore the largest open space in Port of Spain',
    listingId: 'plc_001',
    organizationId: 'org_tourism',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    likeCount: 178,
    commentCount: 23,
    shareCount: 45,
    viewCount: 876,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['park', 'tourism', 'culture'],
  ),
  MediaFeedItem(
    id: 'feed_005',
    url: 'https://picsum.photos/400/600?random=5',
    mediaType: MediaType.video,
    title: 'Caribbean AI & Machine Learning Summit',
    description: 'Deep dive into the latest advancements in AI',
    listingId: 'evt_003',
    organizationId: 'org_tech_conf',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likeCount: 456,
    commentCount: 67,
    shareCount: 98,
    viewCount: 3456,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: true,
    tags: ['AI', 'machine learning', 'technology'],
  ),
  MediaFeedItem(
    id: 'feed_006',
    url: 'https://picsum.photos/400/600?random=6',
    mediaType: MediaType.image,
    title: 'Maracas Beach Day Trip',
    description: 'Experience Trinidad\'s most famous beach',
    listingId: 'plc_002',
    organizationId: 'org_tourism',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    likeCount: 389,
    commentCount: 56,
    shareCount: 78,
    viewCount: 1567,
    isLikedByUser: true,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['beach', 'tourism', 'food'],
  ),
  MediaFeedItem(
    id: 'feed_007',
    url: 'https://picsum.photos/400/600?random=7',
    mediaType: MediaType.image,
    title: 'Luxury Spa Package at Hyatt',
    description: 'Relax and rejuvenate with premium spa services',
    listingId: 'srv_001',
    organizationId: 'org_services',
    organizationName: 'Caribbean Hotel Group',
    organizationAvatar: 'https://picsum.photos/100/100?random=org3',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    likeCount: 267,
    commentCount: 34,
    shareCount: 56,
    viewCount: 1098,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['wellness', 'spa', 'luxury'],
  ),
  MediaFeedItem(
    id: 'feed_008',
    url: 'https://picsum.photos/400/600?random=8',
    mediaType: MediaType.video,
    title: 'Pitch Lake Tour',
    description: 'Visit the largest natural asphalt lake in the world',
    listingId: 'plc_003',
    organizationId: 'org_tourism',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likeCount: 145,
    commentCount: 23,
    shareCount: 34,
    viewCount: 765,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['natural wonder', 'tourism', 'geology'],
  ),
  MediaFeedItem(
    id: 'feed_009',
    url: 'https://picsum.photos/400/600?random=9',
    mediaType: MediaType.image,
    title: 'Hilton Trinidad & Conference Centre',
    description: 'Iconic hotel with panoramic city views',
    listingId: 'htl_002',
    organizationId: 'org_hospitality',
    organizationName: 'Caribbean Hotel Group',
    organizationAvatar: 'https://picsum.photos/100/100?random=org3',
    createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    likeCount: 312,
    commentCount: 45,
    shareCount: 67,
    viewCount: 1234,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['business', 'hotel', 'conference'],
  ),
  MediaFeedItem(
    id: 'feed_010',
    url: 'https://picsum.photos/400/600?random=10',
    mediaType: MediaType.video,
    title: 'Steelpan Music Lessons',
    description: 'Learn to play the steelpan, Trinidad\'s national instrument',
    listingId: 'srv_002',
    organizationId: 'org_services',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
    likeCount: 234,
    commentCount: 34,
    shareCount: 45,
    viewCount: 987,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['music', 'culture', 'education'],
  ),
  MediaFeedItem(
    id: 'feed_011',
    url: 'https://picsum.photos/400/600?random=11',
    mediaType: MediaType.image,
    title: 'Startup Pitch Competition - Caribbean Edition',
    description: 'Watch promising Caribbean startups compete',
    listingId: 'evt_004',
    organizationId: 'org_startup',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    likeCount: 189,
    commentCount: 28,
    shareCount: 39,
    viewCount: 876,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['startup', 'entrepreneurship', 'innovation'],
  ),
  MediaFeedItem(
    id: 'feed_012',
    url: 'https://picsum.photos/400/600?random=12',
    mediaType: MediaType.image,
    title: 'Pigeon Point Heritage Park',
    description: 'Iconic Tobago beach with the famous jetty',
    listingId: 'plc_004',
    organizationId: 'org_tourism',
    organizationName: 'Tobago Events & Hospitality',
    organizationAvatar: 'https://picsum.photos/100/100?random=org2',
    createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
    likeCount: 423,
    commentCount: 56,
    shareCount: 78,
    viewCount: 1876,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['beach', 'tourism', 'heritage'],
  ),
  MediaFeedItem(
    id: 'feed_013',
    url: 'https://picsum.photos/400/600?random=13',
    mediaType: MediaType.video,
    title: 'Soca & Steelpan Night',
    description: 'An energetic evening of soca music and steelpan',
    listingId: 'evt_005',
    organizationId: 'org_music',
    organizationName: 'Caribbean Events Pro',
    organizationAvatar: 'https://picsum.photos/100/100?random=org1',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    likeCount: 678,
    commentCount: 89,
    shareCount: 123,
    viewCount: 3456,
    isLikedByUser: true,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['soca', 'music', 'culture'],
  ),
  MediaFeedItem(
    id: 'feed_014',
    url: 'https://picsum.photos/400/600?random=14',
    mediaType: MediaType.image,
    title: 'Argyle Waterfall Adventure',
    description: 'Tobago\'s highest waterfall in the rainforest',
    listingId: 'plc_006',
    organizationId: 'org_tourism',
    organizationName: 'Tobago Events & Hospitality',
    organizationAvatar: 'https://picsum.photos/100/100?random=org2',
    createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
    likeCount: 345,
    commentCount: 43,
    shareCount: 67,
    viewCount: 1345,
    isLikedByUser: false,
    isSavedByUser: false,
    isFollowing: false,
    tags: ['waterfall', 'adventure', 'nature'],
  ),
  MediaFeedItem(
    id: 'feed_015',
    url: 'https://picsum.photos/400/600?random=15',
    mediaType: MediaType.image,
    title: 'Magdalena Grand Beach & Golf Resort',
    description: 'Luxury beachfront resort with golf course',
    listingId: 'htl_003',
    organizationId: 'org_hospitality',
    organizationName: 'Caribbean Hotel Group',
    organizationAvatar: 'https://picsum.photos/100/100?random=org3',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    likeCount: 456,
    commentCount: 67,
    shareCount: 89,
    viewCount: 1567,
    isLikedByUser: false,
    isSavedByUser: true,
    isFollowing: false,
    tags: ['resort', 'golf', 'luxury'],
  ),
];
