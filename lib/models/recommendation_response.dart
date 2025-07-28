// lib/models/recommendation_response.dart

import 'job_opportunity.dart';
import 'training_course.dart';

class RecommendationResponse {
  final List<JobOpportunity> jobOpportunities;
  final List<TrainingCourse> trainingCourses; // <--- تأكد أن الاسم هنا بصيغة الجمع

  RecommendationResponse({
    required this.jobOpportunities,
    required this.trainingCourses, // <--- وهنا أيضاً
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    List<T> _parseList<T>(String key, Function fromJson) {
      if (json[key] != null && json[key] is List) {
        return (json[key] as List)
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList()
            .cast<T>();
      }
      return [];
    }

    return RecommendationResponse(
      jobOpportunities: _parseList<JobOpportunity>('recommended_jobs', (json) => JobOpportunity.fromJson(json)),
      trainingCourses: _parseList<TrainingCourse>('training_courses', (json) => TrainingCourse.fromJson(json)), // <--- وهنا أيضاً
    );
  }
}