import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/api_service.dart';

class PublicArticleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Article> _articles = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  Future<void> fetchArticles() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchArticles(page: 1);
      _articles = paginatedResponse.data ?? [];
      _currentPage = paginatedResponse.currentPage ?? 1;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreArticles() async {
    if (_isFetchingMore || !_hasMorePages) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchArticles(page: nextPage);
      _articles.addAll(paginatedResponse.data ?? []);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      // Optionally set an error, but might be disruptive for infinite scroll
      print("Failed to fetch more articles: $e");
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Article> fetchArticleDetails(int articleId) async {
    try {
      return await _apiService.fetchArticle(articleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
