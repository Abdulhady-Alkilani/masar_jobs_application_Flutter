import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/api_service.dart';

class PublicArticleProvider extends ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // تابع مساعدة للتحويل الآمن والمتحكم به من List<dynamic> إلى List<Article>
  List<Article> _convertDynamicListToArticleList(List<dynamic>? data) {
    if (data == null) return []; // إذا كانت القائمة الأصلية null، أعد قائمة فارغة

    List<Article> articleList = [];
    for (final item in data) {
      // تحقق مما إذا كان العنصر هو خريطة قبل محاولة فك ترميزه كـ Article
      if (item is Map<String, dynamic>) {
        try {
          // حاول فك ترميز العنصر كـ Article
          articleList.add(Article.fromJson(item));
        } catch (e) {
          // إذا فشل فك ترميز عنصر واحد، قم بتسجيل الخطأ وتجاهل هذا العنصر
          print('Error parsing individual Article item in public list: $e for item $item');
        }
      } else {
        // إذا لم يكن العنصر خريطة، قم بتسجيل الخطأ وتجاهله
        print('Skipping unexpected item type in public Article list: $item');
      }
    }
    return articleList; // أعد القائمة التي تم بناؤها بأمان
  }


  // جلب أول صفحة من المقالات
  Future<void> fetchArticles({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // هنا لا نحتاج لتوكن لأن المسار عام
      final paginatedResponse = await _apiService.fetchArticles(page: page);
      // print('Fetched initial public articles response: $paginatedResponse'); // Debug print


      // استخدم التابع المساعد للتحويل الآمن
      _articles = _convertDynamicListToArticleList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchPublicArticles: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load articles: ${e.toString()}';
      print('Unexpected error during fetchPublicArticles: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من المقالات
  Future<void> fetchMoreArticles() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      // هنا لا نحتاج لتوكن لأن المسار عام
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchArticles(page: nextPage);
      // print('Fetched more public articles response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _articles.addAll(_convertDynamicListToArticleList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMorePublicArticles: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMorePublicArticles: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل مقال محدد
  Future<Article?> fetchArticle(int articleId) async {
    // تحقق مما إذا كان المقال موجوداً بالفعل في القائمة المحملة
    final existingArticle = _articles.firstWhereOrNull((article) => article.articleId == articleId);
    if (existingArticle != null) {
      return existingArticle;
    }

    // إذا لم يكن موجوداً في القائمة، اذهب لجلبه من الـ API
    // حالة تحميل منفصلة لجلب عنصر فردي (اختياري)
    // setState(() { _isFetchingSingleArticle = true; }); notifyListeners();

    try {
      // هنا لا نحتاج لتوكن لأن المسار عام
      final article = await _apiService.fetchArticle(articleId);
      // لا تضيفه للقائمة هنا لتجنب تكرار العناصر في القائمة الرئيسية المصفحة
      return article;
    } on ApiException catch (e) {
      print('API Exception during fetchSinglePublicArticle: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام إذا فشل جلب التفاصيل
      return null;
    } catch (e) {
      print('Unexpected error during fetchSinglePublicArticle: ${e.toString()}');
      _error = 'Failed to load article details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleArticle = false; }); notifyListeners();
    }
  }

}

// Simple extension to mimic firstWhereOrNull if not using collection package
extension ListArticleExtension on List<Article> {
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}