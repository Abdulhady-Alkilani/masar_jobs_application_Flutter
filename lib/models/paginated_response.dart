class PaginatedResponse<T> {
  final int? currentPage;
  final List<dynamic>? data;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
// final List<Link>? links; // You could create a Link model
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;
  PaginatedResponse({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
// this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });
  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedResponse<T>(
      currentPage: json['current_page'] as int?,
      data: (json['data'] as List<dynamic>?)
      !.map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      firstPageUrl: json['first_page_url'] as String?,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int?,
      lastPageUrl: json['last_page_url'] as String?,
// links: (json['links'] as List<dynamic>?)?.map((l) => Link.fromJson(l as Map<String, dynamic>)).toList(),
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String?,
      perPage: json['per_page'] as int?,
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int?,
      total: json['total'] as int?,
    );
  }
}
// Example of how to use PaginatedResponse:
// Future<PaginatedResponse<Article>> fetchArticles() async {
//   final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/v1/articles'));
//   if (response.statusCode == 200) {
//     return PaginatedResponse<Article>.fromJson(
//       jsonDecode(response.body),
//       (json) => Article.fromJson(json), // Pass the specific model's fromJson
//     );
//   } else {
//     throw Exception('Failed to load articles');
//   }
// }
