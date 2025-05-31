import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/paginated_response.dart';
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

  // جلب أول صفحة من المقالات
  Future<void> fetchArticles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchArticles(page: 1);
      print(paginatedResponse);
      _articles.addAll((paginatedResponse.data ?? []) as Iterable<Article>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load articles: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من المقالات (للتمرير اللانهائي)
  Future<void> fetchMoreArticles() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null; // Clear previous errors if any
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchArticles(page: nextPage);
      print(paginatedResponse);
      _articles.addAll((paginatedResponse.data ?? []) as Iterable<Article>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage; // Should be nextPage
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      // Optionally handle errors differently for infinite scroll
      print('Error fetching more articles: ${e.message}');
      // _error = e.message; // Might not want to block UI with error for just more data
    } catch (e) {
      print('Unexpected error fetching more articles: ${e.toString()}');
      // _error = 'Failed to load more articles: ${e.toString()}';
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل مقال محدد (إذا لم يكن موجوداً بالفعل في القائمة)
  Future<Article?> fetchArticle(int articleId) async {
    // Check if the article is already loaded
    final existingArticle = _articles.firstWhereOrNull((article) => article.articleId == articleId);
    print(existingArticle);
    if (existingArticle != null) {
      return existingArticle;
    }

    _isLoading = true; // Can use a separate loading state for single item if needed
    _error = null;
    notifyListeners();

    try {
      final article = await _apiService.fetchArticle(articleId);
      print(article);
      // Optionally add to the local list if not already there
      if (!_articles.any((a) => a.articleId == article.articleId)) {
        // Decide if you want to add single fetched item to list or keep list paginated only
        // _articles.add(article);
        // _articles.sort((a, b) => b.createdAt!.compareTo(a.createdAt!)); // Maintain sort order
      }
      return article;
    } on ApiException catch (e) {
      _error = e.message;
      return null; // Indicate failure
    } catch (e) {
      _error = 'Failed to load article: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
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