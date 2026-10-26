abstract class Identifiable {
  String get id;
}

abstract class Timestamped {
  DateTime get createdAt;
  DateTime? get updatedAt;
}

abstract class Publishable {
  PublishStatus get status;
  bool get isActive;
}

extension PublishStatusX on PublishStatus {
  static PublishStatus fromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
        return PublishStatus.draft;
      case 'published':
        return PublishStatus.published;
      case 'archived':
        return PublishStatus.archived;
      default:
        throw FormatException('Unknown PublishStatus value: $value');
    }
  }
}

enum PublishStatus { draft, unpublished, published, archived, canceled }
