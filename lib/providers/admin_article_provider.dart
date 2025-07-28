import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'package:provider/provider.dart';


class AdminArticleProvider extends ChangeNotifier {
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

  // !! تم حذف التابع المساعد _convertDynamicListToArticleList !!
  // لأن التحويل من Map<String, dynamic> إلى Article
  // يتم الآن داخل PaginatedResponse.fromJson باستخدام الدالة الممررة


  // جلب جميع المقالات (للأدمن) - الصفحة الأولى
  Future<void> fetchAllArticles(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllArticlesAdmin(token!, page: 1);
      // print('Fetched initial admin articles response: $paginatedResponse'); // Debug print

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _articles = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllArticlesAdmin: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load articles: ${e.toString()}';
      print('Unexpected error during fetchAllArticlesAdmin: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من المقالات
  Future<void> fetchMoreArticles(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllArticlesAdmin(token, page: nextPage);
      // print('Fetched more admin articles response: $paginatedResponse'); // Debug print

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _articles.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreAdminArticles: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreAdminArticles: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب مقال واحد بواسطة الأدمن (لشاشة التفاصيل)
  Future<Article?> fetchSingleArticle(BuildContext context, int articleId) async {
    // حاول إيجاد المقال في القائمة المحملة حالياً
    final existingArticle = _articles.firstWhereOrNull((article) => article.articleId == articleId);
    if (existingArticle != null) {
      return existingArticle;
    }

    // إذا لم يوجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا
    // setState(() { _isFetchingSingleArticle = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final article = await _apiService.fetchSingleArticleAdmin(token, articleId);
      // لا تضيفه للقائمة هنا

      return article;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminArticle: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminArticle: ${e.toString()}');
      _error = 'Failed to load article details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleArticle = false; }); notifyListeners();
    }
  }


  // إنشاء مقال (بواسطة الأدمن)
  Future<void> createArticle(BuildContext context, Map<String, dynamic> articleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newArticle = await _apiService.createArticleAdmin(token, articleData);
      // print('Created new article: $newArticle'); // Debug print

      _articles.insert(0, newArticle); // أضف المقال الجديد في بداية القائمة

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create article: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث مقال (بواسطة الأدمن)
  Future<void> updateArticle(BuildContext context, int articleId, Map<String, dynamic> articleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedArticle = await _apiService.updateArticleAdmin(token, articleId, articleData);
      // print('Updated article: $updatedArticle'); // Debug print

      // العثور على المقال في القائمة المحلية وتحديثه
      final index = _articles.indexWhere((article) => article.articleId == articleId);
      if (index != -1) {
        _articles[index] = updatedArticle;
      } else {
        // إذا لم يتم العثور على المقال في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        fetchAllArticles(context); // إعادة جلب لتحديث القائمة المعروضة
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update article: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف مقال (بواسطة الأدمن)
  Future<void> deleteArticle(BuildContext context, int articleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteArticleAdmin(token, articleId);

      // إزالة المقال من القائمة المحلية
      _articles.removeWhere((article) => article.articleId == articleId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete article: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Article>
extension ListConsultantArticleExtension on List<Article> { // ربما يجب تغيير الاسم إلى ListArticleExtension أو ListAdminArticleExtension ليكون أكثر وضوحاً
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}