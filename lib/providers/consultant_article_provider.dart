import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
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

  // جلب المقالات التي نشرها الاستشاري
  Future<void> fetchManagedArticles(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || userType != 'خبير استشاري') {
      //    throw ApiException(403, 'User not authorized to manage articles.');
      // }

      final paginatedResponse = await _apiService.fetchManagedArticles(token!, page: 1);
      // print(paginatedResponse); // للتصحيح

      // التصحيح هنا: إضافة التحويل الصريح إلى List<Article>
      _managedArticles = (paginatedResponse.data ?? []) as List<Article>;


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load managed articles: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> fetchMoreManagedArticles(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedArticles(token, page: nextPage);
      // print(paginatedResponse); // للتصحيح

      // التصحيح هنا: إضافة التحويل الصريح إلى List<Article>
      _managedArticles.addAll((paginatedResponse.data ?? []) as List<Article>);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more managed articles: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more managed articles: ${e.toString()}');
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
      print(newArticle);

      _managedArticles.insert(0, newArticle);

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
      print(updatedArticle);

      final index = _managedArticles.indexWhere((article) => article.articleId == articleId);
      if (index != -1) {
        _managedArticles[index] = updatedArticle;
      } else {
        fetchManagedArticles(context);
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