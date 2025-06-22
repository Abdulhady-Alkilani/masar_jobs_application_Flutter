// lib/providers/recommendation_provider.dart

import 'package:flutter/material.dart';
import '../models/recommendation_response.dart'; // <-- 1. استيراد الموديل الجديد
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationResponse? _recommendations; // <-- 2. تحديد النوع الصحيح
  bool _isLoading = false;
  String? _error;

  RecommendationResponse? get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchRecommendations(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      // 3. ApiService سيعيد الآن كائنًا من نوع RecommendationResponse
      _recommendations = await _apiService.fetchRecommendations(token);

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