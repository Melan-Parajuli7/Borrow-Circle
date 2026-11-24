/// Generic paginated response wrapper.
///
/// Contains the list of items for the current page, pagination metadata,
/// and a flag indicating if more pages are available.
class Paged<T> {
  /// Items for the current page.
  final List<T> data;

  /// Total number of items across all pages.
  final int total;

  /// Current page number (1-based).
  final int page;

  /// Number of items per page.
  final int limit;

  /// Whether there are more pages after the current one.
  final bool hasMore;

  /// Creates a [Paged] result with the given properties.
  const Paged({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  /// Creates a [Paged] instance from a JSON response.
  ///
  /// [json] - The decoded JSON response.
  /// [dataKey] - The key in the JSON object that contains the array of items.
  /// [fromJson] - Function to convert each JSON item to type [T].
  factory Paged.fromJson(
    Map<String, dynamic> json,
    String dataKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawData = (json[dataKey] as List<dynamic>?) ?? const [];
    final data = rawData
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
    final total = (json['total'] as num?)?.toInt() ?? data.length;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? data.length;
    final hasMore = (json['has_more'] as bool?) ?? false;

    return Paged<T>(
      data: data,
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
    );
  }
}