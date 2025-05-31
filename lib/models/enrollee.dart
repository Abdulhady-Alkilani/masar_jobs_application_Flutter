import 'user.dart'; // Use the main User model
import 'profile.dart'; // Import Profile as it's nested in User here

class Enrollee {
  final int? enrollmentId;
  final int? userId;
  final int? courseId;
  final String? status; // Enrollment status ('مكتمل', 'قيد التقدم', 'ملغي')
  final DateTime? date; // Enrollment date
  final DateTime? completDate; // Completion date
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user; // Nested Enrollee User object (might be fully loaded with profile)

  Enrollee({
    this.enrollmentId,
    this.userId,
    this.courseId,
    this.status,
    this.date,
    this.completDate,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Enrollee.fromJson(Map<String, dynamic> json) {
    // Note: JSON key has spaces
    return Enrollee(
      enrollmentId: json['EnrollmentID'] as int?,
      userId: json['UserID'] as int?,
      courseId: json['CourseID'] as int?,
      status: json['Status'] as String?,
      date: json['Date'] != null ? DateTime.parse(json['Date'] as String) : null,
      completDate: json['Complet Date'] != null ? DateTime.parse(json['Complet Date'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>) // Assuming it's the full User model here
          : null,
    );
  }
}