import 'package:flutter/material.dart';
import 'package:masar_jobs/models/article.dart';
import 'package:masar_jobs/services/api_service.dart';
import 'auth_provider.dart';
import 'package:provider/provider.dart';


class ConsultantArticleProvider extends ChangeNotifier {
  List<Article> _managedArticles = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<Article> get managedArticles => _managedArticles;
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
          print('Error parsing individual Article item: $e for item $item');
        }
      } else {
        // إذا لم يكن العنصر خريطة، قم بتسجيل الخطأ وتجاهله
        print('Skipping unexpected item type in list: $item');
      }
    }
    return articleList; // أعد القائمة التي تم بناؤها بأمان
  }


  // جلب المقالات التي نشرها الاستشاري (الصفحة الأولى)
  Future<void> fetchManagedArticles(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchManagedArticles(token!, page: 1);
      // print('Fetched initial articles response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن
      _managedArticles = _convertDynamicListToArticleList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchManagedArticles: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load managed articles: ${e.toString()}';
      print('Unexpected error during fetchManagedArticles: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من المقالات التي نشرها الاستشاري
  Future<void> fetchMoreManagedArticles(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null; // قد لا تريد مسح الخطأ هنا إذا كان خطأ تحميل الصفحة الأولى
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        // هذا لا ينبغي أن يحدث إذا كان المستخدم مصادقاً عليه أساساً
        throw ApiException(401, 'User not authenticated.');
      }

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedArticles(token, page: nextPage);
      // print('Fetched more articles response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _managedArticles.addAll(_convertDynamicListToArticleList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreManagedArticles: ${e.message}');
      // لا تعين _error العام هنا، فقط قم بتسجيل الخطأ أو إعلام المستخدم بطريقة أخرى بوجود مشكلة في تحميل المزيد
    } catch (e) {
      print('Unexpected error during fetchMoreManagedArticles: ${e.toString()}');
      // لا تعين _error العام هنا
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }


  // إنشاء مقال جديد بواسطة الاستشاري
  Future<void> createArticle(BuildContext context, Map<String, dynamic> articleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newArticle = await _apiService.createManagedArticle(token, articleData);
      print('Created new article: $newArticle'); // Debug print

      _managedArticles.insert(0, newArticle); // أضف المقال الجديد في بداية القائمة

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

  // تحديث مقال بواسطة الاستشاري
  Future<void> updateArticle(BuildContext context, int articleId, Map<String, dynamic> articleData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedArticle = await _apiService.updateManagedArticle(token, articleId, articleData);
      // print('Updated article: $updatedArticle'); // Debug print

      // العثور على المقال في القائمة المحلية وتحديثه
      final index = _managedArticles.indexWhere((article) => article.articleId == articleId);
      if (index != -1) {
        _managedArticles[index] = updatedArticle;
      } else {
        // إذا لم يتم العثور على المقال في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)،
        // يمكن إعادة جلب القائمة الرئيسية لتعكس التغيير.
        fetchManagedArticles(context); // إعادة جلب لتحديث القائمة المعروضة
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

  // حذف مقال بواسطة الاستشاري
  Future<void> deleteArticle(BuildContext context, int articleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteManagedArticle(token, articleId);

      // إزالة المقال من القائمة المحلية
      _managedArticles.removeWhere((article) => article.articleId == articleId);

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
extension ListConsultantArticleExtension on List<Article> {
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}