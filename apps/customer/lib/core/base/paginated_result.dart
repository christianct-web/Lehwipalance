// core/base/paginated_result.dart

class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResult.fromList({
    required List<T> allItems,
    required int page,
    required int pageSize,
  }) {
    // INPUT VALIDATION - CRITICAL
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize <= 0 ? 20 : pageSize;

    // If the list is empty or page is out of range, return empty result
    if (allItems.isEmpty || (safePage * safePageSize) >= allItems.length) {
      return PaginatedResult(
        items: [],
        totalCount: allItems.length,
        page: safePage,
        pageSize: safePageSize,
        hasNextPage: false,
        hasPreviousPage: safePage > 0,
      );
    }

    // FIX: Use 0-based page indexing (no subtract 1)
    final startIndex = safePage * safePageSize;
    final endIndex = (startIndex + safePageSize).clamp(0, allItems.length);

    // Safe sublist extraction
    final items = startIndex < allItems.length
        ? allItems.sublist(startIndex, endIndex)
        : <T>[];

    final totalCount = allItems.length;
    final hasNextPage = endIndex < totalCount;
    final hasPreviousPage = safePage > 0;

    return PaginatedResult(
      items: items,
      totalCount: totalCount,
      page: safePage,
      pageSize: safePageSize,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}
