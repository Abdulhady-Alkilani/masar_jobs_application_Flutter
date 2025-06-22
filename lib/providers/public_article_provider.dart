import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../models/paginated_response.dart'; // تأكد من المسار
import '../services/api_service.dart';
// لا تحتاج AuthProvider هنا لأن المسارات عامة
// import '../providers/auth_provider.dart';
// import 'package:provider/provider.dart';


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

  // **احذف هذا التابع المساعد**:
  // List<Article> _convertDynamicListToArticleList(List<dynamic>? data) { ... }


  // جلب أول صفحة من المقالات العامة
  Future<void> fetchArticles({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchArticles(page: page);
      // print('Fetched initial public articles response: $paginatedResponse'); // Debug print

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة الآن
      // لأن التحويل الآمن أصبح يتم داخل PaginatedResponse.fromJson
      _articles = paginatedResponse.data ?? [];


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
    // لا تجلب المزيد إذا كنت تحمل بالفعل أو لا يوجد المزيد من الصفحات
    if (_isFetchingMore || !hasMorePages) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchArticles(page: nextPage);
      // print('Fetched more public articles response: $paginatedResponse'); // Debug print

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة الآن
      _articles.addAll(paginatedResponse.data ?? []);


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
    // حاول إيجاد المقال في القائمة المحملة حالياً أولاً
    final existingArticle = _articles.firstWhereOrNull((article) => article.articleId == articleId);
    if (existingArticle != null) {
      return existingArticle;
    }

    // إذا لم يوجد في القائمة، اذهب لجلبه من الـ API العام
    // لا نغير حالة التحميل الرئيسية هنا لعدم التأثير على عرض القائمة الرئيسية
    // bool _isFetchingSingleArticle = false; // تعريف حالة تحميل فردية إذا لزم الأمر

    try {
      // هذا المسار عام لا يتطلب توكن
      final article = await _apiService.fetchArticle(articleId);
      // لا تضيفه للقائمة هنا لتجنب تكرار العناصر في القائمة الرئيسية المصفحة
      return article;
    } on ApiException catch (e) {
      print('API Exception during fetchSinglePublicArticle: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام هنا إذا فشل جلب التفاصيل
      return null; // أعد null للإشارة إلى الفشل
    } catch (e) {
      print('Unexpected error during fetchSinglePublicArticle: ${e.toString()}');
      _error = 'Failed to load article details: ${e.toString()}';
      return null; // أعد null للإشارة إلى الفشل
    } finally {
      // يمكن تحديث حالة تحميل العنصر الفردي هنا
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