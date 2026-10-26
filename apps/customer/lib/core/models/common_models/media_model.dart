/// Organization media assets
class MediaModel {
  final String mainImageUrl;
  final String? logoUrl;
  final List<String> imageUrls;
  final List<String>? videoUrls;

  const MediaModel({
    required this.mainImageUrl,
    this.logoUrl,
    this.imageUrls = const [],
    this.videoUrls,
  });

  bool get hasImages => imageUrls.isNotEmpty;
  static MediaModel empty() => const MediaModel(mainImageUrl: '');
  Map<String, dynamic> toJson() {
    return {};
  }

  // ==============================
  // 🔹 Firestore Deserialization
  // ==============================

  factory MediaModel.fromJson(Map<String, dynamic>? map) {
    if (map == null) {
      return MediaModel(
        mainImageUrl: '',
        logoUrl: null,
        imageUrls: [],
        videoUrls: null,
      );
    }

    return MediaModel(
      mainImageUrl: map['mainImageUrl'] ?? '',
      logoUrl: map['logoUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: map['videoUrls'] != null
          ? List<String>.from(map['videoUrls'])
          : null,
    );
  }
}

// Helper class for media items
class MediaItem {
  final String url;
  final MediaType type;
  // final bool isVideo;
  final String? title;
  final String? listingId;

  MediaItem({
    required this.url,
    required this.type,
    //   required this.isVideo,
    this.title,
    this.listingId,
  });

  // Create from MediaModel
  factory MediaItem.fromMediaModel(
    MediaModel model, {
    String? title,
    String? listingId,
  }) {
    // For videos
    if (model.videoUrls != null && model.videoUrls!.isNotEmpty) {
      return MediaItem(
        url: model.videoUrls!.first,
        type: MediaType.video,
        //    isVideo: true,
        title: title,
        listingId: listingId,
      );
    }
    // For images
    if (model.imageUrls.isNotEmpty) {
      return MediaItem(
        url: model.imageUrls.first,
        type: MediaType.image,
        //    isVideo: false,
        title: title,
        listingId: listingId,
      );
    }
    // Fallback to main image
    return MediaItem(
      url: model.mainImageUrl,
      type: MediaType.image,
      //   isVideo: false,
      title: title,
      listingId: listingId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

/// Media type enum
enum MediaType { image, video }
