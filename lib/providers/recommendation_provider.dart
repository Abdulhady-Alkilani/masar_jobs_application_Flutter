import 'package:flutter/material.dart';
import '../models/recommendation_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationResponse? _recommendations;
  bool _isLoading = false;
  String? _error;

  RecommendationResponse? get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // جلب التوصيات للمستخدم الحالي
  Future<void> fetchRecommendations(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      print(token);
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      _recommendations = await _apiService.fetchRecommendations(token);
      print(_recommendations);

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load recommendations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}