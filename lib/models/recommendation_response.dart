import 'job_opportunity.dart';
import 'training_course.dart';

class RecommendationResponse {
  final List<JobOpportunity>? recommendedJobs;
  final List<TrainingCourse>? recommendedCourses;

  RecommendationResponse({this.recommendedJobs, this.recommendedCourses});

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      recommendedJobs: (json['recommended_jobs'] as List<dynamic>?)
          ?.map((j) => JobOpportunity.fromJson(j as Map<String, dynamic>))
          .toList(),
      recommendedCourses: (json['recommended_courses'] as List<dynamic>?)
          ?.map((c) => TrainingCourse.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}