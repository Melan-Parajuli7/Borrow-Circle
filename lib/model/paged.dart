/// Wrapper for the backend's paginated lists:
/// { items|requests|loans|reviews: [...], page, limit, total, totalPages }
class Paged<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Paged({
    required this.data,
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
  });

  bool get hasMore => page < totalPages;

  /// [listKey] is the name of the list in the JSON ("items", "requests", ...).
  factory Paged.fromJson(
    Map<String, dynamic> json,
    String listKey,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final raw = (json[listKey] as List?) ?? const [];
    return Paged<T>(
      data: raw.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
