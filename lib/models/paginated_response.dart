import 'dart:convert'; // قد تحتاج لفك ترميز داخلي في المستقبل أو لطباعة Debug

class PaginatedResponse<T> {
  final int? currentPage;
  final List<T>? data; // <--- تأكد أن هذا هو النوع الصحيح
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

  // الباني المصنعي لتحويل JSON إلى PaginatedResponse<T>
  // يتطلب دالة fromJsonT: دالة تأخذ Map<String, dynamic> وتعيد كائن من نوع T
  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, Function(Map<String, dynamic>) fromJsonT) {

    // **التصحيح هنا:** معالجة القائمة 'data' وتحويلها بشكل صريح وآمن
    List<T>? dataList;
    if (json['data'] is List) {
      List<dynamic> rawList = json['data'];
      dataList = rawList.map((item) {
        // تحقق من نوع العنصر قبل محاولة فك ترميزه
        if (item is Map<String, dynamic>) {
          try {
            // حاول فك ترميز العنصر إلى نوع T باستخدام الدالة الممررة
            return fromJsonT(item);
          } catch (e) {
            // إذا فشل فك الترميز لعنصر واحد، قم بتسجيل الخطأ وتجاهله
            print('Error parsing item in PaginatedResponse data: $e for item $item');
            return null; // أعد null لتجاهل العنصر الخاطئ
          }
        } else {
          // إذا كان العنصر ليس Map، فهو ليس بالهيئة المتوقعة، تجاهله
          print('Skipping non-Map item in PaginatedResponse data: $item');
          return null;
        }
      }).whereType<T>().toList(); // تصفية العناصر الـ null وتحويل إلى List<T>
    }


    return PaginatedResponse<T>(
      currentPage: json['current_page'] as int?,
      data: dataList, // <--- استخدم القائمة التي تم تحويلها بأمان
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

// تابع اختياري لطباعة محتويات PaginatedResponse (للتصحيح)
/*
   @override
   String toString() {
     return 'PaginatedResponse(currentPage: $currentPage, dataCount: ${data?.length}, lastPage: $lastPage, total: $total)';
   }
   */
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